#Me when blind:
#⣿⣿⣿⠟⠛⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢋⣩⣉⢻⣿⣿
#⣿⣿⣿⢸⣿⣶⣕⣈⠹⠿⠿⠿⠿⠟⠛⣛⢋⣰⠣⣿⣿⢸⣿⣿
#▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
#░░░░░░▀█▄▀▄▀██████░▀█▄▀▄▀████▀
#░░░░░░░░▀█▄█▄███▀░░░▀██▄█▄█▀░░
#⣿⣿⣿⣿⣆⢩⣝⣫⣾⣿⣿⣿⣿⡟⠿⠿⠦⠄⠸⠿⣻⣿⡄⢻
#⣿⣿⣿⣿⣿⡄⢻⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⠇⣼
#⣿⣿⣿⣿⣿⣿⡄⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣰⣿
#⣿⣿⣿⣿⣿⣿⠇⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢀⣿⣿
#⣿⣿⣿⣿⣿⠏⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿
#⣿⣿⣿⣿⠟⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿
#⣿⣿⣿⠋⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⣿⣿

class_name GodsourceCameraAnchor3D
extends Node3D
#TODO: ADAPT TO MULTIPLAYER

var multiplayer_authority_id: int = 0
var anchor_id : int = 0
var can_be_controlled : bool = true

var anchor_position_offset : Vector3 = Vector3.ZERO

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

##maximum distance of camera smoothing. If distance is exceeded camera snapped to anchor position instead
var max_smoothing_distance : float = 1.0
var smoothing_frames : int = 10
var start_smoothing_position : Vector3 = Vector3.ZERO

#TODO: remove and make global script in input gathering class
var mouse_motion : Vector2
var mouse_moved : bool = false

#region native methods

func _ready() -> void:
	adjust_mounted_cameras()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if start_smoothing_position != Vector3.ZERO:
		if owner is CharacterBody3D:
			smooth_camera(delta, owner.velocity)
		else:
			smooth_camera(delta)
	update_vectors()
	update_rotations()
	view_angle = $smoother/anchor.global_rotation
	adjust_mounted_cameras()

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

#endregion

#region camera mounting

func mount_camera(camera: Node3D) -> void:
	if mounted_cameras.find(camera) != -1: return #already mounted
	#TODO: check if mounted anywhere else and unmount
	mounted_cameras.append(camera)
	adjust_mounted_cameras()

func unmount_camera(camera: Node3D) -> void:
	mounted_cameras.erase(camera)

func adjust_mounted_cameras() -> void:
	for i : Node3D in mounted_cameras:
		i.global_position = $smoother/anchor.global_position
		i.global_rotation = $smoother/anchor.global_rotation
		#scale?

#endregion

#region input

func rotate_with_mouse() -> void:
	if !mouse_moved: return
	var motion : Vector2 = get_mouse_motion()
	var motion_x : float = motion.x
	var motion_y : float = motion.y
	motion_x *= client_setting_mouse_sensetivity_x
	motion_y *= client_setting_mouse_sensetivity_y
	rotate_y(-motion_x)
	$smoother/anchor.rotate_x(-motion_y)
	$smoother/anchor.rotation.x = clampf($smoother/anchor.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func get_mouse_motion() -> Vector2:
	#TODO: replace with hook to input gathering class
	return mouse_motion

#endregion

#region anchor properties

func update_vectors() -> void:
	forward = Vector3.FORWARD.rotated(Vector3.RIGHT, $smoother/anchor.rotation.x).rotated(Vector3.UP, rotation.y)
	up = Vector3.UP.rotated(Vector3.RIGHT, $smoother/anchor.rotation.x).rotated(Vector3.UP, rotation.y)
	right = Vector3.RIGHT.rotated(Vector3.RIGHT, $smoother/anchor.rotation.x).rotated(Vector3.UP, rotation.y)

func update_rotations() -> void:
	pitch = $smoother/anchor.rotation.x
	yaw = rotation.y
	roll = $smoother/anchor.rotation.z

#endregion

# func set_anchor_position_offset(offset: Vector3) -> void:
# 	pass

# func set_anchor_rotation_offset(offset: Vector3) -> void:
# 	pass

#region smoothing

func save_start_smoothing_position() -> void:
	start_smoothing_position = $smoother.global_position

func smooth_camera(delta: float, owner_velocity: Vector3 = Vector3.ZERO) -> void:
	$smoother.global_position.y = start_smoothing_position.y
	if start_smoothing_position.distance_to(global_position) > max_smoothing_distance:
		start_smoothing_position = Vector3.ZERO
		$smoother.position = Vector3.ZERO
		return
	var movement_amount : float = 3.0 * delta
	if owner_velocity != Vector3.ZERO:
		movement_amount = owner_velocity.length() * delta * 2
	print($smoother.global_position.move_toward(global_position, movement_amount), $smoother.global_position)
	$smoother.global_position = $smoother.global_position.move_toward(global_position, movement_amount)
	start_smoothing_position = $smoother.global_position
	if $smoother.position == Vector3.ZERO:
		start_smoothing_position = Vector3.ZERO

#endregion
