class_name GodsourceCameraAnchor3D
extends Node3D

#TODO: ADAPT TO MULTIPLAYER

var multiplayer_authority_id: int = 0
var anchor_id : int = 0
var can_be_controlled : bool = true

var forward: Vector3 = Vector3.FORWARD
var right: Vector3 = Vector3.RIGHT
var up: Vector3 = Vector3.UP
var view_angle: Vector3 = Vector3.ZERO
var pitch : float = 0
var yaw : float = 0
var roll : float = 0

var mounted_cameras : Array[Node3D] = []

var client_setting_mouse_sensetivity_x : float = 0.003 #TODO: change tobe read from client settings script
var client_setting_mouse_sensetivity_y : float = 0.0045 #TODO: change tobe read from client settings script

func _ready() -> void:
	adjust_mounted_cameras()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void: #TODO: replace with process to work server side where no input is possible
	mouse_moved = false
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_moved = true
		mouse_motion = event.screen_relative
	
	if event is InputEventKey:
		if Input.is_physical_key_pressed(KEY_ESCAPE):
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if can_be_controlled:
		rotate_with_mouse()
	adjust_mounted_cameras()

func mount_camera(camera: Node3D) -> void:
	if mounted_cameras.find(camera) != -1: return
	mounted_cameras.append(camera)

func unmount_camera(camera: Node3D) -> void:
	mounted_cameras.erase(camera)

func adjust_mounted_cameras() -> void:
	for i : Node3D in mounted_cameras:
		i.global_transform = $anchor.global_transform

func rotate_with_mouse() -> void:
	if !mouse_moved: return
	var motion : Vector2 = get_mouse_motion()
	var motion_x : float = motion.x
	var motion_y : float = motion.y
	motion_x *= client_setting_mouse_sensetivity_x
	motion_y *= client_setting_mouse_sensetivity_y
	rotate_y(-motion_x)
	$anchor.rotate_x(-motion_y)
	$anchor.rotation.x = clampf($anchor.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func get_mouse_motion() -> Vector2:
	#TODO: replace with hook to input gathering class
	return mouse_motion

#TODO: remove and make global script in input gathering class
var mouse_motion : Vector2
var mouse_moved : bool = false

func _process(delta: float) -> void:
	update_vectors()
	update_rotations()
	view_angle = $anchor.global_rotation

func update_vectors() -> void:
	forward = Vector3.FORWARD.rotated(Vector3.RIGHT, $anchor.rotation.x).rotated(Vector3.UP, rotation.y)
	up = Vector3.UP.rotated(Vector3.RIGHT, $anchor.rotation.x).rotated(Vector3.UP, rotation.y)
	right = Vector3.RIGHT.rotated(Vector3.RIGHT, $anchor.rotation.x).rotated(Vector3.UP, rotation.y)

func update_rotations() -> void:
	pitch = $anchor.rotation.x
	yaw = rotation.y
	roll = $anchor.rotation.z
