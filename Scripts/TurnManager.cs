using Godot;
using System.Collections.Generic;

public partial class TurnManager : Node
{
	private List<int> _playerOrder = new List<int>();
	private int _currentIndex = 0;

	public int CurrentTurnPlayerId => _playerOrder[_currentIndex];

	public void StartGame()
	{
		_playerOrder.Clear();
		_playerOrder.Add(1); // Host is always ID 1
		foreach (var id in Multiplayer.GetPeers())
			_playerOrder.Add(id);

		GD.Print("Turn order: " + string.Join(", ", _playerOrder));
		NotifyTurnChange();
	}

	[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true)]
	public void EndTurn()
	{
		_currentIndex = (_currentIndex + 1) % _playerOrder.Count;
		NotifyTurnChange();
	}

	private void NotifyTurnChange()
	{
		GD.Print($"It's now Player {CurrentTurnPlayerId}'s turn");
	}
}
