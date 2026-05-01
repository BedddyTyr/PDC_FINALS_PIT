using Godot;

public partial class NetworkManager : Node
{
	private const int PORT = 7777;
	public static int MaxPlayers { get; private set; } = 2;
	public static NetworkManager Instance { get; private set; }

	public override void _Ready()
	{
		Instance = this;

		Multiplayer.PeerConnected += (id) => 
			GD.Print($"Player {id} connected!");
		Multiplayer.PeerDisconnected += (id) => 
			GD.Print($"Player {id} disconnected!");
		Multiplayer.ConnectedToServer += () => 
			GD.Print("Successfully joined!");
		Multiplayer.ConnectionFailed += () => 
			GD.Print("Connection failed!");
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
		GD.Print($"Hosting for {MaxPlayers} players on port {PORT}");
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
		GD.Print($"Joining game at {ip}:{PORT}");
	}

	public void DisconnectGame()
	{
		Multiplayer.MultiplayerPeer = null;
		GD.Print("Disconnected.");
	}
}
