using Godot;

public partial class LobbyMenu : Node2D
{
	private VBoxContainer _lobbyList;
	private Button _refreshButton;
	private Button _backButton;
	private Label _titleLabel;
	private LineEdit _manualIPInput;
	private Button _manualJoinButton;
	private float _refreshTimer = 0f;
	private const float REFRESH_INTERVAL = 1.0f;

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
		_manualIPInput = GetNode<LineEdit>(
			"CanvasLayer/ManualIPInput");
		_manualJoinButton = GetNode<Button>(
			"CanvasLayer/ManualJoinButton");

		_titleLabel.Text = "LOBBY MENU";
		_refreshButton.Text = "Refresh";
		_backButton.Text = "Back";
		_manualIPInput.PlaceholderText = 
			"Enter host IP manually (e.g 192.168.18.36)";
		_manualJoinButton.Text = "Connect";

		_refreshButton.Pressed += OnRefreshPressed;
		_backButton.Pressed += OnBackPressed;
		_manualJoinButton.Pressed += OnManualJoinPressed;

		LobbyDiscovery.Instance.StartListening();
		RefreshLobbyList();
	}

	public override void _Process(double delta)
	{
		_refreshTimer += (float)delta;
		if (_refreshTimer >= REFRESH_INTERVAL)
		{
			_refreshTimer = 0f;
			LobbyDiscovery.Instance.StartListening();
			RefreshLobbyList();
		}
	}

	private void RefreshLobbyList()
	{
		foreach (Node child in _lobbyList.GetChildren())
			child.QueueFree();

		var lobbies = LobbyDiscovery.Instance.DiscoveredLobbies;

		if (lobbies.Count == 0)
		{
			var noLobbies = new Label();
			noLobbies.Text =
				"No lobbies found...\n" +
				"Try refreshing or use manual IP below!";
			_lobbyList.AddChild(noLobbies);
			return;
		}

		foreach (var lobby in lobbies)
		{
			var panel = new PanelContainer();
			var hbox = new HBoxContainer();
			var vbox = new VBoxContainer();

			var nameLabel = new Label();
			nameLabel.Text =
				$"  {lobby.HostName}'s Lobby";

			var countLabel = new Label();
			countLabel.Text =
				$"  Players: {lobby.CurrentPlayers}" +
				$"/{lobby.MaxPlayers}";

			var statusLabel = new Label();
			statusLabel.Text = lobby.IsFull ?
				"  Full" : "  Waiting...";

			var joinButton = new Button();
			joinButton.Text = "Join Lobby";
			joinButton.Disabled = lobby.IsFull;
			joinButton.CustomMinimumSize =
				new Vector2(120, 50);

			string lobbyIP = lobby.IP;
			joinButton.Pressed += () => OnJoinLobby(lobbyIP);

			vbox.AddChild(nameLabel);
			vbox.AddChild(countLabel);
			vbox.AddChild(statusLabel);
			hbox.AddChild(vbox);
			hbox.AddChild(joinButton);
			panel.AddChild(hbox);
			panel.CustomMinimumSize =
				new Vector2(600, 80);
			_lobbyList.AddChild(panel);
		}
	}

	private void OnJoinLobby(string ip)
	{
		GD.Print($"Joining lobby at {ip}");
		NetworkManager.Instance.JoinGame(ip);
		GetTree().ChangeSceneToFile(
			"res://Scenes/JoinLobby.tscn");
	}

	private void OnManualJoinPressed()
	{
		string ip = _manualIPInput.Text.Trim();

		if (ip == "")
		{
			GD.Print("Please enter an IP address!");
			return;
		}

		GD.Print($"Manually joining at {ip}");
		NetworkManager.Instance.JoinGame(ip);
		GetTree().ChangeSceneToFile(
			"res://Scenes/JoinLobby.tscn");
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
		GetTree().ChangeSceneToFile(
			"res://Scenes/MainMenu.tscn");
	}
}
