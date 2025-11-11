class_name GodsourcePlayerMovement3D
extends CharacterBody3D

## Class description TBD

#region variables

#region server defined variables #TODO: move to server script later
## Maximum walking speed base value. 300 hu/s is team fortres 2 default
var maximum_walking_speed_base : float = 300 * 1.905 / 100
## Amount of velocity enitity can have. Any more is capped to this value
var maximum_velocity_cap : float = 3500 * 1.905 / 100 #TODO: move maximum velocity to server settings
## Global multiplier of surface friction used in [method GodsourcePlayerMovement3D.apply_friction] method
var server_variable_friction : float = 4.0
## Global stop speed threshold used in [method GodsourcePlayerMovement3D.apply_friction] method
var server_variable_stop_speed : float = 100 * 1.905 / 100
var server_variable_max_speed : float = 320 * 1.905 / 100 #TODO: rename to something more sensible cause it isnt in source engine.
var server_variable_air_acceleration : float = 10
#endregion

#region client settings variables #TODO: echange for getters whenever client settings are implemented
var client_setting_null_movement : bool = true
#endregion

#region Exported variables
@export
var max_ground_speed : float = 240 * 1.905 / 100
## Multiplier of default server defined max walking speed.
## In TF2 100% is equal to 300 hu/s (4.527 m/s).[br]133% (400 hu/s) - Scout[br]107% (321 hu/s) - Spy, Medic[br]100% (300hu/s) - Pyro, Engineer, Sniper[br]93.(3)% (280 hu/s) - Demoman[br]80% (240 hu/s) - Soldier[br]76.(6)% (230hu/s) - Heavy
@export
var max_ground_speed_multiplier : float = 1.0
## Amount of vertical velocity that needed to be exceeded for player to become airborne
@export
var upward_velocity_threshhold : float = 250 * 1.905 / 100
## Vertical velocity given to player upon jumping. See [method handle_jumping] for exceptions
@export
var jump_strength : float = 289 * 1.905 / 100
## Amount of mid air jumps player can perform without touching ground
@export
var maximum_mid_air_jumps : int = 0
## Size of player bounding box hull in normal state
@export
var standart_hull_size : Vector3 = Vector3(49 * 1.905 / 100, 83 * 1.905 / 100, 49 * 1.905 / 100) #TODO: change default
## Size of player bounding box hull in crouched state
@export
var crouch_hull_size : Vector3 = Vector3(49 * 1.905 / 100, 63 * 1.905 / 100, 49 * 1.905 / 100) #TODO: change default
@export_subgroup("Known bugged behavior toggles")
## Causes player jump while crouching down to be 2 hammer units highier due to not substracting 1 tick of half gravity. [br][color=gold]For explanation in source engine check this [url=https://www.youtube.com/watch?v=7z_p_RqLhkA]video[/url] by Shounic[/color]
@export
var is_crouch_jump_bug_enabled : bool = true
## Causes player jump while uncrouching to be neutered low jump caused by lack of player shift upwards and forced to be crouched when close to the ground. This also allows for much more knockback from explosives.[br][color=gold]For explanation in source engine check this [url=https://www.youtube.com/watch?v=76HDJIWfVy4]video[/url] by Shounic[/color]
@export
var is_ctap_bug_enabled : bool = true
## Causes player to be able to jump as soon as player touches ground, bypassing ground friction
@export
var is_bhop_bug_enabled : bool = true
## Does not reset player jump key state even if unable to jump at this frame. Meaning that whicj jump key held down player would be able to jump as soon as they touch the ground, performing a bhop, if its enabled. If bhop is disabled frition will still apply
@export
var is_auto_jump_enabled : bool = false
## Limit player movement speed to [jump_speed_cap]
@export
var limit_bhop_speed: bool = true
## Limit player movement speed to 1.2 times the max walking speed upon jumping. Preventative measure to cripple bhop bug
@export
var jump_speed_cap: float = 1.2
@export
var max_air_speed : float = 30 * 1.905 / 100
#endregion

#region player state variables
##	Indicates if player is grounded.[br][color=orange]IMPORTANT! NOT THE SAME AS [method CharacterBody3D.is_on_floor][/color].[br]main difference that player is considered airborne the frame their vertical velocity exceeds [member upward_velocity_threshhold]
var is_airborne : bool = false
##	Indicates if player is fully crouched.
var is_crouched : bool = false
##	Indicates if player is in process of crouching.
var is_crouching_animation : bool = false
##	Indicates if player is in process of uncrouching.
var is_uncrouching_animation : bool = false
## Indicates if player is stuck inside the solid geometry. See [method check_stuck] for explanation
var is_stuck : bool = false
## Surface friction is used in [method apply_friction] method to slow down player movement. This value is modified depending on surface player stand on on step 10 in [method process_movement] method.
var surface_friction: float = 1.0
#endregion

#region local variables
## Current player movement type from [enum MOVEMENT_TYPE]
var current_movement_type : MOVEMENT_TYPE = MOVEMENT_TYPE.AIRBORNE
var unstuck_offsets_table : PackedVector3Array = []
var unstuck_offsets_table_id : int = 0
var unstuck_check_timer : Timer
var queue_uncrouch : bool = false
var wish_hull_size : Vector3 = standart_hull_size
var gravity_multiplier : float = 1.0
var current_mid_air_jumps : int = 0
var ground_acceleration : float = 10
#endregion

#region enum defenitions
## Player movement type enumerator that dictates player movement properties
enum MOVEMENT_TYPE {
	AIRBORNE, ## Player is airborne
	WALK, ## Player is walking
	SWIM, ## Player is considered swimming through liquid
	NOCLIP, ## No collision fly mode
}
#endregion

#region node references
## Reference to the stuck_check_collider node
@onready
var stuck_check_collider : ShapeCast3D = get_node("stuck_check_collider")
## Reference to the uncrocuh_check_collider node[br]Node is utilized in [method check_stuck] method to determine where player can be nudged to 
@onready
var crouch_check_collider : ShapeCast3D = get_node("uncrocuh_check_collider")
## Reference to the collision_hull node
@onready
var collision_hull : CollisionShape3D = get_node("collision_hull")
## Reference to the crouch_timer node
@onready
var crouch_timer : Timer = get_node("crouch_timer")
## Reference to the uncrouch_timer node
@onready
var uncrouch_timer : Timer = get_node("uncrouch_timer")
## Reference to the camera node
@onready
var camera : Camera3D = Camera3D.new()

#endregion

#region wish control variables
#TODO: move this region to the dedicated player input gathering node for easier multiplayer client prediction and server reconciliation
## Desired input vector. left is -x, right is +x, forward is -y, back is +y
var wish_direction : Vector2 = Vector2.ZERO
## Dictionarry that keeps track of last frame of keys to determine if key was just pressed, still pressed, just released or still released
var null_movement_key_state_last_frame : Dictionary = {
	"left": false,
	"right": false,
	"forward": false,
	"back": false,
}
var wish_crouch : bool = false
var wish_jump : bool = false
var wish_crouch_last_frame : bool = false
var wish_left : bool = false
var wish_right : bool = false
var wish_forward : bool = false
var wish_back : bool = false
#endregion

#endregion variables

#region native godot methods
func _unhandled_input(_event: InputEvent) -> void: #TODO: move to input gathering script. Not bullet proof. TESTING ONLY
	wish_crouch = Input.is_action_pressed("crouch")
	if Input.is_action_just_released("jump"):
		wish_jump = false
	if Input.is_action_just_pressed("jump"):
		wish_jump = true
	if Input.is_key_pressed(KEY_F1):	#TODO: Remove after done testing. Also implement host_time_scale console command	╗ 
		Engine.time_scale = 0.05		#																					║
	if Input.is_key_pressed(KEY_F2):	#																					║
		Engine.time_scale = 1.0			#																					╝
	wish_left = Input.is_action_pressed("left")
	wish_right = Input.is_action_pressed("right")
	wish_forward = Input.is_action_pressed("forward")
	wish_back = Input.is_action_pressed("back")

func _ready() -> void:
	update_hull()
	unstuck_offsets_table = gen_unstuck_offsets_table()
	#TODO: change to asigning specific camera with multiplayer authority
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 110.0 # Yeah i have fkn prey side mounted eyes with 360 degrees of vision. How did you know?
	self.add_child(camera)
	get_node("CameraAnchor").mount_camera(camera) #each player entity has CameraAnchor by default. Might be bad to include here without checking if anchor is present (ex. player is a ghost/spectator)
	

func _physics_process(delta: float) -> void:
	process_movement(delta)
#endregion

#region main movement processing stack
##Utter dogshit
func process_movement(delta: float) -> void:
	#step 1: check if stuck and try to unstuck and move to step 14
	check_stuck()
	if !is_stuck:
		#step 2: check vertical velocity. Become airborne
		check_upward_velocity()
		#step 3: handle crouching
		handle_crouch()
		#step 4: apply half of gravity
		apply_half_gravity()
		#step 5: handle jumping
		handle_jump()	
		#step 6: cap velocity
		limit_velocity()
		#step 7: if not airborne apply friction and 0 out vertical velocity
		if !is_airborne:
			velocity.y = 0.0
			apply_friction(delta)
		#step 8: accelerate
		accelerate(delta)
		if is_on_floor():
			clip_velocity(get_floor_normal())
		elif is_on_wall_only():
			clip_velocity(get_wall_normal())
		#step 9: move and slide?. Question mark here is due to me(gibbdev) being not 100% sure if this is correct place to plug default godot implementation of move_and_slide
		#It might be out of place due to Source 1 engine processing movement and physics kinda separate as Valve traces the player bounding box before editing the velocity
		move_and_slide()
		#step 10: check if grounded and surface properties
		if check_grounded():
			is_airborne = false
			#TODO: get_surface_properties()
		else:
			is_airborne = true
			#TODO: reset_surface_properies()
		#step 11: apply second half of gravity
		apply_half_gravity()
		#step 12: if not airborne, zero out vertical velocity
		if !is_airborne:
			velocity.y = 0.0
		#step 13:
		limit_velocity()
	#step 14: check triggers to activate
	#step 15: adjust collision hull. Source engine adjusts position of world collision hul on this step. In godot it handled by physics server during move_and_slide of player parent node 
	update_hull()
	#step 16: process projectiles. NOT including releasing stored knockback. Maybe should move this step to main world order physics process
	#process_projectiles()

#endregion

#region unstuck algorythm
#---
#Valve unstuck algorythm goes through fixed list of player nudges. Some stuck bugs in TF2 are caused by this.
#If this table outputed minimum value of y is -0.125 hammer units. And thats it.
#Source engine does not try to nudge player more that in downwards direction.
#For more human frienly explanation check out Shounic video here: https://www.youtube.com/watch?v=PEhY4vE6krE
#--- GibbDev 12AUG2025

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

#region velocity checks

func check_upward_velocity() -> void:
	if velocity.y >= upward_velocity_threshhold:
		is_airborne = true

func check_grounded() -> bool:
	return (is_on_floor() and (velocity.y < upward_velocity_threshhold))

func limit_velocity() -> void:
	if velocity.length() > maximum_velocity_cap:
		velocity = velocity.normalized() * maximum_velocity_cap

#endregion

#region gravity

func apply_half_gravity() -> void:
	velocity.y -= get_gravity_tick()

func get_gravity_tick() -> float:
	var gravity : float = (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier)
	var engine_tick_multiplier : float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 66) / Engine.time_scale
	return gravity / engine_tick_multiplier / 2.0

#endregion

#region crouching
#---
# Writing this in full cause im going insane...
# Character crouching is way more complex in source engine as it actually takes time for character to crouch or uncrouch
# If player wishes to crouch there are sseveral checks done.
#	Check for state from last frame: if player changed their mind since last frame
#	Check if player wishes to crouch or uncrouch
#	Check if player is fully crouched already or is in process of uncrouching or uncrouching
#	Check if player is on the ground
#	Check if collider, for space that player would occupy by uncrouching, is colliding
#	Depending on checks there would be different outcomes and not only binary crouched/incrouched (I wish lmao)
#--- GibbDev 12AUG2025

func handle_crouch() -> void:
	#check if player wants to uncrouch and ask engine to uncrouch as soon as possible
	if !wish_crouch and (is_crouched or is_crouching_animation):
		queue_uncrouch = true
	if queue_uncrouch:
		try_uncrouch()
		return
	
	#if state didnt change from last frame -> return
	if (wish_crouch == wish_crouch_last_frame): return
	wish_crouch_last_frame = wish_crouch

	if wish_crouch:
		queue_uncrouch = false
		if is_on_floor():
			#regular crouch on floor
			start_delayed_crouch()
		else:
			#air crouch with position shift up
			position.y += standart_hull_size.y - crouch_hull_size.y 
			crouch()
			# $CameraAnchor.save_start_smoothing_position()
			$CameraAnchor.position.y = 45 * 1.905 / 100
			return
	else:
		if !is_on_floor():
			#air uncrouch with position shift down.
			crouch_check_collider.position = Vector3(0, (standart_hull_size.y - crouch_hull_size.y) / -2.0, 0)
			crouch_check_collider.force_update_transform()
			crouch_check_collider.force_shapecast_update()
			if !crouch_check_collider.is_colliding():
				position.y -= standart_hull_size.y - crouch_hull_size.y
				uncrouch()
				# $CameraAnchor.save_start_smoothing_position()
				$CameraAnchor.position.y = 68 * 1.905 / 100
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
	$CameraAnchor.save_start_smoothing_position()
	$CameraAnchor.position.y = 45 * 1.905 / 100

func start_delayed_uncrouch() -> void:
	if is_uncrouching_animation: return
	is_crouching_animation = false
	crouch_timer.stop()
	is_uncrouching_animation = true
	uncrouch_timer.start()
	$CameraAnchor.save_start_smoothing_position()
	$CameraAnchor.position.y = 68 * 1.905 / 100


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
#endregion

#region jumping

func handle_jump() -> void:
	if !is_on_floor():
		pass #TODO: make mid air jumping  copying scout from tf2
	else:
		current_mid_air_jumps = maximum_mid_air_jumps
		if wish_jump and !is_crouched:
			is_airborne = true
			if is_crouching_animation:
				crouch_jump()
			elif is_uncrouching_animation:
				ctap()
			else:
				velocity.y += jump_strength - get_gravity_tick()
			if !is_bhop_bug_enabled:
				#TODO: add one tick of friction here
				pass
			if limit_bhop_speed:
				var horizontal_velocity : Vector2 = Vector2(velocity.x, velocity.z)
				var speed : float = horizontal_velocity.length()
				if speed > maximum_walking_speed_base * max_ground_speed_multiplier * jump_speed_cap:
					horizontal_velocity = horizontal_velocity.normalized() * maximum_walking_speed_base * max_ground_speed_multiplier * jump_speed_cap
					velocity = Vector3(horizontal_velocity.x, velocity.y, horizontal_velocity.y)
	if !is_auto_jump_enabled:
		wish_jump = false

func crouch_jump() -> void: #invokled from jumping handle
	crouch()
	if is_crouch_jump_bug_enabled:
		velocity.y = jump_strength
	else:
		velocity.y = jump_strength - get_gravity_tick()
	position.y += standart_hull_size.y - crouch_hull_size.y

func ctap() -> void: #invokled from jumping handle
	crouch()
	velocity.y = jump_strength - get_gravity_tick()
	if !is_ctap_bug_enabled:
		position.y += standart_hull_size.y - crouch_hull_size.y

#endregion

#region acceleration

func apply_friction(delta: float) -> void:
	var speed : float = velocity.length() #Speed of player movement
	var new_speed : float = 0.0 #New speed after friction calculations
	var drop : float = 0.0 #Speed that needs to be dropped due to friction
	var friction : float = 1.0 #friction amount
	var control : float = 0.0 #control speed threshold
	#stop infinitelly slow movements
	if speed < (0.1 * 1.905 / 100.0):
		velocity = Vector3.ZERO
		return
	#apply ground friction
	if !is_airborne:
		friction = server_variable_friction * surface_friction
	#Bleed  off some speed, but if we have less than the bleed threshold, bleed the threshold amount.
	if (speed < server_variable_stop_speed):
		control = server_variable_stop_speed
	else:
		control = speed
	drop += control * friction * delta
	new_speed = max(0.0, speed - drop)
	#determine the proportion of new speed to old speed
	if new_speed != speed:
		new_speed /= speed
		velocity *= new_speed
	velocity -= (1.0-new_speed) * velocity

func accelerate(delta: float) -> void:
	# get_view_angles() Unused. skip compilation
	get_view_rotations()
	wish_direction = get_wish_direction()
	if is_airborne:
		air_move(delta)
	else:
		ground_move(delta)

func clip_velocity(surface_normal: Vector3, overbounce: float = 1.0) -> void:
	# get modified velocity
	var backoff: float = velocity.dot(surface_normal)
	# if negative - cancell
	if backoff >= 0: return
	# get reflected velocity component
	var change: Vector3 = surface_normal * backoff * overbounce
	# modify and return velocity
	velocity -= change
	# iterate once to make sure we aren't still moving through the plane - Valve said that, and I'd say they know a little more about Source than you do, pal, because they invented it, and then they spagetted it so that no living man could make sence of it in the ring of honor.
	var adjust: float = velocity.dot(surface_normal)
	if adjust < 0.0:
		velocity -= surface_normal * adjust


func air_move(delta: float) -> void:
	var wish_vel : Vector3 = Vector3(wish_direction.x, 0, wish_direction.y).normalized().rotated(Vector3.UP, get_view_rotations().y)
	var wish_dir : Vector3 = wish_vel.normalized()
	var wish_speed : float = max_air_speed
	var current_speed : float = velocity.dot(wish_dir)
	var add_speed : float = wish_speed - current_speed
	if add_speed <= 0: return
	var accel_speed : float = delta * server_variable_air_acceleration * min(server_variable_max_speed, max_ground_speed)# * surface_friction
	accel_speed = min(accel_speed, add_speed)
	velocity += accel_speed * wish_dir

## Changes velocity of player
func ground_move(delta: float) -> void:
	var dir : Vector3 = Vector3(wish_direction.x, 0, wish_direction.y).rotated(Vector3.UP, get_view_rotations().y).normalized()
	var current_speed : float = velocity.dot(dir)
	#TODO: make speed multiplier
	var add_speed : float = clamp(ground_acceleration * max_ground_speed * delta * max_ground_speed_multiplier, 0, max_ground_speed * max_ground_speed_multiplier - current_speed)
	velocity += dir * add_speed

## Returns [Vector2] of keyboard input. TODO: change to hook from input gatheirng class.[br]
## left is -x, right is +x, forward is -y, back is +y
func get_wish_direction() -> Vector2:
	# Null movement, known as null cancelling script or, stollen by razer and renamed, "snap-tap"
	# is a way of interpreting cardinal directions movement from keyboard input where new key press
	# overrides previous one, but also checks if other key is still held on input release to switch
	# movement direction back to held key
	if client_setting_null_movement:
		if null_movement_key_state_last_frame["left"] != wish_left: # if left bind state changed
			if wish_left: # if left bind was pressed - switch to moving left immediately
				wish_direction.x = -1
			elif wish_right: # if left bind was released and right bind is still held - switch back to moving right
				wish_direction.x = 	1
			else: # if left bind released but right bind also isnt pressed - stop strafing 
				wish_direction.x = 	0
		if null_movement_key_state_last_frame["right"] != wish_right:
			if wish_right:
				wish_direction.x = 	1
			elif wish_left:
				wish_direction.x = -1
			else:
				wish_direction.x = 	0
		if null_movement_key_state_last_frame["forward"] != wish_forward:
			if wish_forward:
				wish_direction.y = -1
			elif wish_back:
				wish_direction.y = 	1
			else:
				wish_direction.y = 	0
		if null_movement_key_state_last_frame["back"] != wish_back:
			if wish_back:
				wish_direction.y = 	1
			elif wish_forward:
				wish_direction.y = -1
			else:
				wish_direction.y = 	0
		null_movement_key_state_last_frame = {
			"left": wish_left,
			"right": wish_right,
			"forward": wish_forward,
			"back": wish_back,
		}
	else: # if null movement isnt enabled jsut use simple integer math to determine direction
		wish_direction = Input.get_vector( "left", "right", "forward", "back")
	return wish_direction

## Returns [PackedVector3Array] containing [param forward], [param up] and [param right] direction vectors from [GodsourceCameraAnchor3D]
##[br][br]
##Currently unused. Implemented just in case someone needs direction vector instead of rotating basis vectors by camera rotations
func get_view_angles() -> PackedVector3Array:
	var angles_array : PackedVector3Array
	angles_array.append($CameraAnchor.forward)
	angles_array.append($CameraAnchor.up)
	angles_array.append($CameraAnchor.right)
	return angles_array

## Returns [Vector3] containing [param pitch], [param yaw] and [param roll] from [GodsourceCameraAnchor3D]
func get_view_rotations() -> Vector3:
	return Vector3($CameraAnchor.pitch, $CameraAnchor.yaw, $CameraAnchor.roll)

#endregion

#region collision hull editing

## Updates player [CollisionShape3D] hull shape size. Sets hull and [member stuck_check_collider] position to the center of parent node and raised to half of the vertical size.[br]
## [br]
## [param new_size] - If provided sets dimensions of the collision hull to new_size. If not - set size to [member wish_hull_size]
func update_hull(new_size : Vector3 = wish_hull_size) -> void:
	if collision_hull.shape.size == new_size: return			#/if hull shape is already of new_size -> return.
																#\might cause possible descrepancy between hull shape and stuck_check_collider. If this is the case Ill go back and fix it
	collision_hull.position = Vector3(0.0, new_size.y/2.0, 0.0) # set new position of the hull
	collision_hull.shape.size = new_size 						# set new shape size
	stuck_check_collider.position = collision_hull.position 	# copy hull position
	stuck_check_collider.shape = collision_hull.shape 			# copy hull shape

#endregion
