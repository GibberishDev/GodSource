class_name godsource_player_movement
extends CharacterBody3D



@export
var upward_velocity_threshhold : float = 250 * 1.905 / 100
@export
var maximum_velocity_cap : float = 3500 * 1.905 / 100 #TODO: move maximum velocity to server settings
@export
var jump_velocity : float = 289 * 1.905 / 100

var gravity_multiplier : float = 1.0

var is_grounded : bool = false
var is_crouched : bool = false
var is_crouching_animation : bool = false
var is_uncrouching_animation : bool = false
var is_airborne : bool = false
var is_stuck : bool = false

var current_movement_type : MOVEMENT_TYPE = MOVEMENT_TYPE.AIRBORNE

var unstuck_offsets_table : PackedVector3Array = []
var unstuck_offsets_table_id : int = 0
var unstuck_check_timer : Timer
var queue_uncrouch : bool = false

@export
var standart_hull_size : Vector3 = Vector3(49 * 1.905 / 100, 83 * 1.905 / 100, 49 * 1.905 / 100) #TODO: change default
@export
var crouch_hull_size : Vector3 = Vector3(49 * 1.905 / 100, 63 * 1.905 / 100, 49 * 1.905 / 100) #TODO: change default
var wish_hull_size : Vector3 = standart_hull_size


@export_category("Known bugged behavior toggles")
## Causes player jump while crouching down to be 2 hammer units highier due to not substracting 1 tick of half gravity. [br][color=gold]For explanation in source engine check this [url=https://www.youtube.com/watch?v=7z_p_RqLhkA]video[/url] by Shounic[/color]
@export
var is_crouch_jump_bug_enabled : bool = true
## Causes player jump while uncrouching to be neutered low jump caused by lack of player shift upwards and forced to be crouched when close to the ground. This also allows for much more knockback from explosives.[br][color=gold]For explanation in source engine check this [url=https://www.youtube.com/watch?v=76HDJIWfVy4]video[/url] by Shounic[/color]
@export
var is_ctap_bug_enabled : bool = true

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
var crouch_check_collider : ShapeCast3D = get_node("uncrocuh_check_collider")
@onready
var collision_hull : CollisionShape3D = get_node("collision_hull")
@onready
var crouch_timer : Timer = get_node("crouch_timer")
@onready
var uncrouch_timer : Timer = get_node("uncrouch_timer")
#endregion

#region wish control variables
var wish_crouch : bool = false
var wish_jump : bool = false
var wish_crouch_last_frame : bool = false
#endregion

func _unhandled_input(event: InputEvent) -> void: #TODO: move to input gathering script. Not bullet proof. TESTING ONLY
	if Input.is_action_just_released("jump"):
		wish_jump = false
	if Input.is_action_just_pressed("jump"):
		wish_jump = true
	if Input.is_key_pressed(KEY_F1):
		Engine.time_scale = 0.05
	if Input.is_key_pressed(KEY_F2):
		Engine.time_scale = 1.0

func _ready() -> void:
	update_hull()
	unstuck_offsets_table = gen_unstuck_offsets_table()

func _physics_process(delta: float) -> void:
	wish_crouch = Input.is_action_pressed("crouch")
	process_movement(delta)

func process_movement(delta: float) -> void:
	#step 1: check if stuck and try to unstuck and move to step 14
	check_stuck()
	if !is_stuck:
		#step 2: check vertical velocity. Become airborne
		if velocity.y >= upward_velocity_threshhold:
			is_airborne = true
		#step 3: handle crouching
		handle_crouch()
		#step 4: apply half of gravity
		velocity.y -= (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier) / ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 66) / 2.0 * Engine.time_scale
		#step 5: handle jumping
		if wish_jump and !is_airborne:
			wish_jump = false
			is_airborne = true
			if !is_crouched:
				if is_crouching_animation:
					crouch_jump()
				elif is_uncrouching_animation and is_ctap_bug_enabled:
					ctap()
				else:
					velocity.y = jump_velocity - (((ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier) / Engine.get_physics_ticks_per_second()) / 2.0)
					print(velocity)
			
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
		velocity.y -= (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier) / ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 66) / 2.0 * Engine.time_scale
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

func check_stuck() -> void:
	stuck_check_collider.force_update_transform()
	stuck_check_collider.force_shapecast_update()
	if stuck_check_collider.is_colliding():
		try_unstuck()
	else:
		is_stuck = false

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

#region crouching

#---
# Writing this in full cause im going insane...
# Character crouching is way more complex in source engine as it actually takes time for character to crouch or uncrouch
# If player wishes to crouch there are sseveral checks done. If im capable of it I will reordder checks in this commen in order they are actually done.
# (aka if you see this sentence I failed to do so :P)
#	Check for state from last frame: if player changed their mind since last frame
#	Check if player wishes to crouch or uncrouch
#	Check if player is fully crouched already or is in process of uncrouching or uncrouching
#	Check if player is on the ground
#	Check if collider, for space that player would occupy by uncrouching, is colliding
#	Depending on checks there would be different outcomes and not only binary crouched/incrouched (I wish lmao)

#--- GibbDev 12AUG2028






func handle_crouch() -> void:
	if !wish_crouch and (is_crouched or is_crouching_animation):
		queue_uncrouch = true
	
	if queue_uncrouch:
		try_uncrouch()
		return
	
	if (wish_crouch == wish_crouch_last_frame): return
	wish_crouch_last_frame = wish_crouch

	if wish_crouch:
		queue_uncrouch = false
		if is_on_floor():
			start_delayed_crouch()
		else:
			position.y += standart_hull_size.y - crouch_hull_size.y
			crouch()
			return
	else:
		if !is_on_floor():
			position.y -= standart_hull_size.y - crouch_hull_size.y
			uncrouch()
			return
		elif is_crouched:
			queue_uncrouch = true
			try_uncrouch()
			return



func crouch() -> void:
	queue_uncrouch = false
	crouch_timer.stop()
	uncrouch_timer.stop()
	wish_hull_size = crouch_hull_size
	update_hull()
	is_crouching_animation = false
	is_uncrouching_animation = false
	is_crouched = true

func uncrouch() -> void:
	queue_uncrouch = false
	crouch_timer.stop()
	uncrouch_timer.stop()
	wish_hull_size = standart_hull_size
	update_hull()
	is_crouching_animation = false
	is_uncrouching_animation = false
	is_crouched = false

func start_delayed_crouch() -> void:
	if is_crouching_animation: return
	is_uncrouching_animation = false
	uncrouch_timer.stop()
	is_crouching_animation = true
	crouch_timer.start()

func start_delayed_uncrouch() -> void:
	if is_uncrouching_animation: return
	is_crouching_animation = false
	crouch_timer.stop()
	is_uncrouching_animation = true
	uncrouch_timer.start()


func try_uncrouch() -> void:
	var check_offset : float = (standart_hull_size.y - (standart_hull_size.y - crouch_hull_size.y)) / 2.0
	if is_on_floor():
		crouch_check_collider.position = Vector3(0, crouch_hull_size.y + ((standart_hull_size.y - crouch_hull_size.y) / 2.0), 0)
		crouch_check_collider.force_update_transform()
		crouch_check_collider.force_shapecast_update()
		if !crouch_check_collider.is_colliding():
			start_delayed_uncrouch()
	else:
		crouch_check_collider.position = Vector3(0, (standart_hull_size.y - crouch_hull_size.y) / -2.0, 0)
		crouch_check_collider.force_update_transform()
		crouch_check_collider.force_shapecast_update()
		if !crouch_check_collider.is_colliding():
			uncrouch()


func crouch_jump() -> void: #invokled from jumping handle
	print("crouch_jump_triggered")
	crouch()
	if is_crouch_jump_bug_enabled:
		velocity.y = jump_velocity
	else:
		velocity.y = jump_velocity - (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier / Engine.get_physics_ticks_per_second() / 2.0)
	position.y += standart_hull_size.y - crouch_hull_size.y


func ctap() -> void: #invokled from jumping handle
	print("ctap_triggered")
	crouch()
	velocity.y = jump_velocity - (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier / Engine.get_physics_ticks_per_second() / 2.0)

func finish_uncrouch() -> void:
	wish_hull_size = standart_hull_size
	update_hull()
	is_crouched = false
	is_uncrouching_animation = false
	queue_uncrouch = false
#endregion

#region collision hull editing

func update_hull() -> void:
	if collision_hull.shape.size == wish_hull_size:
		return
	var size : Vector3 = wish_hull_size
	var hull : CollisionShape3D = collision_hull
	hull.position = Vector3(0.0, size.y/2.0, 0.0)
	stuck_check_collider.position = Vector3(0.0, size.y/2.0, 0.0)
	hull.shape.size = size
	stuck_check_collider.shape = hull.shape

#endregion
