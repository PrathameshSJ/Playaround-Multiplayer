extends Area3D

@export var damage: int = 10

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage"):
		NetworkManager.rpc_id(1,"report_hit",body.get_multiplayer_authority(),damage)
