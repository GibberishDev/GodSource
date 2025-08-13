class_name godsource_player_movement
extends CharacterBody3D

@export
var upward_velocity_threshhold : float = 250 * 1.905 / 100
@export
var maximum_velocity_cap : float = 3500 * 1.905 / 100 #TODO: move maximum velocity to server settings

var gravity_multiplier : float = 1.0

var is_grounded : bool = false
var is_airborne : bool = false
var is_stuck : bool = false

var current_movement_type : MOVEMENT_TYPE = MOVEMENT_TYPE.AIRBORNE

var unstuck_offsets_table : PackedVector3Array = []
var unstuck_offsets_table_id : int = 0
var unstuck_check_timer : Timer

var standart_hull_size : Vector3 = Vector3(49 * 1.905 / 100, 83 * 1.905 / 100, 49 * 1.905 / 100)
var crouch_hull_size : Vector3 = Vector3(49 * 1.905 / 100, 63 * 1.905 / 100, 49 * 1.905 / 100)
var wish_hull_size : Vector3 = standart_hull_size

enum MOVEMENT_TYPE {
	AIRBORNE,
	WALK,
	SWIM,
	NOCLIP,
}

#region nodde references
@onready
var stuck_check_collider : ShapeCast3D = get_node("stuck_check_collider")
@onready
var player_collision_hull : CollisionShape3D = get_node("collision_hull")
#endregion

func _ready() -> void:
	update_hull()
	unstuck_offsets_table = gen_unstuck_offsets_table()

func _physics_process(delta: float) -> void:
	process_movement(delta)

func process_movement(delta: float) -> void:
	#step 1: check if stuck and try to unstuck and move to step 14
	stuck_check_collider.force_update_transform()
	stuck_check_collider.force_shapecast_update()
	if stuck_check_collider.is_colliding():
		try_unstuck()
	else:
		if is_stuck: is_stuck = false
		#step 2: check vertical velocity. Become airborne
		if velocity.y >= upward_velocity_threshhold:
			is_airborne = true
		#step 3: handle crouching
		#step 4: apply half of gravity
		velocity.y -= (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier) / ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 66) / 2.0
		#step 5: handle jumping
		#step 6: cap velocity
		if velocity.length() > maximum_velocity_cap:
			velocity = velocity.normalized() * maximum_velocity_cap
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
		if velocity.length() > maximum_velocity_cap:
			velocity = velocity.normalized() * maximum_velocity_cap
	#step 14: check triggers to activate
	#step 15: adjust collision hull
		update_hull()
	#step 16: process projectiles 
		#process_projectiles()

#region unstuck algorythm
#---
#Valve unstuck algorythm goes through fixed list of player nudges. Some stuck bugs in TF2 are caused by this.
#If this table outputed minimum value of y is -0.125 hammer units. And thats it.
#Source engine does not try to nudge player more that in downwards direction.
#For more human frienly explanation check out Shounic video here: https://www.youtube.com/watch?v=PEhY4vE6krE
#--- GibbDev 12AUG2028

func gen_unstuck_offsets_table() -> PackedVector3Array:
	var x: float
	var y: float
	var z: float
	var table : PackedVector3Array = []
	#Little Moves --- Valve
	y = -0.125
	while y <= 0.125:
		table.append(Vector3(0,y,0))
		y += 0.125
	x = -0.125
	while x <= 0.125:
		table.append(Vector3(x,0,0))
		x += 0.125
	z = -0.125
	while z <= 0.125:
		table.append(Vector3(0,0,z))
		z += 0.125
	#Remaining multi axis nudges. --- Valve
	y = -0.125
	while y <= 0.125:
		x = -0.125
		while x <= 0.125:
			z = -0.125
			while z <= 0.125:
				table.append(Vector3(x, y, z))
				z += 0.25
			x += 0.25
		y += 0.25
	# Big Moves. --- Valve
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
	#convert hammer units to meters: --- GibbDev
	for i : int in range(table.size()):
		table[i] *= 1.905 / 100
	return table

#pull offset off the unstuck table using player offset
func get_unstuck_offset() -> Vector3:
	var unstuck_offset : Vector3 = unstuck_offsets_table[unstuck_offsets_table_id % 53]
	unstuck_offsets_table_id += 1
	return unstuck_offset

#iterate through unstuck offsets table and move player in first empty space
#HACK:	Iterates every physics frame. If it becomes a problem with physics perfomance switch to iterating at intervals.
#		Valve decided to iterate no sooner than 0.05 seconds from last iteration. Roughly every 4 physics frames at 66 pfps 
func try_unstuck() -> void:
	var unstuck_offset : Vector3
	is_stuck = true
	stuck_check_collider.position = Vector3(0.0, stuck_check_collider.shape.size.y/2.0, 0.0)
	for i:int in range(53):
		unstuck_offset = get_unstuck_offset()
		stuck_check_collider.position = unstuck_offset + Vector3(0.0, stuck_check_collider.shape.size.y/2.0, 0.0)
		stuck_check_collider.force_update_transform()
		stuck_check_collider.force_shapecast_update()
		if !stuck_check_collider.is_colliding():
			global_position += unstuck_offset
			is_stuck = false
			unstuck_offsets_table_id = 0
			break


#endregion

#region collision hull editing

func update_hull() -> void:
	if player_collision_hull.shape.size == wish_hull_size:
		return
	var size : Vector3 = wish_hull_size
	var hull : CollisionShape3D = player_collision_hull
	hull.position = Vector3(0.0, size.y/2.0, 0.0)
	stuck_check_collider.position = Vector3(0.0, size.y/2.0, 0.0)
	hull.shape.size = size
	stuck_check_collider.shape = hull.shape

#endregion
