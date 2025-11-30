extends Node3D

var explosion_radius : float = GSUtils.to_meters(121.0)
var explosion_base_damage : float = 90.0
@onready
var trigger : ShapeCast3D = $trigger

func _physics_process(delta: float) -> void:
	trigger.shape.radius = explosion_radius
	trigger.force_update_transform()
	explode()
	queue_free()

func explode() -> void:
	var targets : Array[Node] = get_targets()
	if targets == []: return
	for i : Node in targets:
		if i is GSPlayer:
			calculate_player_explosion(i)

func get_targets() -> Array[Node]:
	var targets : Array[Node] = []
	trigger.force_shapecast_update()
	var targets_num: int = trigger.get_collision_count()
	if targets_num == 0: return []
	for i : int in range(targets_num):
		targets.append(trigger.get_collider(i))
	return targets

func calculate_player_explosion(player: GSPlayer) -> void:
	var origin : Vector3 = self.global_position - Vector3(0, GSUtils.to_meters(10.0), 0)
	var distance : float = min(origin.distance_to(player.global_position), origin.distance_to(player.global_position + Vector3(0, player.collision_hull.shape.size.y/2.0, 0.0)))
	var knockback_direction : Vector3 = origin.direction_to(player.global_position)
	var knockback_power : float = get_player_knockback(player)
	player.apply_impulse(knockback_direction * knockback_power)

func get_player_knockback(player: GSPlayer) -> float:
	var knockback_damage : float = explosion_base_damage * (1 - 0.5 * min(self.global_position.distance_to(player.global_position) / explosion_radius, 1))
	var player_mass : float = 1.0
	var tf2_soldier_knockback_multiplier : float = 5.0
	var knockback_damage_reduction : float = 1.0
	if player.is_crouched:
		player_mass = 0.67
	if player.is_airborne:
		tf2_soldier_knockback_multiplier = 10.0
	if player.is_airborne and !player.is_in_water:
		knockback_damage_reduction = 0.6
	return min(GSUtils.to_meters(1000.0), GSUtils.to_meters((knockback_damage * tf2_soldier_knockback_multiplier * knockback_damage_reduction) / player_mass))
