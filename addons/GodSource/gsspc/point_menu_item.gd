@tool
class_name GSSPCPointMenuItem extends Panel

var point : GDSPCPoint

signal selected_point

func update() -> void:
	$GridContainer/id.text = str(point.id)
	$GridContainer/cords.text = "[color=#ffffff70]Pitch: [/color][b][color=#00ffff]"+str(snapped(point.pitch, 0.01))+"[/color][/b][color=#ffffff70]  - Roll: [/color][b][color=#ffff00]"+str(snapped(point.roll, 0.01))+"[/color][/b]"
	var stylebox : StyleBoxFlat = get_theme_stylebox(&"panel").duplicate()
	if point.selected:
		stylebox.bg_color = Color(0,0.5,1.0,0.5)
	else:
		stylebox.bg_color = Color.TRANSPARENT
	self.add_theme_stylebox_override(&"panel",stylebox)


func connect_signals(reciever: GDSPC) -> void:
	$GridContainer/remove_point.pressed.connect(reciever.remove_point.bind(point))
	$GridContainer/center_on_point.pressed.connect(reciever.reset_view_on_point.bind(point))
	selected_point.connect(reciever.select_point.bind(point))
	$GridContainer/move_controls/move_up.pressed.connect(reciever.insert_point_into_id.bind(point, point.id - 1))
	$GridContainer/move_controls/move_down.pressed.connect(reciever.insert_point_into_id.bind(point, point.id + 1))


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			selected_point.emit()
