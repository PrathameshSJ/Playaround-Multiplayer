extends Control

@onready var hud = $"../hud"
@onready var resume_btn = $Panel/VBoxContainer/resume
@onready var menu_btn = $Panel/VBoxContainer/mainmenu
@onready var quit_btn = $Panel/VBoxContainer/quit
@onready var Player = $".."
@onready var ip_label = $Panel/VBoxContainer/ip

@onready var ip = NetworkManager.local_ip_finder()

var is_open := false #tells if the menu is open or not
var paused := false # tells if the game is paused

func _ready():
	#hides if its visible by accident on startup
	hide()
	# keeps the menu alaive even if game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS   
	if  !is_multiplayer_authority() or !NetworkManager.isSinglePlayer:
		hud.hide()
	
	## Delay ownership check until node is fully ready
	#await get_tree().process_frame
	
	ip_label.text = ip
	if multiplayer.is_server() and !NetworkManager.isSinglePlayer:
		ip_label.show()
	
	resume_btn.pressed.connect(_on_resume_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)


func _input(event):
	if is_multiplayer_authority() or NetworkManager.isSinglePlayer:
		if event.is_action_pressed("ui_cancel"): # usually ESC
			_escape_pressed()


func _on_menu_pressed():
	if NetworkManager.isSinglePlayer:
		NetworkManager.isSinglePlayer = false
	
	NetworkManager.disconnectPeer()
	NetworkManager.freePlayersarray()
	
	# go back to main menu scene
	get_tree().change_scene_to_file("res://scenes/MainScreen.tscn")

func _escape_pressed():
	if is_open:
		_close_menu()
	else:
		_open_menu()

#dont use this pauseGame func ok
func pauseGame():
	#pause logic
	if paused:
		get_tree().paused = true
	else:
		get_tree().paused = false

func _open_menu():
	
	is_open = true
	show()
	
	#check if singleplayer, then pause the game
	if not multiplayer.has_multiplayer_peer():
		paused = true
		pauseGame()
	
	
	hud.hide()
	
	Player.release_mouse()

func _close_menu():
	is_open = false
	hide()
	
	if not multiplayer.has_multiplayer_peer():
		paused = false
		pauseGame()
	
	hud.show()
	
	Player.capture_mouse()

func _on_resume_pressed():
	_close_menu()

func _on_quit_pressed():
	get_tree().quit()
