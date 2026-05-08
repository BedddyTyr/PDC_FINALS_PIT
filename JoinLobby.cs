using Godot;

public partial class JoinLobby : Node2D
{
	private Label _titleLabel;
	private Label _playersLabel;
	private Label _statusLabel;
	private Button _readyButton;
	private Button _disconnectButton;
	private LobbyManager _lobbyManager;
	private bool _isReady = false;

	public override void _Ready()
	{
		_titleLabel = GetNode<Label>(
			"CanvasLayer/VBoxContainer/TitleLabel");
		_playersLabel = GetNode<Label>(
			"CanvasLayer/VBoxContainer/PlayersLabel");
		_statusLabel = GetNode<Label>(
			"CanvasLayer/VBoxContainer/StatusLabel");
		_readyButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/ReadyButton");
		_disconnectButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/DisconnectButton");

		_lobbyManager = new LobbyManager();
		AddChild(_lobbyManager);

		_titleLabel.Text = "LOBBY";
		_readyButton.Text = "Ready Up!";
		_disconnectButton.Text = "Disconnect";
		_statusLabel.Text = 
			"Click Ready when you are prepared!";

		_readyButton.Pressed += OnReadyPressed;
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

	private void OnReadyPressed()
	{
		if (!_isReady)
		{
			_isReady = true;
			_readyButton.Text = "✓ Ready!";
			_statusLabel.Text = 
				"Waiting for other players...";
			_lobbyManager.Rpc(
				nameof(LobbyManager.SetPlayerReady),
				Multiplayer.GetUniqueId());
		}
	}

	private void OnDisconnectPressed()
	{
		NetworkManager.Instance.DisconnectGame();
		GetTree().ChangeSceneToFile("res://Scenes/MainMenu.tscn");
	}
}
