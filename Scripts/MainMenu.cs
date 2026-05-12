using Godot;

public partial class MainMenu : Node2D
{
	private Button _hostButton;
	private Button _joinButton;
	private Button _exitButton;

	public override void _Ready()
	{
		_hostButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/HostButton");
		_joinButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/JoinButton");

		_hostButton.Text = "Host Game";
		_joinButton.Text = "Join Game";

		_hostButton.Pressed += OnHostPressed;
		_joinButton.Pressed += OnJoinPressed;

		// Create NetworkManager only once
		if (NetworkManager.Instance == null)
		{
			var networkManager = new NetworkManager();
			AddChild(networkManager);
		}
	}

	private void OnHostPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/HostScreen.tscn");
	}

	private void OnJoinPressed()
	{
		// Start listening for lobbies
		LobbyDiscovery.Instance.StartListening();
		GetTree().ChangeSceneToFile("res://Scenes/LobbyMenu.tscn");
	}
}
