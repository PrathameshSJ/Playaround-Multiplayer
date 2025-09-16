extends Node3D

@export var damage: int = 20
@export var fire_rate: float = 0.25
@export var bullet_range: float = 10000000.0
@onready var animation_player = $AnimationPlayer
@onready var myplayer = $"../.."
@onready var muzzle = $Muzzle
@onready var shot_sound = $AudioStreamPlayer3D
@onready var camera = $"../../CamRoot/CamPitch/SpringArm3D/Camera3D"


var can_fire := true

func _unhandled_input(event):
	#process input if the player is singleplayer or is multiplayer and system is owner of the system
	if is_multiplayer_authority() or NetworkManager.isSinglePlayer:
		if event.is_action_pressed("right_click") and can_fire:
			can_fire = false
			shoot()
			await get_tree().create_timer(fire_rate).timeout
			can_fire = true

func shoot():
	shot_sound.play()
	
	#animations
	animation_player.play("shoot")
	
	
	var space_state = get_world_3d().direct_space_state
	
	# Get camera position and forward direction
	var cam = camera # adjust path if needed
	var from = cam.global_transform.origin
	var to = from + -cam.global_transform.basis.z * bullet_range  # -z is forward
	
	
	
	# Create the ray query
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	# Perform raycast
	var result = space_state.intersect_ray(query)
	
	if result and result.has("collider") and result.collider.has_method("apply_damage"):
		hit_player(result.collider)

	# Reset fire cooldown
	await get_tree().create_timer(fire_rate).timeout



# Call this when a bullet hits something
func hit_player(player: Node) -> void:
	# Send to SERVER only (peer_id = 1 is always server in ENet)
	print("Player ",player.get_multiplayer_authority()," hit.")
	NetworkManager.rpc_id(1, "report_hit", player.get_multiplayer_authority(), damage)  
	myplayer.face_target(player.global_transform.origin)
