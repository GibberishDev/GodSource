extends Control

## [CharacterBody3D] parent.
@onready
var P : CharacterBody3D = get_node("..")

var consoleShown := bool(false)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("console"):
		if !consoleShown:
			consoleShown = true
			P.uiFocused = true
			$consoleContainer.size = Vector2(DisplayServer.window_get_size().x,DisplayServer.window_get_size().y * 0.5)
			$consoleContainer.visible = true
			$consoleContainer/BoxContainer/BoxContainer2/consoleInput.grab_focus()
		else:
			consoleShown = false
			P.uiFocused = false
			$consoleContainer.visible = false
			$consoleContainer/BoxContainer/BoxContainer2/consoleInput.release_focus()
