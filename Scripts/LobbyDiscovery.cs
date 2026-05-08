using Godot;
using System.Collections.Generic;

public partial class LobbyDiscovery : Node
{
	public static LobbyDiscovery Instance { get; private set; }

	private const int BROADCAST_PORT = 7778;
	private const float BROADCAST_INTERVAL = 2.0f;

	private PacketPeerUdp _broadcaster;
	private PacketPeerUdp _listener;
	private float _timer = 0f;
	private bool _isHosting = false;

	public class LobbyInfo
	{
		public string HostName { get; set; }
		public string IP { get; set; }
		public int CurrentPlayers { get; set; }
		public int MaxPlayers { get; set; }
		public bool IsFull => CurrentPlayers >= MaxPlayers;
	}

	public List<LobbyInfo> DiscoveredLobbies { get; private set; }
		= new List<LobbyInfo>();

	public override void _Ready()
	{
		Instance = this;
	}

	// Called by HOST to start broadcasting
	public void StartBroadcasting(string hostName, int maxPlayers)
	{
		_isHosting = true;

		_broadcaster = new PacketPeerUdp();
		_broadcaster.SetBroadcastEnabled(true);
		_broadcaster.Bind(0);

		GD.Print($"Broadcasting lobby: {hostName}");
	}

	// Called by JOINER to start listening
	public void StartListening()
	{
		_isHosting = false;
		DiscoveredLobbies.Clear();

		_listener = new PacketPeerUdp();
		_listener.Bind(BROADCAST_PORT);

		GD.Print("Listening for lobbies...");
	}

	public void StopAll()
	{
		_isHosting = false;
		_broadcaster?.Close();
		_listener?.Close();
		_broadcaster = null;
		_listener = null;
	}

	public override void _Process(double delta)
	{
		// HOST: broadcast every 2 seconds
		if (_isHosting && _broadcaster != null)
		{
			_timer += (float)delta;
			if (_timer >= BROADCAST_INTERVAL)
			{
				_timer = 0f;
				BroadcastLobby();
			}
		}

		// JOINER: listen for broadcasts
		if (!_isHosting && _listener != null)
		{
			ListenForLobbies();
		}
	}

	private void BroadcastLobby()
	{
		string hostName = OS.GetEnvironment("USERNAME");
		int currentPlayers = Multiplayer.GetPeers().Length + 1;
		string ip = NetworkManager.Instance.GetLocalIP();

		// Format: LOBBY|HostName|IP|CurrentPlayers|MaxPlayers
		string message = 
			$"LOBBY|{hostName}|{ip}|{currentPlayers}|{NetworkManager.MaxPlayers}";

		byte[] data = System.Text.Encoding.UTF8.GetBytes(message);
		_broadcaster.SetDestAddress("255.255.255.255", BROADCAST_PORT);
		_broadcaster.PutPacket(data);
	}

	private void ListenForLobbies()
	{
		while (_listener.GetAvailablePacketCount() > 0)
		{
			byte[] data = _listener.GetPacket();
			string message = 
				System.Text.Encoding.UTF8.GetString(data);

			if (message.StartsWith("LOBBY|"))
			{
				string[] parts = message.Split("|");
				if (parts.Length == 5)
				{
					string ip = parts[2];

					// Check if lobby already in list
					var existing = DiscoveredLobbies
						.Find(l => l.IP == ip);

					if (existing != null)
					{
						// Update existing lobby
						existing.CurrentPlayers = int.Parse(parts[3]);
						existing.MaxPlayers = int.Parse(parts[4]);
					}
					else
					{
						// Add new lobby
						DiscoveredLobbies.Add(new LobbyInfo
						{
							HostName = parts[1],
							IP = ip,
							CurrentPlayers = int.Parse(parts[3]),
							MaxPlayers = int.Parse(parts[4])
						});

						GD.Print($"Found lobby: {parts[1]} at {ip}");
					}
				}
			}
		}
	}
}
