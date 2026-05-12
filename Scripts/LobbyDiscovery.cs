using Godot;
using System.Collections.Generic;
using System.IO;

public partial class LobbyDiscovery : Node
{
	public static LobbyDiscovery Instance { get; private set; }

	private const int BROADCAST_PORT = 7778;
	private const float BROADCAST_INTERVAL = 1.0f;

	private PacketPeerUdp _broadcaster;
	private PacketPeerUdp _listener;
	private float _timer = 0f;
	private bool _isHosting = false;
	private string _hostName = "";
	private int _maxPlayers = 2;
	private string _subnetBroadcast = "192.168.18.255";

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

		// Auto detect subnet broadcast address
		string localIP = "";
		foreach (var ip in IP.GetLocalAddresses())
		{
			if (ip.Contains(".") && !ip.StartsWith("127"))
			{
				localIP = ip;
				break;
			}
		}

		if (localIP != "")
		{
			// Get subnet broadcast e.g 192.168.18.255
			string[] parts = localIP.Split(".");
			if (parts.Length == 4)
				_subnetBroadcast = 
					$"{parts[0]}.{parts[1]}.{parts[2]}.255";
		}

		GD.Print($"Subnet broadcast: {_subnetBroadcast}");
	}

	public void StartBroadcasting(string hostName, int maxPlayers)
	{
		_isHosting = true;
		_hostName = hostName;
		_maxPlayers = maxPlayers;

		_broadcaster = new PacketPeerUdp();
		_broadcaster.SetBroadcastEnabled(true);
		_broadcaster.Bind(0);

		GD.Print($"Broadcasting lobby: {hostName}");
	}

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
		if (_isHosting && _broadcaster != null)
		{
			_timer += (float)delta;
			if (_timer >= BROADCAST_INTERVAL)
			{
				_timer = 0f;
				BroadcastLobby();
			}
		}

		if (!_isHosting && _listener != null)
		{
			ListenForLobbies();
		}
	}

	private void BroadcastLobby()
	{
		int currentPlayers = 
			Multiplayer.GetPeers().Length + 1;
		string ip = NetworkManager.Instance.GetLocalIP();

		string message =
			$"LOBBY|{_hostName}|{ip}|{currentPlayers}|{_maxPlayers}";

		byte[] data =
			System.Text.Encoding.UTF8.GetBytes(message);

		// Send to subnet broadcast
		_broadcaster.SetDestAddress(
			_subnetBroadcast, BROADCAST_PORT);
		_broadcaster.PutPacket(data);

		// Also send to localhost for same computer testing
		_broadcaster.SetDestAddress(
			"127.0.0.1", BROADCAST_PORT);
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
					var existing = DiscoveredLobbies
						.Find(l => l.IP == ip);

					if (existing != null)
					{
						existing.CurrentPlayers =
							int.Parse(parts[3]);
						existing.MaxPlayers =
							int.Parse(parts[4]);
					}
					else
					{
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
