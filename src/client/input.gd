extends Node

var setting_null_movement : bool = true

var wish_jump          : bool = false
var wish_move_forward  : bool = false
var wish_move_back : bool = false
var wish_move_right    : bool = false
var wish_move_left     : bool = false
var look_dir           : Vector2 = Vector2(0, 0)
var move_strafe_dir : int = 0
var move_dir : int = 0


func get_movement_wish_direction() -> Vector2:
	wish_move_right = Input.is_action_pressed("right")
	wish_move_left = Input.is_action_pressed("left")
	wish_move_forward = Input.is_action_pressed("forward")
	wish_move_back = Input.is_action_pressed("back")

	if Input.is_action_just_pressed("right"): move_strafe_dir = 1
	if Input.is_action_just_pressed("left"): move_strafe_dir = -1
	if Input.is_action_just_pressed("forward"): move_dir = 1
	if Input.is_action_just_pressed("back"): move_dir = -1

	if Input.is_action_just_released("right"):
		wish_move_right = false
		if wish_move_left:
			move_strafe_dir = -1
		else:
			move_strafe_dir = 0
	if Input.is_action_just_released("left"):
		wish_move_left = false
		if wish_move_right:
			move_strafe_dir = 1
		else:
			move_strafe_dir = 0
	if Input.is_action_just_released("forward"):
		wish_move_forward = false
		if wish_move_back:
			move_dir = -1
		else:
			move_dir = 0
	if Input.is_action_just_released("back"):
		wish_move_back = false
		if wish_move_forward:
			move_dir = 1
		else:
			move_dir = 0
	

	return Vector2(move_dir, move_strafe_dir)
		
