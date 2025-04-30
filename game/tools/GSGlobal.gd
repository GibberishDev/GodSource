extends Node

@onready var menu: Node = get_tree().get_root().get_node("Root Scene/Menu")
@onready var main_menu: Node = menu.get_node("GSMainMenu")
@onready var game: Node = get_tree().get_root().get_node("Root Scene/Game")

var mouse_captured: bool
var mouse_position_pre_capture: Vector2 = Vector2.ZERO

func toggle_pointer_lock() -> void:
	if mouse_captured:
		release_pointer()
	else:
		grab_pointer()

func grab_pointer() -> void:
	mouse_position_pre_capture = get_viewport().get_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true

func release_pointer() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false
