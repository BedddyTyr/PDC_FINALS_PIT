using Godot;

public partial class HostLobby : Node2D
{
	private Label _titleLabel;
	private Label _roomCodeLabel;
	private Label _ipLabel;
	private Label _playersLabel;
	private Button _disconnectButton;
	private LobbyManager _lobbyManager;

	public override void _Ready()
	{
		_titleLabel = GetNode<Label>(
			"CanvasLayer/VBoxContainer/TitleLabel");
		_roomCodeLabel = GetNode<Label>(
			"CanvasLayer/VBoxContainer/RoomCodeLabel");
		_ipLabel = GetNode<Label>(
			"CanvasLayer/VBoxContainer/IPLabel");
		_playersLabel = GetNode<Label>(
			"CanvasLayer/VBoxContainer/PlayersLabel");
		_disconnectButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/DisconnectButton");

		_lobbyManager = new LobbyManager();
		AddChild(_lobbyManager);

		_titleLabel.Text = "YOUR LOBBY";
		_roomCodeLabel.Text = 
			$"Room Code: {NetworkManager.RoomCode}";
		_ipLabel.Text = 
			$"Your IP: {NetworkManager.HostIP}";
		_disconnectButton.Text = "Disconnect";

		_disconnectButton.Pressed += OnDisconnectPressed;

		Multiplayer.PeerConnected += (id) => UpdatePlayers();
		Multiplayer.PeerDisconnected += (id) => UpdatePlayers();

		UpdatePlayers();
	}

	private void UpdatePlayers()
	{
		int current = Multiplayer.GetPeers().Length + 1;
		_playersLabel.Text =
			$"Players: {current}/{NetworkManager.MaxPlayers}";
	}

	private void OnDisconnectPressed()
	{
		NetworkManager.Instance.DisconnectGame();
		GetTree().ChangeSceneToFile("res://Scenes/MainMenu.tscn");
	}
}
