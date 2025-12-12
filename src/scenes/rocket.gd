extends Node3D

var explosion_particles : PackedScene
var explosion : PackedScene
var speed : float = 1100 * 1.905 / 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	#TODO: replace with global call to process projectiles
	$rocket.position.z -= speed * delta
	if $rocket/RayCast3D.is_colliding():
		var particles : Node3D = explosion_particles.instantiate()
		particles.position = $rocket/RayCast3D.get_collision_point()
		get_tree().root.get_node("GameRoot/Node3D").add_child(particles)
		var explosion_node : Node3D = explosion.instantiate()
		explosion_node.position = $rocket/RayCast3D.get_collision_point()
		get_tree().root.get_node("GameRoot/Node3D").add_child(explosion_node)
		queue_free()


func _on_timer_timeout() -> void:
		queue_free()
