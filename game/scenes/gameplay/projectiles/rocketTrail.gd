extends GPUParticles3D

func end() -> void:
	self.reparent(get_tree().root)
	emitting = false
	await get_tree().create_timer(5).timeout
	free()
