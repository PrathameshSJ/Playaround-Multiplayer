extends Node3D
class_name GameManager

func _ready() -> void:
	register_player_root()


func _process(_delta):
	pass

func register_player_root():
	# When the World scene loads, tell NetworkManager where the Players root is
	var players_root = $"../Players"
	print("✅ Registered Players root from GameManager:", players_root)
	NetworkManager.register_players_root(players_root)
