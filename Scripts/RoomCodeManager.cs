using Godot;

public partial class RoomCodeManager : Node
{
	// Stores the room code that the joiner typed
	public static string EnteredCode { get; set; } = "";

	// Simple dictionary to map room codes to IP addresses
	// In LAN this is handled locally
	public static string GetIPFromCode(string code)
	{
		// For LAN, the host shares their code
		// which matches their IP
		// We just return the HostIP from NetworkManager
		if (code == NetworkManager.RoomCode)
			return NetworkManager.HostIP;

		return "";
	}
}
