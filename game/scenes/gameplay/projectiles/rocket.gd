extends Node3D

@onready
var explosionScene = preload("res://game/scenes/gameplay/explosion.tscn")

var speed : float = 0
var dir := Vector3.ZERO

func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	if $hitDetection.is_colliding():
		var expl = explosionScene.instantiate()
		expl.position = $hitDetection.get_collision_point()
		expl.baseDamage = 90.0 #TODO replace with weapon stats reading when inventory sytem is in place
		expl.radius = 146 * 1.905 / 100 #TODO replace with weapon stats reading when inventory sytem is in place
		get_tree().root.add_child(expl)
		free()
		print("rocket exploded")
