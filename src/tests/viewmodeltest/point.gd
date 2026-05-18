extends MeshInstance3D;func delete()->void:queue_free()
func set_up_dir(dir: Vector3) -> void:
	$dir.look_at(-dir.normalized())
	$dir.scale.z = dir.length() / 10.0
	
