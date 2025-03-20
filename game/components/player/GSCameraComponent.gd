## [b][color=#f0b000]!!! IMPORTANT !!![/color] - This component requires to be a child of [CharacterBody3D] to function properly[b][br][br]
## This component listens to user inputs to move parent node in 3D space. All default values aren an example implementation and are converted from TF2 and correspond to default movement of Soldier
extends Node3D

## [CharacterBody3D] parent.
@export var player_root: CharacterBody3D
@export var movement_component: PlayerGSMvtComp

@export_subgroup("Camera Settings")

@export var camera_view_height: float = 68 * 1.905 / 100
@export var camera_duck_view_heght: float = 45 * 1.905 / 100
@export var camera_zoom_ability: bool = true

@export_range(20.0, 180.0, 0.1) var camera_zoom_fov: float = 90

@export var show_axis: bool = true

var mouse_captured: bool = false
var mouse_position_pre_capture: Vector2 = Vector2.ZERO

# global var
var look_direction: Vector3 = Vector3.ZERO

# settings var
var sensitivity_x: float = 0.0015
var sensitivity_y: float = 0.0015

# state var
var camera_saved_position: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	smooth_camera(delta)  

func toggle_pointer_lock() -> void:
	if mouse_captured:
		release_pointer()
	else:
		grab_pointer()

func grab_pointer() -> void:
	mouse_position_pre_capture = get_viewport().get_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true

func release_pointer() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false
	Input.warp_mouse(mouse_position_pre_capture)

func _ready() -> void:
	grab_pointer()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		input_camera(event)

	# TODO change to ESC input action
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pointer_lock()

func input_camera(input_event: InputEventMouseMotion) -> void:
	$head.rotation.y -= input_event.screen_relative.x * sensitivity_x
	$head/camera_smoother/camera.rotation.x = clamp($head/camera_smoother/camera.rotation.x - input_event.screen_relative.y * sensitivity_y, -deg_to_rad(89), deg_to_rad(89))

	look_direction = Vector3($head/camera_smoother/camera.rotation.x, $head.rotation.y, 0)

func save_camera_position() -> void:
	if camera_saved_position == Vector3.ZERO:
		camera_saved_position = $head/camera_smoother.global_position

func smooth_camera(delta:float) -> void:
	if camera_saved_position == Vector3.ZERO:
		return

	$head/camera_smoother.global_position.y = camera_saved_position.y
	$head/camera_smoother.position.y = clampf($head/camera_smoother.position.y, -0.5, 0.5)

	var move_amplitude: float = max(player_root.velocity.length() * delta, movement_component.ground_max_speed * movement_component.get_speed_multiplier() / 2 * delta)

	$head/camera_smoother.position.y = move_toward($head/camera_smoother.position.y, 0.0, move_amplitude)
	camera_saved_position = $head/camera_smoother.global_position

	if $head/camera_smoother.position.y == 0.0:
		camera_saved_position = Vector3.ZERO

func crouch() -> void:
	save_camera_position()
	$head.position.y = camera_duck_view_heght

func uncrouch() -> void:
	save_camera_position()
	$head.position.y = camera_view_height

func get_camera_rotation() -> Vector3:
	return $head/camera_smoother/camera.global_rotation

func get_camera_direction() -> Vector3:
	var direction: Vector3 = Vector3(0, 0, -1.0).rotated(Vector3.RIGHT, get_camera_rotation().x).rotated(Vector3.UP, get_camera_rotation().y)

	return direction.normalized()

func get_angle_vectors() -> Array[Vector3]:

	var vector_forward = Vector3.FORWARD.rotated(Vector3.RIGHT, get_camera_rotation().x).rotated(Vector3.UP, get_camera_rotation().y)
	var vector_up = Vector3.UP.rotated(Vector3.RIGHT, get_camera_rotation().x).rotated(Vector3.UP, get_camera_rotation().y)
	var vector_right = Vector3.RIGHT.rotated(Vector3.RIGHT, get_camera_rotation().x).rotated(Vector3.UP, get_camera_rotation().y)

	var return_vectors : Array[Vector3] = [vector_forward, vector_up, vector_right]

	return return_vectors
