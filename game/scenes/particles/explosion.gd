@tool
class_name Particle
extends Node3D

@export
var emit: bool = false: 
	set = emitting,
	get = getEmit

func emitting(val: float) -> void:
	emit = false
	$p_flash.emitting = true
	$p_shockwave.emitting = true
	$p_shockwave2.emitting = true
	$p_smoke.emitting = true

func getEmit() -> bool:
	return emit

func kill() -> void:
	queue_free()
