@tool
extends Control

var is_burst : bool = true
@onready
var input_node : Control = $vbox/ScrollContainer/content_cont/editor_container/Panel/point_editor/user_input

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%guides.root = self
	resized.connect(dock_resized)

func dock_resized() -> void:
	if size.x < 800:
		%content_cont.vertical = true
		$vbox/ScrollContainer/content_cont/editor_container.custom_minimum_size.y = size.x - 14
	else:
		%content_cont.vertical = false
		$vbox/ScrollContainer/content_cont/editor_container.custom_minimum_size.y = 0


func _on_pattern_settings_container_fold(is_folded: bool) -> void:
	if is_folded:
		$vbox/ScrollContainer/content_cont/settings/pattern_settings.size_flags_vertical = SIZE_SHRINK_BEGIN
	else:
		$vbox/ScrollContainer/content_cont/settings/pattern_settings.size_flags_vertical = SIZE_FILL


var preview_offset : Vector2 = Vector2.ZERO
var preview_scale : float = 1.0

func _on_user_input(event: InputEvent) -> void:
	queue_redraw()
	if event is InputEventMouseMotion:
		var mouse_pos : Vector2 = Vector2(
			event.position.x - input_node.size.x / 2.0,
			event.position.y - input_node.size.y / 2.0
			)
		var mouse_move : Vector2 = event.screen_relative * preview_scale
		mouse_pos *= preview_scale
		mouse_pos += preview_offset
		%met_cords.text = str(snapped(mouse_pos.x, 0.01)) + "m X\n" + str(snapped(mouse_pos.y, 0.01)) + "m Y"
		if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_MIDDLE):
			preview_offset += mouse_move
			%guides.queue_redraw()
		# print(preview_offset)

func reset_view() -> void:
	preview_offset = Vector2.ZERO
	preview_scale = 1.0
	%guides.queue_redraw()
