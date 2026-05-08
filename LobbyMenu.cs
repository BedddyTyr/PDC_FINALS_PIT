using Godot;

public partial class LobbyMenu : Node2D
{
	private VBoxContainer _lobbyList;
	private Button _refreshButton;
	private Button _backButton;
	private Label _titleLabel;
	private float _refreshTimer = 0f;
	private const float REFRESH_INTERVAL = 2.0f;

	public override void _Ready()
	{
		_titleLabel = GetNode<Label>(
			"CanvasLayer/TitleLabel");
		_lobbyList = GetNode<VBoxContainer>(
			"CanvasLayer/ScrollContainer/LobbyList");
		_refreshButton = GetNode<Button>(
			"CanvasLayer/RefreshButton");
		_backButton = GetNode<Button>(
			"CanvasLayer/BackButton");

		_titleLabel.Text = "LOBBY MENU";
		_refreshButton.Text = "🔄 Refresh";
		_backButton.Text = "← Back";

		_refreshButton.Pressed += OnRefreshPressed;
		_backButton.Pressed += OnBackPressed;

		// Start listening for lobbies
		LobbyDiscovery.Instance.StartListening();

		// Initial refresh
		RefreshLobbyList();
	}

	public override void _Process(double delta)
	{
		// Auto refresh every 2 seconds
		_refreshTimer += (float)delta;
		if (_refreshTimer >= REFRESH_INTERVAL)
		{
			_refreshTimer = 0f;
			RefreshLobbyList();
		}
	}

	private void RefreshLobbyList()
	{
		// Clear existing lobby entries
		foreach (Node child in _lobbyList.GetChildren())
			child.QueueFree();

		var lobbies = LobbyDiscovery.Instance.DiscoveredLobbies;

		if (lobbies.Count == 0)
		{
			// Show no lobbies message
			var noLobbies = new Label();
			noLobbies.Text = "No lobbies found...\nMake sure host is on same WiFi!";
			_lobbyList.AddChild(noLobbies);
			return;
		}

		// Create a button for each lobby
		foreach (var lobby in lobbies)
		{
			// Container for each lobby entry
			var panel = new PanelContainer();
			var hbox = new HBoxContainer();
			var vbox = new VBoxContainer();

			// Lobby name
			var nameLabel = new Label();
			nameLabel.Text = $"🎮 {lobby.HostName}'s Lobby";

			// Player count
			var countLabel = new Label();
			countLabel.Text = 
				$"Players: {lobby.CurrentPlayers}/{lobby.MaxPlayers}";

			// Status
			var statusLabel = new Label();
			statusLabel.Text = lobby.IsFull ? 
				"🔒 Full" : "✅ Waiting";

			// Join button
			var joinButton = new Button();
			joinButton.Text = "Join Lobby";
			joinButton.Disabled = lobby.IsFull;

			// Capture IP for button press
			string lobbyIP = lobby.IP;
			joinButton.Pressed += () => OnJoinLobby(lobbyIP);

			// Build the layout
			vbox.AddChild(nameLabel);
			vbox.AddChild(countLabel);
			vbox.AddChild(statusLabel);
			hbox.AddChild(vbox);
			hbox.AddChild(joinButton);
			panel.AddChild(hbox);
			_lobbyList.AddChild(panel);
		}
	}

	private void OnJoinLobby(string ip)
	{
		GD.Print($"Joining lobby at {ip}");
		NetworkManager.Instance.JoinGame(ip);
		GetTree().ChangeSceneToFile("res://Scenes/JoinLobby.tscn");
	}

	private void OnRefreshPressed()
	{
		LobbyDiscovery.Instance.DiscoveredLobbies.Clear();
		LobbyDiscovery.Instance.StartListening();
		RefreshLobbyList();
	}

	private void OnBackPressed()
	{
		LobbyDiscovery.Instance.StopAll();
		GetTree().ChangeSceneToFile("res://Scenes/MainMenu.tscn");
	}
}
