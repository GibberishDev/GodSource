extends Node

@onready var player_root: GSPlayer = get_node("..")
@onready var movement_component : Node3D = player_root.movement_component

@export_category("Health")
@export var max_health: float = 200
var health: float = 0

func _ready() -> void:
	health = max_health

func damage(amount: float) -> void:
	health -= amount

	if health <= 0:
		death()

func death() -> void:
	# TODO: Implement dying lmao
	print("You are dead. Not big surprise")

func explosive_damage(damage: float, base_damage: float, origin: Vector3, explosion_radius: float) -> void:
	# TODO: hook up damage
	var direction: Vector3 = (origin + Vector3(0, 10 * 1.905, 0)).direction_to(player_root.get_global_position() + Vector3(0, movement_component.bounding_box.shape.size.y / 2.0, 0))
	var amount: float = base_damage * (1.0 - 0.5 * min(origin.distance_to(player_root.global_position) / explosion_radius, 1))

	movement_component.apply_impulse(direction, amount)
