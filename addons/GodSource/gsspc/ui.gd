@tool
class_name GDSPC extends Control

var is_burst : bool = true
@onready
var input_node : Control = $vbox/ScrollContainer/content_cont/editor_container/Panel/point_editor/user_input
var pattern_distance : float = 57.29
var length_guides : bool = true
var degree_guides : bool = true
var deg_preview_subdivisions : int = 0
var random_guides : bool = true

@export
var center_texture : DPITexture
@export
var center_point_texture : DPITexture


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
	update_points_position()

func update_points_position()->void:
	%points_preview.position = %guides.size/2 + preview_offset
	


func _on_pattern_settings_container_fold(is_folded: bool, source: FoldableContainer) -> void:
	if is_folded:
		source.size_flags_vertical = SIZE_SHRINK_BEGIN
	else:
		source.size_flags_vertical = SIZE_FILL


var preview_offset : Vector2 = Vector2.ZERO
var preview_scale : float = 1.0
var mouse_hide_pos : Vector2

func _on_user_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				mouse_hide_pos = get_global_mouse_position()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				if mouse_hide_pos:
					Input.warp_mouse(mouse_hide_pos)
		elif event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if (not event.pressed) and selected_point!=null:
				selected_point.selected = false
				selected_point = null
				%center_button.get_node("icon").texture = center_texture
	if event is InputEventMouseMotion:
		var mouse_pos : Vector2 = Vector2(
			event.position.x - input_node.size.x / 2.0,
			event.position.y - input_node.size.y / 2.0
			)
		var mouse_move : Vector2 = event.screen_relative * preview_scale
		mouse_pos *= preview_scale
		mouse_pos -= preview_offset
		if length_guides:
			%met_cords.text = "[color=#ff0000]" + String.num(mouse_pos.x / %guides.grid_size * 0.01, 3).pad_decimals(3) + "m X[/color]\n[color=#00ff00]" + String.num(mouse_pos.y / %guides.grid_size * 0.01, 3).pad_decimals(3) + "m Y[/color]"
		if degree_guides:
			var dist : float = mouse_pos.length() / %guides.grid_size
			var hypotenuse : float = sqrt(dist*dist + pattern_distance*pattern_distance)
			var pitch : float = rad_to_deg(acos((pow(hypotenuse,2) - pow(dist,2) + pow(pattern_distance,2))/(2 * hypotenuse * pattern_distance)))
			var roll : float = rad_to_deg(mouse_pos.angle_to(Vector2.DOWN)) + 180
			%deg_cords.text = "[color=#00ffff]Pitch: " + str(snapped(pitch,0.1)).pad_decimals(1) + "[/color]\n[color=#ffff00]Roll: " + str(snapped(roll,0.1)).pad_decimals(1) + "[/color]"
		if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_MIDDLE):
			preview_offset += mouse_move
			update_points_position()
			%guides.queue_redraw()

func reset_view() -> void:
	if selected_point:
		var pos : Vector2 = selected_point.position
		preview_offset = -pos * %points_preview.scale
		preview_scale = 1.0
		update_points_position()
		%guides.queue_redraw()
	else:
		preview_offset = Vector2.ZERO
		preview_scale = 1.0
		update_points_position()
		%guides.queue_redraw()


func _on_pd_range_value_changed(value: float) -> void:
	pattern_distance = value
	var val : float = pattern_distance/57.29
	%points_preview.scale = Vector2(val, val)

func _on_length_guides_pressed() -> void:
	length_guides = !length_guides
	%met_cords.visible = length_guides

func _on_degree_guides_pressed() -> void:
	degree_guides = !degree_guides
	%deg_cords.visible = degree_guides

func _on_pitch_subdivisions_changed(value: float) -> void:
	deg_preview_subdivisions = value

func _on_lrandom_guides_pressed() -> void:
	random_guides = !random_guides

#region points

var points : Array[GDSPCPoint] = []
var selected_point : GDSPCPoint = null

func _point_clicked(point: GDSPCPoint) -> void:
	if selected_point != null:
		selected_point.selected = false
	selected_point = point
	selected_point.selected = true
	%center_button.get_node("icon").texture = center_point_texture

var snap_on : bool = true

func get_new_point_pos(new_pos: Vector2) -> Array[Vector2]:
	new_pos *= preview_scale
	new_pos -= preview_offset

	var pitch : float = get_pitch_from_pos(new_pos)
	var roll : float = get_roll_from_pos(new_pos)
	if snap_on:
		var pitch_snap : float = snappedf(pitch, 1.0/(deg_preview_subdivisions+1.0))
		print(deg_preview_subdivisions)
		var roll_snap : float = snappedf(roll,360.0/48.0)
		if abs(abs(pitch) - abs(pitch_snap)) < 0.25:
			pitch = pitch_snap
		if abs(abs(roll) - abs(roll_snap)) < 1.0:
			roll = roll_snap
		new_pos = get_pos_from_point(pitch,roll)
	if length_guides:
		%met_cords.text = "[color=#ff0000]" + String.num(get_pos_from_point(pitch,roll).x / %guides.grid_size * 0.01, 3).pad_decimals(3) + "m X[/color]\n[color=#00ff00]" + String.num(get_pos_from_point(pitch,roll).y / %guides.grid_size * 0.01, 3).pad_decimals(3) + "m Y[/color]"
	if degree_guides:
		%deg_cords.text = "[color=#00ffff]Pitch: " + str(snapped(get_pitch_from_pos(new_pos),0.1)).pad_decimals(1) + "[/color]\n[color=#ffff00]Roll: " + str(snapped(get_roll_from_pos(new_pos),0.1)).pad_decimals(1) + "[/color]"
	return [new_pos,Vector2(pitch, roll)]
#endregion

func get_pitch_from_pos(pos: Vector2)->float:
	var dist : float = pos.length() / %guides.grid_size
	var hypotenuse : float = sqrt(dist*dist + pattern_distance*pattern_distance)
	var pitch : float = rad_to_deg(acos((pow(hypotenuse,2) - pow(dist,2) + pow(pattern_distance,2))/(2 * hypotenuse * pattern_distance)))
	return pitch
func get_roll_from_pos(pos: Vector2)->float:
	var roll : float = rad_to_deg(pos.angle_to(Vector2.DOWN)) + 180
	return roll

func get_pos_from_point(pitch:float,roll:float) -> Vector2:
	pitch = deg_to_rad(pitch)
	roll = deg_to_rad(roll)
	var dist : float = pattern_distance * (sin(pitch) / sin(deg_to_rad(90.0)-pitch)) * %guides.grid_size
	return Vector2(0,-dist).rotated(-roll)
	
