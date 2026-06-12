@tool
class_name GSSPCPointMenuItem extends Control

var point_id : int = 0 : 
	set(val):
		point_id = val
		$GridContainer/id.text = str(val)
var point_pitch : float = 0.0 :
	set(val):
		point_pitch = val
		update_cords()
var point_roll : float = 0.0 :
	set(val):
		point_roll = val
		update_cords()
var selected : bool = false

signal delete_point
signal select_point
signal center_point
signal reorder_points_drag
signal reorder_points_up
signal reorder_points_down

func update_cords() -> void:
	$GridContainer/cords.text = "[color=#ffffff70]Pitch: [/color][b][color=#00ffff]"+str(point_pitch)+"[/color][/b][color=#ffffff70]  - Roll: [/color][b][color=#ffff00]"+str(point_roll)+"[/color][/b]"

func connect_signals(reciever: GDSPC) -> void:
	pass
