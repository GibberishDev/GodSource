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
	if Input.is_action_pressed("attack1") and !attackDelayActive:
		attackDelayActive = true
		var rocket = rocketScene.instantiate()
		rocket.dir = camComp.getCamDir()
		rocket.rotation = camComp.getCamRot()
		rocket.speed = 1100 * 1.905 / 100
		rocket.position = global_position + Vector3(0, 1.295, 0)
		get_tree().root.add_child(rocket)
		print("Spawned a rocket! - ", Engine.get_physics_frames())
		await get_tree().create_timer(attackDelay).timeout
		attackDelayActive = false
