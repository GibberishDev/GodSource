class_name godsource_player_movement
extends CharacterBody3D

@export
var upward_velocity_threshhold : float = 4.7625 #250 hammer units a second

var gravity_multiplier : float = 1.0

var is_grounded : bool = false
var is_airborne : bool = false
var is_stuck : bool = false
var current_movement_type : MOVEMENT_TYPE = MOVEMENT_TYPE.AIRBORNE

var unstuck_offsets_table : PackedVector3Array = []
var unstuck_offsets_table_id : int = 0

enum MOVEMENT_TYPE {
	AIRBORNE,
	WALK,
	SWIM,
	NOCLIP,
}


#region nodde references

@onready
var stuck_check_collider : ShapeCast3D = get_node("stuck_check_collider")

#endregion

var first_frame : bool = true
func _ready() -> void:
	unstuck_offsets_table = gen_unstuck_offsets_table()

func _physics_process(delta: float) -> void:
	process_movement(delta)
	pass

func process_movement(delta: float) -> void:
	#step 1: check if stuck and try to unstuck and move to step 14
	stuck_check_collider.force_shapecast_update()
	if stuck_check_collider.is_colliding():
		is_stuck = try_unstuck()
		print(is_stuck)
	else: #
		#step 2: check vertical velocity. Become airborne
		if velocity.y >= upward_velocity_threshhold:
			is_airborne = true
		#step 3: handle crouching
		#step 4: apply half of gravity
		velocity.y -= (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier) / ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 66) / 2.0
		#step 5: handle jumping
		#step 6: cap velocity
		if velocity.length() > 66.675:
			velocity = velocity.normalized() * 66.675 #TODO: move maximum velocity to server settings
		#step 7: if not airborne apply friction and 0 out vertical velocity
		if !is_airborne:
			velocity.y = 0.0
			#apply friction
		#step 8: accelerate
		#step 9: move and slide?
		move_and_slide()
		#step 10: check if grounded
		if is_on_floor() and velocity.y < upward_velocity_threshhold:
			is_airborne = false
		else:
			is_airborne = true
		#step 11: apply second half of gravity
		velocity.y -= (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier) / ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 66) / 2.0
		#step 12: if not airborne, zero out vertical velocity
		if !is_airborne:
			velocity.y = 0.0
		#step 13:
		if velocity.length() > 66.675:
			velocity = velocity.normalized() * 66.675 #TODO: move maximum velocity to server settings
	#step 14: check triggers to activate
	#step 15:
		#change_collision_hull_size()
	#step 16:
		#process_projectiles()
		first_frame = false
	pass

#valve unstuck algorythm goes through fixed list of player nudges. Some stuck bugs in TF2 are cause of this.
#if this table outputed minimum value of y is -0.125 hammer units. and thats it.
#Source does not try to nudge player more that in downwards direction.
#For more human frienly explanation check out Shounic video here: https://www.youtube.com/watch?v=PEhY4vE6krE

func gen_unstuck_offsets_table() -> PackedVector3Array:
	
	var table : PackedVector3Array = []
	#Little Moves
	var little_move : float = 0.125
	var y : float = -little_move
	while y <= little_move:
		table.append(Vector3(0,y,0))
		y += little_move
	var x : float = -little_move
	while x <= little_move:
		table.append(Vector3(x,0,0))
		x += little_move
	var z : float = -little_move
	while z <= little_move:
		table.append(Vector3(0,0,z))
		z += little_move
	#Remaining multi axis nudges.
	y = -little_move
	while y <= little_move:
		x = -little_move
		while x <= little_move:
			z = -little_move
			while z <= little_move:
				table.append(Vector3(x, y, z))
				z += 0.25
			x += 0.25
		y += 0.25
	
	# Big Moves.
	var yi : PackedFloat32Array = [0.0, 1.0, 6.0]
	
	for i : float in yi:
		y = i
		table.append(Vector3(0, y, 0))
	x = -2.0
	while x <= 2.0:
		table.append(Vector3(x, 0, 0))
		x += 2.0
	z = -2.0
	while z <= 2.0:
		table.append(Vector3(0, 0, z))
		z += 2.0
	
	for i : float in yi:
		y = i
		x = -2.0
		while x <= 2.0:
			z = -2.0
			while z <= 2.0:
				table.append(Vector3(x, y, z))
				z += 2.0
			x += 2.0

	#convert hammer units to meters:
	for i : int in range(table.size()):
		table[i] *= 1.905 / 100

	return table

func get_unstuck_offset() -> Vector3:
	var unstuck_offset : Vector3 = unstuck_offsets_table[unstuck_offsets_table_id % 53]
	unstuck_offsets_table_id += 1
	return unstuck_offset

func reset_unstuck_offsets_table_id() -> void:
	unstuck_offsets_table_id = 0

func try_unstuck() -> bool:
	var unstuck_offset : Vector3 = get_unstuck_offset()
	stuck_check_collider.position = unstuck_offset
	stuck_check_collider.force_shapecast_update()
	if stuck_check_collider.is_colliding():
		stuck_check_collider.position = Vector3.ZERO
		return false
	stuck_check_collider.position = Vector3.ZERO
	global_position += unstuck_offset
	reset_unstuck_offsets_table_id()
	return true
