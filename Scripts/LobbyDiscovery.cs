using Godot;
using System.Collections.Generic;
using System.Threading.Tasks;

public partial class LobbyDiscovery : Node
{
	public static LobbyDiscovery Instance { get; private set; }

	private const int GAME_PORT = 7777;
	private const int BROADCAST_PORT = 7778;

	private PacketPeerUdp _broadcaster;
	private PacketPeerUdp _listener;
	private float _timer = 0f;
	private bool _isHosting = false;
	private string _hostName = "";
	private int _maxPlayers = 2;
	private string _subnet = "";
	private bool _isScanning = false;

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
		DetectSubnet();
	}

	private void DetectSubnet()
	{
		foreach (var ip in IP.GetLocalAddresses())
		{
			if (!ip.Contains(".")) continue;
			if (ip.StartsWith("127")) continue;
			if (ip.StartsWith("169")) continue;

			string[] parts = ip.Split(".");
			if (parts.Length == 4)
			{
				_subnet = 
					$"{parts[0]}.{parts[1]}.{parts[2]}";
				GD.Print($"Detected subnet: {_subnet}");
				break;
			}
		}
	}

	public void StartBroadcasting(string hostName, 
		int maxPlayers)
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

		_listener?.Close();
		_listener = new PacketPeerUdp();
		_listener.Bind(BROADCAST_PORT);

		GD.Print("Listening for lobbies...");

		if (!_isScanning && _subnet != "")
			ScanNetwork();
	}

	public void StopAll()
	{
		_isHosting = false;
		_isScanning = false;
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
			if (_timer >= 1.0f)
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
			$"LOBBY|{_hostName}|{ip}" +
			$"|{currentPlayers}|{_maxPlayers}";

		byte[] data =
			System.Text.Encoding.UTF8.GetBytes(message);

		try
		{
			if (_subnet != "")
			{
				_broadcaster.SetDestAddress(
					$"{_subnet}.255", BROADCAST_PORT);
				_broadcaster.PutPacket(data);
			}

			_broadcaster.SetDestAddress(
				"255.255.255.255", BROADCAST_PORT);
			_broadcaster.PutPacket(data);

			_broadcaster.SetDestAddress(
				"127.0.0.1", BROADCAST_PORT);
			_broadcaster.PutPacket(data);
		}
		catch (System.Exception e)
		{
			GD.Print($"Broadcast error: {e.Message}");
		}
	}

	private void ListenForLobbies()
	{
		while (_listener.GetAvailablePacketCount() > 0)
		{
			byte[] data = _listener.GetPacket();
			string message =
				System.Text.Encoding.UTF8.GetString(data);

			if (message.StartsWith("LOBBY|"))
				ParseLobbyMessage(message);
		}
	}

	private void ParseLobbyMessage(string message)
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
				GD.Print(
					$"Found lobby: {parts[1]} at {ip}");
			}
		}
	}

	private async void ScanNetwork()
	{
		if (_subnet == "") return;
		_isScanning = true;

		GD.Print($"Scanning network: {_subnet}.x");

		for (int i = 1; i <= 254; i++)
		{
			if (!_isScanning) break;

			string targetIP = $"{_subnet}.{i}";
			string localIP =
				NetworkManager.Instance.GetLocalIP();

			if (targetIP == localIP) continue;

			var scanner = new PacketPeerUdp();
			try
			{
				scanner.SetDestAddress(
					targetIP, BROADCAST_PORT);
				string ping = "PING";
				byte[] data =
					System.Text.Encoding.UTF8
					.GetBytes(ping);
				scanner.PutPacket(data);
			}
			catch { }
			finally
			{
				scanner.Close();
			}

			await Task.Delay(10);
		}

		_isScanning = false;
		GD.Print("Network scan complete!");
	}
}
