class_name Explosion
extends Node3D

enum DAMAGE_TYPE {GENERIC, BLAST, KNOCKBACK, FIRE} #TODO: move into separate autoload damage type class idk

##Type of damage to deal. May be smth like fire damage, blast damage, generic(untyped or without any special behaviour) damage 
var damage_type: DAMAGE_TYPE # TODO: when damage types are introduced hook up

## How big explosion will be 
var radius: float = 0.0

## Base damage of an explosion. IMPORTANT! This is not the same as actual damage recieved to health. in TF2 all knockback is calculated based on damage. So to make game more consistent Valve went the way of setting separate damage and base damage for weapons(ex. for blast jumping calculations all rocket launchers have base damage of 90.0)
var base_damage: float = 0.0

@export var debug_shape: bool = true

var damage: float = 0.0
var projectile_owner: GSPlayer = null
const particle_scene: Resource = preload("res://game/scenes/particles/explosion.tscn")

func _ready() -> void:
	$detectionRange.shape.radius = radius
	cause_effects()

func _physics_process(_delta: float) -> void:
	explode()

	if debug_shape:
		$vis.visible = true
		$vis.mesh.radius = radius
		$vis.mesh.height = radius * 2
		$vis.reparent(get_node(".."))

	queue_free()


func explode() -> void:
	var targets: Array = get_targets()

	if targets == []:
		return

	for i: int in range(targets.size()):
		if targets[i] is GSPlayer:
			explode_player(targets[i])
		if targets[i].is_in_group("worldPropWeapon") and targets[i] is RigidBody3D:
			explode_physics_props(targets[i])

func check_hit(entity_list: Array) -> Array:
	#TODO: implement visibility check from explosion to hit entities bounding boxes
	return entity_list

func cause_effects() -> void:
	var particle_scene_explosion: Node = particle_scene.instantiate()
	particle_scene_explosion.position = global_position
	particle_scene_explosion.emitting(true)
	get_tree().root.add_child(particle_scene_explosion)

## ---[br]
func get_targets() -> Array:
	var targets: Array = []

	$detectionRange.force_shapecast_update()

	var num: int = $detectionRange.get_collision_count()

	for i: int in range(num):
		targets.append($detectionRange.get_collider(i))

	return targets

func explode_player(player_root: GSPlayer) -> void:
	#TODO: add health damage calculation
	var kbDir: Vector3 = getKnockbackDir(player_root)
	var kbAmt: float = getKnockbackAmt(player_root)

	player_root.movement_component.apply_impulse(kbDir, kbAmt)

func getKnockbackDir(player_root: GSPlayer) -> Vector3:
	var explosionOrigin: Vector3 = self.global_position - Vector3(0, GSTools.to_meters(10), 0) #Shift explosion oprigin down 10 hammer units to make it easier for explosions to "pop" players into air
	$vis.global_position = explosionOrigin
	return explosionOrigin.direction_to(player_root.global_position + Vector3(0, player_root.movement_component.bounding_box.shape.size.y / 2.0, 0)) #return normalized vec3 with direction from shifted explosion origin to player

func getKnockbackAmt(player_root: GSPlayer) -> float:
	var kbDamage: float = base_damage * (1 - 0.5 * min(global_position.distance_to(player_root.global_position) / radius, 1)) #no falloff damage claculation for knockback power.
	#Player mass is actually a scam and not mass at all. It is knockback multplier based on size of bounding box. and even then in TF2 its still a scam as it is now a fixed value
	#Upon release it was ratio to "volume" of standing bOunding box size. In TF2 back then bounding box shrunk to 55 hammer units high instead of 62 nowadays. Original ratio was kept to be consistent with mapping
	var player_rootMass: float = 1.0
	var kbClassMult: float = 5.0 #player_root.movement_component.knockbackMult
	var kbDamageReduction: float = 1.0 #player_root.movement_component.selfBlastDamageReduction
	if player_root.movement_component.crouched:
		player_rootMass = 0.67
	if !player_root.movement_component.grounded:
		kbClassMult = 10.0#player_root.movement_component.airborneKnockbackMult
		kbDamageReduction = .6#player_root.movement_component.selfBlastDamageReductionAir

	return min(GSTools.to_meters(1000), (kbClassMult * kbDamageReduction * kbDamage) / player_rootMass * 1.905 / 100)

func explode_physics_props(prop: RigidBody3D) -> void:
	var shiftedOrigin: Vector3 = global_position - Vector3(0, GSTools.to_meters(10), 0)
	var dir: Vector3 = shiftedOrigin.direction_to(prop.global_position)
	var dist: float = global_position.distance_to(prop.global_position)
	prop.apply_central_impulse(dir * 30 * (radius - dist))
	prop.apply_torque_impulse(dir.rotated(Vector3.UP, prop.rotation.y) * .5)
