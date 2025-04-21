extends Node

signal logged_to_map
signal disconnected_from_map

var on_map: bool = false
var in_menu: bool = true
var saved_console_opened: bool = false

func _physics_process(delta: float) -> void:
	on_map = (true if get_tree().get_root().get_node("Root Scene").get_node("Game").get_node("Map").get_node("Map Scene").get_child_count() == 1 else false)
	
	if !get_window().has_focus():
		on_window_focus_exited()

func _input(event: InputEvent) -> void:
	if (event is InputEventKey):
		if event.pressed:
			if (event.is_action("console")):
				get_tree().get_root().set_input_as_handled()
				if !GSGlobal.console.visible:
					if on_map:
						open_menu()
					GSGlobal.console.toggle_console()
			if event.get_keycode_with_modifiers() == KEY_ESCAPE:
				if on_map:
					if in_menu:
						saved_console_opened = GSGlobal.console.visible
						hide_menu()
					else:
						open_menu()

func on_window_focus_exited() -> void:
	if on_map:
		open_menu()

func hide_menu() -> void:
	in_menu = false

	GSGlobal.grab_pointer()

	# TODO: then make sure that the hud closes for a certain client, since now I'm using get_child(0) to take the first player in the list.
	if on_map:
		GSGlobal.game.get_node("Map").get_node("Players").get_child(0).hud_component.visible = true

	get_child(0).visible = false
	GSGlobal.console.visible = false

func open_menu() -> void:
	in_menu = true

	GSGlobal.release_pointer()

	# It's the same here
	if on_map:
		GSGlobal.game.get_node("Map").get_node("Players").get_child(0).hud_component.visible = false

	get_child(0).visible = true
	GSGlobal.console.visible = saved_console_opened
