using Godot;

public partial class MainMenu : Node2D
{
	private OptionButton _playerCountOption;
	private LineEdit _ipInput;
	private Button _hostButton;
	private Button _joinButton;

	public override void _Ready()
	{
		// Get references to UI nodes
		_playerCountOption = GetNode<OptionButton>(
			"CanvasLayer/VBoxContainer/PlayerCountOption");
		_ipInput = GetNode<LineEdit>(
			"CanvasLayer/VBoxContainer/IpInput");
		_hostButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/HostButton");
		_joinButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/JoinButton");

		// Set up player count options
		_playerCountOption.AddItem("2 Players");
		_playerCountOption.AddItem("3 Players");
		_playerCountOption.AddItem("4 Players");

		// Set placeholder text
		_ipInput.PlaceholderText = "Enter Host IP Address";
		_hostButton.Text = "Host Game";
		_joinButton.Text = "Join Game";

		// Connect buttons
		_hostButton.Pressed += OnHostPressed;
		_joinButton.Pressed += OnJoinPressed;

		// Add NetworkManager to scene
		var networkManager = new NetworkManager();
		AddChild(networkManager);
	}

	private void OnHostPressed()
	{
		// 0 = 2 players, 1 = 3 players, 2 = 4 players
		int playerCount = _playerCountOption.Selected + 2;
		NetworkManager.Instance.HostGame(playerCount);

		// Go to Lobby scene
		GetTree().ChangeSceneToFile("res://Scenes/Lobby.tscn");
	}

	private void OnJoinPressed()
	{
		string ip = _ipInput.Text;

		if (ip == "")
		{
			GD.Print("Please enter an IP address!");
			return;
		}

		NetworkManager.Instance.JoinGame(ip);

		// Go to Lobby scene
		GetTree().ChangeSceneToFile("res://Scenes/Lobby.tscn");
	}
}
