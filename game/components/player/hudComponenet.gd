extends Control

## [CharacterBody3D] parent.
@onready var player_root: CharacterBody3D = get_node("..")

var console_shown: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("console"):
		if !console_shown:
			console_shown = true
			player_root.ui_focused = true
			$consoleContainer.size = Vector2(DisplayServer.window_get_size().x, DisplayServer.window_get_size().y * 0.5)
			$consoleContainer.visible = true
			$consoleContainer/BoxContainer/BoxContainer2/consoleInput.grab_focus()
		else:
			console_shown = false
			player_root.ui_focused = false
			$consoleContainer.visible = false
			$consoleContainer/BoxContainer/BoxContainer2/consoleInput.release_focus()
