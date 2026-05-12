using Godot;

public partial class HostScreen : Node2D
{
	private OptionButton _playerCountOption;
	private Button _createButton;
	private Button _backButton;

	public override void _Ready()
	{
		_playerCountOption = GetNode<OptionButton>(
			"CanvasLayer/VBoxContainer/PlayerCountOption");
		_createButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/CreateButton");
		_backButton = GetNode<Button>(
			"CanvasLayer/VBoxContainer/BackButton");

		// Add player count options
		_playerCountOption.Clear();
		_playerCountOption.AddItem("2 Players");
		_playerCountOption.AddItem("3 Players");
		_playerCountOption.AddItem("4 Players");

		_createButton.Text = "Create Lobby";
		_backButton.Text = "← Back";

		_createButton.Pressed += OnCreatePressed;
		_backButton.Pressed += OnBackPressed;
	}

	private void OnCreatePressed()
	{
		int playerCount = _playerCountOption.Selected + 2;
		NetworkManager.Instance.GenerateRoomCode();
		NetworkManager.Instance.HostGame(playerCount);
		GetTree().ChangeSceneToFile("res://Scenes/HostLobby.tscn");
	}

	private void OnBackPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/MainMenu.tscn");
	}
}
