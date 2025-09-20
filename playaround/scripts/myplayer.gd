extends CharacterBody3D
@onready var my_player: CharacterBody3D
@onready var cam_root :Node3D #$CamRoot
@onready var cam_pitch: Node3D #$CamRoot/CamPitch
@onready var camera :Camera3D #$CamRoot/CamPitch/SpringArm3D/Camera3D
@onready var anim_player = $AnimationPlayer
@onready var body_mesh = $Body
@onready var escape_menu = $EscapeMenu
@onready var cross_hair = $hud/CenterContainer/Crosshair
@onready var hud = $hud
@onready var health_bar_over_head = $HealthBarRoot
var move_vec:Vector3
var forward
var right
@export var gravity: float = 20
@export var speed: float = 10.0
@export var jump_force: float = 10.0
@export var mouse_sensitivity: float = 0.001
@export var pitch_min: float = deg_to_rad(-60)
@export var pitch_max: float = deg_to_rad(60)

var input_dir: Vector2 = Vector2.ZERO
var mouse_caped: bool = false

# --- Player Stats ---
@export var max_health: int = 100
var health: int = max_health

# --- Gun ---
@export var fire_rate: float = 0.25  # seconds between shots
var can_shoot: bool = true



func _ready() -> void:
	
	# Delay ownership check until node is fully ready
	await get_tree().process_frame
	
	if is_multiplayer_authority() or NetworkManager.isSinglePlayer:
		push_warning("this ran btw for %s" % multiplayer.get_unique_id())
		health_bar_over_head.hide()
		capture_mouse()
	
		# Only setup camera for the local authority
	if is_multiplayer_authority():
		var my_id = str(multiplayer.get_unique_id())
		
		# Look up this player in the Players root
		var players_root = get_tree().get_current_scene().get_node("Players")
		if players_root and players_root.has_node(my_id):
			my_player = players_root.get_node(my_id)
			if my_player.has_node("CamRoot"):
				cam_root = my_player.get_node("CamRoot")
				cam_root.set_process(true)
				cam_pitch = cam_root.get_node("CamPitch")
				# Make sure its Camera is the active one
				camera = cam_root.get_node("CamPitch/SpringArm3D/Camera3D")
				
				
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_caped=true
	else:
		mouse_caped=false
		
	##broken rn
	#if !multiplayer.is_server():
		#NetworkManager.rpc_id(1, "request_full_state", multiplayer.get_unique_id()) # 1 = server


func _unhandled_input(event):
	
	if event is InputEventMouseMotion:
		if mouse_caped and cam_root:
			cam_root.rotate_y(-event.relative.x * mouse_sensitivity)
			var new_pitch = cam_pitch.rotation.x + event.relative.y * mouse_sensitivity
			cam_pitch.rotation.x = clamp(new_pitch, pitch_min, pitch_max)

func release_mouse():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_caped=false

func capture_mouse():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_caped=true

func _physics_process(delta: float) -> void:
	#process input if the player is singleplayer or is multiplayer and system is owner of the system
	if is_multiplayer_authority() or NetworkManager.isSinglePlayer:
		# Collect local input
		var dir = Vector2.ZERO
		if Input.is_action_pressed("forward"): dir.y -= 1
		if Input.is_action_pressed("back"): dir.y += 1
		if Input.is_action_pressed("left"): dir.x += 1
		if Input.is_action_pressed("right"): dir.x -= 1
		input_dir = dir.normalized()

		# Send input to network manager
		NetworkManager.send_input(input_dir)

		# Jump
		if is_on_floor():
			if Input.is_action_just_pressed("jump"):
				velocity.y = jump_force
			else:
				velocity.y = 0
		else:
			velocity.y -= gravity * delta
		
		# --- Movement ---
		if cam_root:
			forward = -cam_root.transform.basis.z
			right = cam_root.transform.basis.x
		if right or forward:
			move_vec = (right * input_dir.x) + (forward * input_dir.y)
		move_vec.y = 0
		move_vec = move_vec.normalized()
		
		velocity.x = move_vec.x * speed
		velocity.z = move_vec.z * speed
		
		move_and_slide()

		# Also broadcast transform each tick
		NetworkManager.broadcast_transform(self,self.get_node("Body"))
	else:
		# Remote players still apply gravity
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0



	# --- Animations ---
	if input_dir.length() > 0.1:
		if not anim_player.is_playing() or anim_player.current_animation != "walk":
			anim_player.play("walk")
		var target_rotation = atan2(move_vec.x, move_vec.z)
		body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, target_rotation, 10 * delta)
	else:
		anim_player.stop()

# Called by NetworkManager.rpc_set_input
func apply_network_input(new_input: Vector2):
	if not is_multiplayer_authority():
		input_dir = new_input

#makes the player face the target when shot
func rotate_to_direction(target_pos: Vector3) -> void:
	var dir = (target_pos)
	dir.y = 0  # keep rotation only in XZ plane
	dir = dir.normalized()
	
	if dir.length() > 0.01:
		var target_rot = atan2(dir.x, dir.z)
		body_mesh.rotation.y = target_rot
		NetworkManager.broadcast_transform(self,self.get_node("Body"))


#############DAMAGE###############
@rpc("any_peer","call_local")
func sync_health(id: int,new_health: int):
	if str(id) == name:
		health = new_health
		hud.update_health_bar(health)
		health_bar_over_head.set_health(health)

func apply_damage(amount: int):
	health = max(health - amount, 0)
	print("Player ", name, " health: ", health)
	if health <= 0:
		die()

func die():
	print("Player", multiplayer.get_unique_id(), "died.")
	
	#queue_free()
