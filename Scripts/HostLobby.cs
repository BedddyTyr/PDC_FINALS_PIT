using Godot;

public partial class HostLobby : Node2D
{
	private Label _titleLabel;
	private Label _roomCodeLabel;
	private Label _ipLabel;
	private Label _playersLabel;
	private Label _readyCountLabel;
	private Button _startButton;
	private Button _disconnectButton;

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
		_readyCountLabel = GetNode<Label>(
			"CanvasLayer/VBoxContainer/ReadyCountLabel");
		_startButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/StartButton");
		_disconnectButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/DisconnectButton");

		_titleLabel.Text = "YOUR LOBBY";
		_roomCodeLabel.Text =
			$"Room Code: {NetworkManager.RoomCode}";
		_ipLabel.Text =
			$"Your IP: {NetworkManager.HostIP}";
		_startButton.Text = "Start Game";
		_disconnectButton.Text = "Disconnect";
		_startButton.Disabled = true;

		_startButton.Pressed += OnStartPressed;
		_disconnectButton.Pressed += OnDisconnectPressed;

		Multiplayer.PeerConnected += (id) => UpdateUI();
		Multiplayer.PeerDisconnected += (id) => 
			OnPlayerDisconnected(id);

		LobbyManager.Instance.AllPlayersReady += 
			OnAllPlayersReady;
		LobbyManager.Instance.ReadyCountChanged += 
			OnReadyCountChanged;

		UpdateUI();
	}

	private void OnReadyCountChanged(int readyCount, int total)
	{
		_readyCountLabel.Text =
			$"Ready: {readyCount}/{NetworkManager.MaxPlayers}";
	}

	private void UpdateUI()
	{
		int current = Multiplayer.GetPeers().Length + 1;
		_playersLabel.Text =
			$"Players: {current}/{NetworkManager.MaxPlayers}";
		_readyCountLabel.Text =
			$"Ready: {LobbyManager.Instance.GetReadyCount()}" +
			$"/{NetworkManager.MaxPlayers}";
	}

	private void OnPlayerDisconnected(long id)
	{
		UpdateUI();

		// Disable start button when someone leaves
		_startButton.Disabled = true;
		_readyCountLabel.Text =
			"A player left! Waiting for players...";

		GD.Print($"Player {id} left! Start button disabled.");
	}

	private void OnAllPlayersReady()
	{
		GD.Print("All players ready! Host can start!");
		_readyCountLabel.Text = "All players are ready!";
		_startButton.Disabled = false;
	}

	private void OnStartPressed()
	{
		GD.Print("Host started the game!");
		LobbyManager.Instance.Rpc(
			nameof(LobbyManager.StartGame));
	}

	private void OnDisconnectPressed()
	{
		NetworkManager.Instance.DisconnectGame();
		GetTree().ChangeSceneToFile(
			"res://Scenes/MainMenu.tscn");
	}
}
