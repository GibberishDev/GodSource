extends Node3D

@onready var explosion_scene: Resource = preload("res://game/scenes/gameplay/explosion.tscn")

@export var lifetime : float = 30.0

var speed : float = 0
var direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	$lifetime.wait_time = lifetime
	$lifetime.start()

func _physics_process(delta: float) -> void:
	$rocket.rotation.z += 2 * delta * PI
	position += direction * speed * delta
	
	if $hitDetection.is_colliding():
		var explosion_scene_instantiate: Node = explosion_scene.instantiate()
		explosion_scene_instantiate.position = $hitDetection.get_collision_point()
		explosion_scene_instantiate.base_damage = 90.0 #T ODO replace with weapon stats reading when inventory sytem is in place
		explosion_scene_instantiate.radius = 121.0 * 1.905 / 100.0 #T ODO replace with weapon stats reading when inventory sytem is in place
		get_tree().root.add_child(explosion_scene_instantiate)
		$trailParticles.end()
		free()

func startParticles() -> void:
	$trailParticles.emitting = true
	$trailParticles2.emitting = true

func lifetimeEnd() -> void:
	queue_free()
