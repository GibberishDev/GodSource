extends Node

@onready
var P : CharacterBody3D = get_node("..")
@onready
var mvmtComp : Node3D = P.get_node("GSMvtComp")

@export_category("Health")
@export
var maxHealth := float(200);
var health := float (0)

func _ready():
	health = maxHealth

func damage(amt: float) -> void:
	health -= amt
	if health <= 0: death()

func death() -> void:
	#TODO: Implement dying lmao
	print("You are dead. Not big surprise")

func explosiveDamage(damage: float, baseDamage: float, origin: Vector3, explosionRadius: float) -> void:
	#TODO: hook up damage
	var dir = (origin + Vector3(0,10*1.905,0)).direction_to(P.get_global_position() + Vector3(0,mvmtComp.bBox.shape.size.y / 2.0,0))
	var amt = baseDamage * (1.0 - .5 * min(origin.distance_to(P.global_position) / explosionRadius, 1))
	mvmtComp.applyImpulse(dir, amt)
	
