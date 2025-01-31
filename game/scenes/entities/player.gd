class_name Player
extends CharacterBody3D

## This Is root of player class. It is what get modified by components.

var uiFocused : bool = false

@onready
var rocketScene = preload("res://game/scenes/gameplay/projectiles/rocket.tscn")
var attackDelay := float(0.8)
var attackDelayActive := bool(false)

@onready
var mvtComp : Node3D = get_node("movementComponent")
@onready
var camComp : Node3D = get_node("cameraComponent")
@onready
var healtComp : Node = null

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("attack1") and !attackDelayActive: #TODO: Move attack into invetory componenet once created
		attackDelayActive = true
		var rocket = rocketScene.instantiate()
		rocket.dir = camComp.getCamDir()
		rocket.rotation = camComp.getCamRot()
		rocket.speed = 1100 * 1.905 / 100
		var offset := Vector3.ZERO
		if mvtComp.crouched:
			offset = (Vector3(12, 8, -23.5) * 1.905 / 100).rotated(Vector3.RIGHT, camComp.getCamRot().x).rotated(Vector3.UP, camComp.getCamRot().y)
		else:
			offset = (Vector3(12, -3, -23.5) * 1.905 / 100).rotated(Vector3.RIGHT, camComp.getCamRot().x).rotated(Vector3.UP, camComp.getCamRot().y)
		rocket.position = camComp.get_node("head/camSmoother/cam").global_position + offset
		get_tree().root.add_child(rocket)
		await get_tree().create_timer(attackDelay).timeout
		attackDelayActive = false
		#Remove after testing rocket jumping height
