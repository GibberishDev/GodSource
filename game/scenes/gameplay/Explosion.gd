class_name Explosion
extends Node3D

enum DAMAGETYPE {GENERIC, BLAST, KNOCKBACK, FIRE} #TODO: move into separate autoload damage type class idk

##Type of damage to deal. May be smth like fire damage, blast damage, generic(untyped or without any special behaviour) damage 
var damageType : DAMAGETYPE #TODO: when damage types are introduced hook up

## How big explosion will be 
var radius : float = 0.0

## Base damage of an explosion. IMPORTANT! This is not the same as actual damage recieved to health. in TF2 all knockback is calculated based on damage. So to make game more consistent Valve went the way of setting separate damage and base damage for weapons(ex. for blast jumping calculations all rocket launchers have base damage of 90.0)
var baseDamage: float = 0.0

var damage: float = 0.0
var projectileOwner: Player = null
var particleScene : PackedScene

func _ready() -> void:
	$detectionRange.shape.radius = radius
	$vis.mesh.radius = radius
	$vis.mesh.height = radius * 2
	$vis.reparent(get_node(".."))
	causeEffects()

func _physics_process(_delta: float) -> void:
	explode()
	queue_free()


func explode() -> void:
	var targets : Array = getTargets()
	if targets == []: return
	for i in range(targets.size()):
		if targets[i] is Player:
			explodePlayer(targets[i])

func checkHit(entList: Array) -> Array:
	#TODO: implement visibility check from explosion to hit entities bounding boxes
	return entList

func causeEffects() -> void:
	return
	#TODO: Add explosion visualisation


## ---[br]
func getTargets() -> Array:
	var targets = []
	$detectionRange.force_shapecast_update()
	var num = $detectionRange.get_collision_count()
	for i in range(num):
		targets.append($detectionRange.get_collider(i))
	return targets

func explodePlayer(plr: Player) -> void:
	#TODO: add health calculation
	var kbDir = getKnockbackDir(plr)
	var kbAmt = getKnockbackAmt(plr)
	plr.mvtComp.applyImpulse(kbDir, kbAmt)

func getKnockbackDir(plr: Player) -> Vector3:
	var explosionOrigin = self.global_position + Vector3(0, 10 * 1.905 / 100, 0) #Shift explosion oprigin down 10 hammer units to make it easier for explosions to "pop" players into air
	return explosionOrigin.direction_to(plr.global_position + Vector3(0, plr.mvtComp.bBox.shape.size.y / 2.0, 0)) #return normalized vec3 with direction from shifted explosion origin to player

func getKnockbackAmt(plr: Player) -> float:
	var kbDamage : float = baseDamage * (1 - 0.5 * min(global_position.distance_to(plr.global_position) / radius, 1.0)) #no falloff damage claculation for knockback power.
	#Player mass is actually a scam and not mass at all. It is knockback multplier based on size of bounding box. and even then in TF2 its still a scam as it is now a fixed value
	#Upon release it was ratio to "volume" of standing bOunding box size. In TF2 back then bounding box shrunk to 55 hammer units high instead of 62 nowadays. Original ratio was kept to be consistent with mapping
	var plrMass = 1.0
	if plr.mvtComp.crouched:
		plrMass = 0.67
	var kbClassMult = plr.mvtComp.knockbackMult
	var kbDamageReduction = plr.mvtComp.selfBlastDamageReduction
	if !plr.mvtComp.grounded:
		kbClassMult = plr.mvtComp.airborneKnockbackMult
		kbDamageReduction = plr.mvtComp.selfBlastDamageReductionAir
	return min(1000, (kbClassMult * kbDamageReduction * kbDamage) / plrMass) * 1.905 / 100
