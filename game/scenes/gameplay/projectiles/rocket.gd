extends Node3D

@onready
var explosionScene = preload("res://game/scenes/gameplay/explosion.tscn")
@export
var lifetime : float = 30.0
var speed : float = 0
var dir := Vector3.ZERO

func _ready() -> void:
	$lifetime.wait_time = lifetime
	$lifetime.start()

func _physics_process(delta: float) -> void:
	$rocket.rotation.z += 2 * PI * delta  
	position += dir * speed * delta
	if $hitDetection.is_colliding():
		var expl = explosionScene.instantiate()
		expl.position = $hitDetection.get_collision_point()
		expl.baseDamage = 90.0 #TODO replace with weapon stats reading when inventory sytem is in place
		expl.radius = 146 * 1.905 / 100 #TODO replace with weapon stats reading when inventory sytem is in place
		get_tree().root.add_child(expl)
		$trailParticles.end()
		
		free()
		

func startParticles() -> void:
	$trailParticles.emitting = true
	$trailParticles2.emitting = true


func lifetimeEnd() -> void:
	queue_free()
