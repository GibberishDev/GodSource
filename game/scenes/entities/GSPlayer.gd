class_name GSPlayer
extends CharacterBody3D

## This Is root of player class. It is what get modified by components.

const rocket: Resource = preload("res://game/scenes/gameplay/projectiles/rocket.tscn")

var attack_delay: float = 0.8
var attack_delay_active: bool = false
var can_swim: bool = true

@export var movement_component: Node3D
@export var camera_component: Node3D
@export var hud_component: CanvasLayer
@export var health_component: Node

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("mouse1") and !attack_delay_active and GSGlobal.mouse_captured: #TODO: Move attack into invetory componenet once created
		attack_delay_active = true

		var rocket: Node = rocket.instantiate()

		rocket.direction = camera_component.get_camera_direction()
		rocket.rotation = camera_component.get_camera_rotation()
		rocket.speed = 1100 * 1.905 / 100

		var offset: Vector3 = Vector3.ZERO

		if movement_component.crouched:
			offset = (Vector3(12, 8, -23.5) * 1.905 / 100).rotated(Vector3.RIGHT, camera_component.get_camera_rotation().x).rotated(Vector3.UP, camera_component.get_camera_rotation().y)
		else:
			offset = (Vector3(12, -3, -23.5) * 1.905 / 100).rotated(Vector3.RIGHT, camera_component.get_camera_rotation().x).rotated(Vector3.UP, camera_component.get_camera_rotation().y)

		rocket.position = camera_component.get_node("head/camera_smoother/camera").global_position + offset

		get_tree().root.add_child(rocket)
		await get_tree().create_timer(attack_delay).timeout

		attack_delay_active = false
