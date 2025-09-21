extends Control

@export var base_height := 1080  # reference height
@export var CContainer: CenterContainer
@export var colorrect: ColorRect
@export var Control1: Control

@onready var main_menu = $CenterContainer/main_menu
@onready var multiplayer_menu = $CenterContainer/multiplayer_menu
@onready var ip_input = $CenterContainer/multiplayer_menu/Join/ip_input
@onready var singleplayer_menu = $CenterContainer/singleplayer_menu

var ip := ""



func _ready():
	_resize_ui()
	get_viewport().size_changed.connect(_resize_ui)


func _resize_ui():
	var screen_size = get_viewport().size
	Control1.position= screen_size/2
	colorrect.size = screen_size
	colorrect.position = -screen_size/2
	CContainer.size = screen_size
	CContainer.position = -screen_size/2
	var scale_factor = screen_size.y / base_height
	# Scale the VBoxContainer (buttons)
	main_menu.scale = Vector2(scale_factor, scale_factor)



func _on_singleplayer_pressed():
	main_menu.visible = false
	singleplayer_menu.visible = true

func _on_multiplayer_pressed():
	main_menu.visible = false
	multiplayer_menu.visible = true

func _on_quit_pressed():
	get_tree().quit()

# --- Multiplayer Menu ---
func _on_host_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	NetworkManager.host_game()
	

func _on_join_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	if !ip:
		NetworkManager.join_game(NetworkManager.local_ip_finder())
	else:
		NetworkManager.join_game(ip)

func _on_back_pressed():
	multiplayer_menu.visible = false
	main_menu.visible = true


func _on_ip_input_text_changed():
	ip = ip_input.text


func _on_level_0_pressed():
	# Load your level scene
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	NetworkManager.isSinglePlayer = true
	NetworkManager.singleplayer()


func _on_level_1_pressed():
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")
	NetworkManager.isSinglePlayer = true
	NetworkManager.singleplayer()
