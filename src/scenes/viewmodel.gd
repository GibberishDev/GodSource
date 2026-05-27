class_name GSViewmodel
extends Node3D

var camera_active : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if get_parent().is_class("Camera3D"):
		camera_active = get_parent().current
	
	$meshes.visible = camera_active
