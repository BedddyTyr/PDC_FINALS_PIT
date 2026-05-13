using Godot;

public partial class NetworkManager : Node
{
	private const int PORT = 7777;
	public static int MaxPlayers { get; private set; } = 2;
	public static NetworkManager Instance { get; private set; }
	public static string RoomCode { get; private set; } = "";
	public static string HostIP { get; private set; } = "";

	public override void _Ready()
	{
		if (Instance != null)
		{
			QueueFree();
			return;
		}

		Instance = this;

		var lobbyDiscovery = new LobbyDiscovery();
		AddChild(lobbyDiscovery);

		var lobbyManager = new LobbyManager();
		AddChild(lobbyManager);

		Multiplayer.PeerConnected += OnPeerConnected;
		Multiplayer.PeerDisconnected += (id) =>
			GD.Print($"Player {id} disconnected!");
		Multiplayer.ConnectedToServer += () =>
			GD.Print("Successfully joined!");
		Multiplayer.ConnectionFailed += () =>
			GD.Print("Connection failed!");
	}

	private void OnPeerConnected(long id)
	{
		GD.Print($"Player {id} connected!");

		// Host sends MaxPlayers to the new joiner
		if (Multiplayer.IsServer())
		{
			RpcId(id, nameof(SyncMaxPlayers), MaxPlayers);
		}
	}

	// Joiner receives MaxPlayers from host
	[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false,
		TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
	private void SyncMaxPlayers(int maxPlayers)
	{
		MaxPlayers = maxPlayers;
		GD.Print($"MaxPlayers synced: {MaxPlayers}");
	}

	public string GetLocalIP()
	{
		foreach (var ip in IP.GetLocalAddresses())
		{
			if (ip.Contains(".") && !ip.StartsWith("127"))
				return ip;
		}
		return "127.0.0.1";
	}

	public string GenerateRoomCode()
	{
		var random = new System.Random();
		RoomCode = random.Next(1000, 9999).ToString();
		HostIP = GetLocalIP();
		return RoomCode;
	}

	public void HostGame(int playerCount)
	{
		MaxPlayers = playerCount;

		var peer = new ENetMultiplayerPeer();
		Error error = peer.CreateServer(PORT, MaxPlayers);

		if (error != Error.Ok)
		{
			GD.Print("Failed to host: " + error);
			return;
		}

		Multiplayer.MultiplayerPeer = peer;

		string hostName = OS.GetEnvironment("USERNAME");
		LobbyDiscovery.Instance.StartBroadcasting(
			hostName, MaxPlayers);

		GD.Print($"Hosting for {MaxPlayers} players!");
	}

	public void JoinGame(string ip)
	{
		var peer = new ENetMultiplayerPeer();
		Error error = peer.CreateClient(ip, PORT);

		if (error != Error.Ok)
		{
			GD.Print("Failed to join: " + error);
			return;
		}

		Multiplayer.MultiplayerPeer = peer;
		LobbyDiscovery.Instance.StopAll();

		GD.Print($"Joining game at {ip}!");
	}

	public void DisconnectGame()
	{
		LobbyDiscovery.Instance?.StopAll();
		Multiplayer.MultiplayerPeer = null;
		GD.Print("Disconnected.");
	}
}
