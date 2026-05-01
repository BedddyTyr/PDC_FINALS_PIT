using Godot;

public partial class Lobby : Node2D
{
	private Label _statusLabel;
	private Button _disconnectButton;

	public override void _Ready()
	{
		_statusLabel = GetNode<Label>(
			"CanvasLayer/VBoxContainer/StatusLabel");
		_disconnectButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/DisconnectButton");

		_disconnectButton.Text = "Disconnect";
		_disconnectButton.Pressed += OnDisconnectPressed;

		// Add LobbyManager only if not already added
		if (GetNodeOrNull<LobbyManager>("LobbyManager") == null)
		{
			var lobbyManager = new LobbyManager();
			lobbyManager.Name = "LobbyManager";
			AddChild(lobbyManager);
			
			// Check if NetworkManager already exists
if (GetNodeOrNull<NetworkManager>("NetworkManager") == null)
{
	var networkManager = new NetworkManager();
	networkManager.Name = "NetworkManager";
	AddChild(networkManager);
}
		}

		UpdateStatus();

		Multiplayer.PeerConnected += (id) => UpdateStatus();
		Multiplayer.PeerDisconnected += (id) => UpdateStatus();
	}

	private void UpdateStatus()
	{
		int current = Multiplayer.GetPeers().Length + 1;
		_statusLabel.Text =
			$"Waiting for players...\n" +
			$"Players Connected: {current}/{NetworkManager.MaxPlayers}\n" +
			$"Your ID: {Multiplayer.GetUniqueId()}";
	}

	private void OnDisconnectPressed()
	{
		GD.Print("Disconnect button pressed!");

		// Safely disconnect
		if (Multiplayer.MultiplayerPeer != null)
		{
			Multiplayer.MultiplayerPeer.Close();
			Multiplayer.MultiplayerPeer = null;
		}

		// Go back to main menu
		GetTree().ChangeSceneToFile("res://Scenes/MainMenu.tscn");
	}
}
