extends Control

@onready var crosshaircontainer = $CenterContainer
@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
@onready var EscapeMenu : PackedScene = load("res://scenes/escape_menu.tscn")


func _ready():
	# Delay ownership check until node is fully ready
	await get_tree().process_frame
	
	var viewport = get_viewport()
	
	if is_multiplayer_authority() or NetworkManager.isSinglePlayer:
		show()
	
	# Disconnect first if it was already connected (safe reset)
	if viewport.size_changed.is_connected(_resize_ui):
		viewport.size_changed.disconnect(_resize_ui)
	# Now connect
	get_viewport().size_changed.connect(_resize_ui)
	# Call once immediately so it's centered from the start
	_resize_ui()

func _escape_pressed():
	EscapeMenu._escape_pressed()

func _resize_ui():
	var screen_size = get_viewport().get_visible_rect().size
	crosshaircontainer.position= screen_size/2

func update_health_bar(health):
	health_bar.value = health
