using Godot;

public partial class LobbyMenu : Node2D
{
	private VBoxContainer _lobbyList;
	private Button _backButton;
	private Label _titleLabel;
	private LineEdit _manualIPInput;
	private Button _manualJoinButton;
	private Label _errorLabel;
	private float _refreshTimer = 0f;
	private const float REFRESH_INTERVAL = 0.5f;

	public override void _Ready()
	{
		_titleLabel = GetNode<Label>(
			"CanvasLayer/Control/TitleLabel");
		_lobbyList = GetNode<VBoxContainer>(
			"CanvasLayer/Control/LobbyList");
		_backButton = GetNode<Button>(
			"CanvasLayer/Control/BackButton");
		_manualIPInput = GetNode<LineEdit>(
			"CanvasLayer/Control/ManualIPInput");
		_manualJoinButton = GetNode<Button>(
			"CanvasLayer/Control/ManualJoinButton");
		_errorLabel = GetNode<Label>(
			"CanvasLayer/Control/ErrorLabel");

		_titleLabel.Text = "JOIN GAME";
		_manualIPInput.PlaceholderText =
			"Enter host IP (e.g 192.168.1.36)";
		_manualJoinButton.Text = "Connect";
		_backButton.Text = "Back";
		_errorLabel.Text = 
			"Searching for lobbies...";

		_manualJoinButton.Pressed += OnManualJoinPressed;
		_backButton.Pressed += OnBackPressed;

		LobbyDiscovery.Instance.StartListening();
	}

	public override void _Process(double delta)
	{
		_refreshTimer += (float)delta;
		if (_refreshTimer >= REFRESH_INTERVAL)
		{
			_refreshTimer = 0f;
			CheckAutoDiscovery();
		}
	}

	private void CheckAutoDiscovery()
	{
		var lobbies =
			LobbyDiscovery.Instance.DiscoveredLobbies;

		if (lobbies.Count == 0)
		{
			_errorLabel.Text =
				"Searching for lobbies...\n" +
				"Or enter IP manually below";

			// Clear lobby list
			foreach (Node child in _lobbyList.GetChildren())
				child.QueueFree();
			return;
		}

		// Clear old entries
		foreach (Node child in _lobbyList.GetChildren())
			child.QueueFree();

		// Show found lobbies
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
			joinButton.Text = "Join";
			joinButton.Disabled = lobby.IsFull;
			joinButton.CustomMinimumSize =
				new Vector2(100, 50);

			string lobbyIP = lobby.IP;
			joinButton.Pressed += () => 
				OnJoinLobby(lobbyIP);

			vbox.AddChild(nameLabel);
			vbox.AddChild(countLabel);
			vbox.AddChild(statusLabel);
			hbox.AddChild(vbox);
			hbox.AddChild(joinButton);
			panel.AddChild(hbox);
			panel.CustomMinimumSize =
				new Vector2(500, 80);
			_lobbyList.AddChild(panel);

			// Update error label
			_errorLabel.Text = 
				"Lobby found! Click Join to connect.";
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
			_errorLabel.Text =
				"Please enter an IP address!";
			return;
		}

		string[] parts = ip.Split(".");
		if (parts.Length != 4)
		{
			_errorLabel.Text =
				"Invalid IP! Example: 192.168.1.36";
			return;
		}

		_errorLabel.Text = "Connecting...";
		NetworkManager.Instance.JoinGame(ip);

		var timer = GetTree().CreateTimer(3.0f);
		timer.Timeout += () =>
		{
			if (Multiplayer.GetPeers().Length == 0)
			{
				_errorLabel.Text =
					"Can't find lobby!\n" +
					"Check IP and try again.";
				NetworkManager.Instance.DisconnectGame();
			}
			else
			{
				GetTree().ChangeSceneToFile(
					"res://Scenes/JoinLobby.tscn");
			}
		};
	}

	private void OnBackPressed()
	{
		LobbyDiscovery.Instance.StopAll();
		GetTree().ChangeSceneToFile(
			"res://Scenes/MainMenu.tscn");
	}
}
