class_name Explosion
extends Node3D

enum DAMAGETYPE {GENERIC, BLAST, KNOCKBACK, FIRE} #TODO: move into separate autoload damage type class idk

##Type of damage to deal. May be smth like fire damage, blast damage, generic(untyped or without any special behaviour) damage 
var damageType : DAMAGETYPE #TODO: when damage types are introduced hook up

## How big explosion will be 
var radius : float = 0.0

## Base damage of an explosion. IMPORTANT! This is not the same as actual damage recieved to health. in TF2 all knockback is calculated based on damage. So to make game more consistent Valve went the way of setting separate damage and base damage for weapons(ex. for blast jumping calculations all rocket launchers have base damage of 90.0)
var baseDamage: float = 0.0
@export
var debugShape := bool(true)
var damage: float = 0.0
var projectileOwner: GSPlayer = null
var particleScene = preload("res://game/scenes/particles/explosion.tscn")

func _ready() -> void:
	$detectionRange.shape.radius = radius
	causeEffects()

func _physics_process(_delta: float) -> void:
	explode()
	if debugShape:
		$vis.visible = true
		$vis.mesh.radius = radius
		$vis.mesh.height = radius * 2
		$vis.reparent(get_node(".."))
	queue_free()


func explode() -> void:
	var targets : Array = getTargets()
	if targets == []: return
	for i in range(targets.size()):
		if targets[i] is GSPlayer:
			explodePlayer(targets[i])
		if targets[i].is_in_group("worldPropWeapon") and targets[i] is RigidBody3D:
			explodePhysProps(targets[i])

func checkHit(entList: Array) -> Array:
	#TODO: implement visibility check from explosion to hit entities bounding boxes
	return entList

func causeEffects() -> void:
	var p_expl = particleScene.instantiate()
	p_expl.position = global_position
	p_expl.emitting(true)
	get_tree().root.add_child(p_expl)


## ---[br]
func getTargets() -> Array:
	var targets = []
	$detectionRange.force_shapecast_update()
	var num = $detectionRange.get_collision_count()
	for i in range(num):
		targets.append($detectionRange.get_collider(i))
	return targets

func explodePlayer(plr: GSPlayer) -> void:
	#TODO: add health damage calculation
	var kbDir = getKnockbackDir(plr)
	var kbAmt = getKnockbackAmt(plr)
	plr.mvtComp.applyImpulse(kbDir, kbAmt)

func getKnockbackDir(plr: GSPlayer) -> Vector3:
	var explosionOrigin = self.global_position - Vector3(0, 10 * 1.905 / 100, 0) #Shift explosion oprigin down 10 hammer units to make it easier for explosions to "pop" players into air
	$vis.global_position = explosionOrigin
	return explosionOrigin.direction_to(plr.global_position + Vector3(0, plr.mvtComp.bBox.shape.size.y / 2.0, 0)) #return normalized vec3 with direction from shifted explosion origin to player

func getKnockbackAmt(plr: GSPlayer) -> float:
	var kbDamage : float = baseDamage * (1 - 0.5 * min(global_position.distance_to(plr.global_position) / radius, 1)) #no falloff damage claculation for knockback power.
	#Player mass is actually a scam and not mass at all. It is knockback multplier based on size of bounding box. and even then in TF2 its still a scam as it is now a fixed value
	#Upon release it was ratio to "volume" of standing bOunding box size. In TF2 back then bounding box shrunk to 55 hammer units high instead of 62 nowadays. Original ratio was kept to be consistent with mapping
	var plrMass = 1.0
	var kbClassMult = 5.0#plr.mvtComp.knockbackMult
	var kbDamageReduction = 1.0#plr.mvtComp.selfBlastDamageReduction
	if plr.mvtComp.crouched:
		plrMass = 0.67
	if !plr.mvtComp.grounded:
		kbClassMult = 10.0#plr.mvtComp.airborneKnockbackMult
		kbDamageReduction = .6#plr.mvtComp.selfBlastDamageReductionAir
	return min(1000 * 1.905 / 100, (kbClassMult * kbDamageReduction * kbDamage) / plrMass * 1.905 / 100)

func explodePhysProps(prop: RigidBody3D) -> void:
	print(prop)
	var shiftedOrigin = global_position - Vector3(0, 10*1.905/100, 0)
	var dir = shiftedOrigin.direction_to(prop.global_position)
	var dist = global_position.distance_to(prop.global_position)
	prop.apply_central_impulse(dir * 30 * (radius - dist))
	prop.apply_torque_impulse(dir.rotated(Vector3.UP, prop.rotation.y) * .5)
