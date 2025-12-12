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

#region native methods

func _ready() -> void:
	adjust_mounted_cameras()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if start_smoothing_position != Vector3.ZERO:
		if owner is GSPlayer:
			smooth_camera(delta, owner)
		else:
			smooth_camera(delta)
	update_vectors()
	update_rotations()
	view_angle = $smoother/anchor.global_rotation
	adjust_mounted_cameras()
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
	if !GSInput.mouse_moved: return
	var motion : Vector2 = GSInput.mouse_motion_with_sens #TODO: change to check client authority
	var motion_x : float = motion.x
	var motion_y : float = motion.y
	rotate_y(-motion_x)
	$smoother/anchor.rotate_x(-motion_y)
	$smoother/anchor.rotation.x = clampf($smoother/anchor.rotation.x, deg_to_rad(-89), deg_to_rad(89))


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

func smooth_camera(delta: float, player_owner: GSPlayer = null) -> void:
	$smoother.global_position.y = start_smoothing_position.y
	print(start_smoothing_position.distance_to(global_position))
	if start_smoothing_position.distance_to(global_position) > max_smoothing_distance or start_smoothing_position.distance_to(global_position) < 0.1:
		reset_smoothing()
		return
	var movement_amount : float = 3.0 * delta
	if player_owner != null:
		movement_amount = max((player_owner.velocity * Vector3(1,0,1)).length() * delta / 1.5, player_owner.max_ground_speed * delta / 1.5)
	$smoother.global_position = $smoother.global_position.move_toward(global_position, movement_amount)
	start_smoothing_position = $smoother.global_position
	if $smoother.position == Vector3.ZERO:
		start_smoothing_position = Vector3.ZERO

func reset_smoothing() -> void:
	start_smoothing_position = Vector3.ZERO
	$smoother.position = Vector3.ZERO

#endregion
