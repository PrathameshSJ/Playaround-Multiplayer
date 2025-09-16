extends CharacterBody3D

@export var speed := 5.0
@onready var cam: Camera3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/Camera3D

func _ready() -> void:
	# Only my own player keeps its camera & camera logic active
	if not is_multiplayer_authority():
		$CamRoot.process_mode = Node.PROCESS_MODE_DISABLED  # stop addon camera logic on remotes

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var input_dir := Vector3.ZERO
		if Input.is_action_pressed("right"):  input_dir.x -= 1
		if Input.is_action_pressed("left"):   input_dir.x += 1
		if Input.is_action_pressed("back"):   input_dir.z -= 1
		if Input.is_action_pressed("forward"):input_dir.z += 1

		if input_dir != Vector3.ZERO:
			input_dir = input_dir.normalized()

		velocity.x = input_dir.x * speed
		velocity.z = input_dir.z * speed
		move_and_slide()

		# Godot 4 RPC call
		update_transform.rpc(global_transform)

@rpc("unreliable")
func update_transform(t: Transform3D) -> void:
	if not is_multiplayer_authority():
		global_transform = t


#extends CharacterBody3D
#
#signal pressed_jump(jump_state : JumpState)
#signal changed_stance(stance : Stance)
#signal changed_movement_state(_movement_state: MovementState)
#signal changed_movement_direction(_movement_direction: Vector3)
#
#@export var max_air_jump : int = 1
#@export var jump_states : Dictionary
#@export var stances : Dictionary
#
#var air_jump_counter : int = 0
#var movement_direction : Vector3
#var current_stance_name : String = "upright"
#var current_movement_state_name : String
#var stance_antispam_timer : SceneTreeTimer
#
#@onready var cube = $"../first_animation"
#
#func _ready():
	#stance_antispam_timer = get_tree().create_timer(0.25)
	#
	#changed_movement_direction.emit(Vector3.BACK)
	#set_movement_state("stand")
	#set_stance(current_stance_name)
	#
	## Set multiplayer authority based on who owns this node
	#if str(name).is_valid_int():
		#set_multiplayer_authority(int(name))
	#
	#print("Player ", name, " authority: ", get_multiplayer_authority(), " my id: ", multiplayer.get_unique_id())
#
#
#
#
#func _input(event):
	#if event.is_action_pressed("movement") or event.is_action_released("movement"):
		#movement_direction.x = Input.get_action_strength("left") - Input.get_action_strength("right")
		#movement_direction.z = Input.get_action_strength("forward") - Input.get_action_strength("back")
		#
		#if is_movement_ongoing():
			#if Input.is_action_pressed("sprint"):
				#set_movement_state("sprint")
				#if current_stance_name == "stealth":
					#set_stance("upright")
			#else:
				#if Input.is_action_pressed("walk"):
					#set_movement_state("walk")
				#else:
					#set_movement_state("run")
		#else:
			#set_movement_state("stand")
	#
	#if event.is_action_pressed("jump"):
		#if air_jump_counter <= max_air_jump:
			#if is_stance_blocked("upright"):
				#return
			#
			#if current_stance_name != "upright" and current_stance_name != "stealth":
				#set_stance("upright")
				#return
			#
			#var jump_name = "ground_jump"
			#
			#if air_jump_counter > 0:
				#jump_name = "air_jump"
			#
			#pressed_jump.emit(jump_states[jump_name])
			#air_jump_counter += 1
	#
	#if is_on_floor():
		#for stance in stances.keys():
			#if event.is_action_pressed(stance):
				#set_stance(stance)
				#
	#
	#if event.is_action_pressed("G"):
		#cube._cube_animation()
#
#func _physics_process(delta):
	#if is_multiplayer_authority():
		#var input_vec = Vector3(
#Input.get_action_strength("left") - Input.get_action_strength("right"),0,
#Input.get_action_strength("forward") - Input.get_action_strength("back")
#)
#
#
		## Normalize so diagonal movement isn’t faster
		#if input_vec.length() > 0:
			#input_vec = input_vec.normalized()
#
		## Apply velocity
		#var speed = 5.0
		#velocity.x = input_vec.x * speed
		#velocity.z = input_vec.z * speed
#
		#move_and_slide()
#
		## Reset jump counter
		#if is_on_floor():
			#air_jump_counter = 0
		#elif air_jump_counter == 0:
			#air_jump_counter = 1
#
		## Sync our state to others
		#rpc("sync_state", position, rotation_degrees)
#
#
##func _physics_process(delta):
	##
	##if is_multiplayer_authority():
		##if is_movement_ongoing():
			##changed_movement_direction.emit(movement_direction)
			##
		##if is_on_floor():
			##air_jump_counter = 0
		##elif air_jump_counter == 0:
			##air_jump_counter = 1
		#### Only the authority processes input
		###var input_vec = Vector2(Input.get_action_strength("left") - Input.get_action_strength("right")
		###,Input.get_action_strength("back") - Input.get_action_strength("forward"))
###
		###velocity.x = input_vec.x * 5
		###velocity.z = input_vec.y * 5
		###move_and_slide()
		### Sync our state to others
		##rpc("sync_state", position, rotation_degrees)
#
#
#func is_movement_ongoing() -> bool:
	#return abs(movement_direction.x) > 0 or abs(movement_direction.z) > 0
#
#
#func set_movement_state(state : String):
	#var stance = get_node(stances[current_stance_name])
	#current_movement_state_name = state
	#changed_movement_state.emit(stance.get_movement_state(state))
#
#
#func set_stance(_stance_name : String):
	#if stance_antispam_timer.time_left > 0:
		#return
	#stance_antispam_timer = get_tree().create_timer(0.25)
	#
	#var next_stance_name : String
	#
	#if _stance_name == current_stance_name:
		#next_stance_name = "upright"
	#else:
		#next_stance_name = _stance_name
	#
	#if is_stance_blocked(next_stance_name):
		#return
	#
	#var current_stance = get_node(stances[current_stance_name])
	#current_stance.collider.disabled = true
	#
	#current_stance_name = next_stance_name
	#current_stance = get_node(stances[current_stance_name])
	#current_stance.collider.disabled = false
	#
	#changed_stance.emit(current_stance)
	#set_movement_state(current_movement_state_name)
#
#
#func is_stance_blocked(_stance_name : String) -> bool:
	#var stance = get_node(stances[_stance_name])
	#return stance.is_blocked()
#
#@rpc("any_peer", "unreliable")
#func sync_state(pos: Vector3, rot: Vector3):
	#if not is_multiplayer_authority():
		#position = pos
		#rotation_degrees = rot
