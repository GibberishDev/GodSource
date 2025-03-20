@tool
extends Node3D

@export
var Xcord : Vector3 = Vector3(1.0,0.0,0.0) : set = set_xcord
@export
var Ycord : Vector3 = Vector3(0.0,1.0,0.0)  : set = set_ycord
@export
var Zcord : Vector3 = Vector3(0.0,0.0,1.0) : set = set_zcord

func set_xcord(val: Vector3) -> void:
	Xcord = val
	$x.position = val
func set_ycord(val: Vector3) -> void:
	Ycord = val
	$y.position = val
func set_zcord(val: Vector3) -> void:
	Zcord = val
	$z.position = val

func _enter_tree() -> void:
	update_lines()

func update_lines() -> void:
	$lineX.points[0] = position
	$lineX.points[1] = $x.position + position
	$lineY.points[0] = position
	$lineY.points[1] = $y.position + position
	$lineZ.points[0] = position
	$lineZ.points[1] = $z.position + position


func _process(_delta: float) -> void:
	if !Engine.is_editor_hint():
		update_lines()
