extends Node3D

@onready var anim_player = $AnimationPlayer

func _cube_animation():
	anim_player.play("CubeAction_001")  # play the animation
