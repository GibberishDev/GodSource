extends Node3D

func _on_hit(hitbox: Area3D) -> void:
	get_tree().root.get_node("/root/GameRoot/Node3D/damage_number_manager").spawn(
		self,
		90,
		global_position + Vector3(0.0,2.0,0.0),
		get_tree().root.get_node("/root/GameRoot/Node3D/damage_number_manager").DAMAGE_TYPE.EXPLOSION
	)
