class_name GodsourcePlayerMovement3D
extends CharacterBody3D

## This is a dedicated Godsource player movement script. This script implements a bunch of movement techniques present in Source engine. Most of them stem from bugged behaviour or coding oversights that are brought all the way from original quake and doom engines

#region variables

#region server defined variables #TODO: move to server script later
## Maximum walking speed base value. 320 hu/s is team fortres 2 default
var maximum_walking_speed_base : float = 320 * 1.905 / 100
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
@export
var max_step_up : float = 18 * 1.905 / 100
@export
var crouch_speed_multiplier : float = 1.0 / 3.0
@export
var backwards_speed_multiplier : float = 0.9
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
var last_floored_frame : int = 0
var snapped_to_stairs_last_frame : bool = false
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
	setup_casts_step_check()

func _physics_process(delta: float) -> void:
	process_movement(delta)
#endregion

#region main movement processing stack
##Utter dogshit lol[br][br]
## [b][u]PURPOSE[/u][/b]:
## [br]This is very rudementary implementation of processing stack from source engine physics. In source it doesnt touch only entities but includes movemnts, calucations navigation and what not. PLEASE read through paper here for more information: https://www.dropbox.com/scl/fi/c0vxjztou9xj0of1zamer/Review.pdf?rlkey=rv9l35ze3uvhbk5llnwl1ld0k&e=1
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
		if is_on_floor() and (velocity * Vector3(1,0,1)).length() > max_ground_speed*1.1:
			clip_velocity(get_floor_normal())
		elif is_on_wall_only():
			clip_velocity(get_wall_normal())
		#step 9: move and slide?. Question mark here is due to me(gibbdev) being not 100% sure if this is correct place to plug default godot implementation of move_and_slide
		#It might be out of place due to Source 1 engine processing movement and physics kinda separate as Valve traces the player bounding box before editing the velocity
		if !step_up_check(delta):
			step_down_check()
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

## [b][u]PURPOSE[/u][/b]:
## [br]Checks if player is stuck right now check possible space to get unstuck at
func check_stuck() -> void:
	stuck_check_collider.position = Vector3(0, stuck_check_collider.shape.size.y / 2.0, 0)
	stuck_check_collider.force_update_transform()
	stuck_check_collider.force_shapecast_update()
	if stuck_check_collider.is_colliding():
		try_unstuck()
	else:
		is_stuck = false

## [b][u]PURPOSE[/u][/b]:
## [br]This method is run in [method Node._ready] and generates Array of unstuck offsets. This particular table is carbo copy from Team Fortress 2 source code. and yes maximum offsets are that small. idk why but here is Valve for you. They might be were too afraid to let player phase through thin walls (but looking at any% speedruns of half-life they kinda failed at that)
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

## [b][u]PURPOSE[/u][/b]:
## [br]Returns offset or, how valve named it, nudge off the list of possible offsets to try to put player into when stuck. see [method try_unstuck]
func get_unstuck_offset() -> Vector3:
	#get current offset
	var unstuck_offset : Vector3 = unstuck_offsets_table[unstuck_offsets_table_id % 53]
	#increment the id
	unstuck_offsets_table_id += 1
	#send it
	return unstuck_offset

## [b][u]PURPOSE[/u][/b]:
## [br] Iterate through [member unstuck_offsets_table] and move player to first valid spot. source engine doesnt look very far to consider player not stuck. In TF2 being stuck is sometimes beneficial (search HTwo on youtube and look at his stuck launch videos) thats why defaul godot unstuck behaviour will not be replaecated where body will be infinitely pushed away when colliding with solid geometry. Offset to nudge player is chosen once per frame meaning to iterate through the list [member unstuck_offsets_table_id] is used
#HACK:	Iterates every physics frame. If it becomes a problem with physics perfomance switch to iterating at intervals. Valve decided to iterate no sooner than 0.05 seconds from last iteration. Roughly every 4 physics frames at 66 pfps 
func try_unstuck() -> void:
	#become stuck
	is_stuck = true
	#get new offset from the list
	var unstuck_offset : Vector3 = get_unstuck_offset()
	#update colider check node
	stuck_check_collider.position = unstuck_offset + Vector3(0.0, stuck_check_collider.shape.size.y/2.0, 0.0)
	#force physics update
	stuck_check_collider.force_update_transform()
	stuck_check_collider.force_shapecast_update()
	if !stuck_check_collider.is_colliding():
		#move player to valid spot
		global_position += unstuck_offset
		#reset stuck state
		is_stuck = false
		#reset offsets id for next check
		unstuck_offsets_table_id = 0


#endregion

#region velocity checks
## [b][u]PURPOSE[/u][/b]:
## [br]Checks if player moving up way too fast to be grounded. Cus if body moving up faster than [member upward_velocity_threshhold] it will be considered airborne. This allows some actions to force player airborne if they exceed this threshold. good example is rampsliding. With enough horizontal speed moving into ramp, players velocity will be clipped to slope and this will result of them becoming airborne, sliding up the ramp and being launched off it. aka rampsliding. look up demoman trimping videos, they are awsome
func check_upward_velocity() -> void:
	if velocity.y >= upward_velocity_threshhold:
		is_airborne = true

## [b][u]PURPOSE[/u][/b]:
## [br]Determines if character should be considered grounded. Its more than just [method CharacterBody3D.is_on_floor]. This method also checks upward velocity against [member upward_velocity_threshhold]. See [method check_upward_velocity] 
func check_grounded() -> bool:
	#determine if grounded
	var state : bool = is_on_floor() and (velocity.y < upward_velocity_threshhold)
	#update states
	if state: 
		#refresh mid air jumps
		current_mid_air_jumps = maximum_mid_air_jumps
		#if grounded update last grounded frame for step up calculations
		last_floored_frame = Engine.get_physics_frames()
		#take fall damage
		#reset blast jumping state
	return state

## [b][u]PURPOSE[/u][/b]:
## [br]Caps velocity to [member maximum_velocity_cap]. This is a hard limit in source engine games and cannot be exceeded. No body can move faster than this for more than 1 frame
func limit_velocity() -> void:
	if velocity.length() > maximum_velocity_cap:
		velocity = velocity.normalized() * maximum_velocity_cap

#endregion

#region gravity

## [b][u]PURPOSE[/u][/b]:
## [br]Applies half of the gravity to player [CharacterBody3D]. Doing it in halves is to increase precision
func apply_half_gravity() -> void:
	velocity.y -= get_gravity_tick()

## [b][u]PURPOSE[/u][/b]:
## [br]Returns 1 tick of gravity used in calculations
func get_gravity_tick() -> float:
	#get gravity value from project settings
	var gravity : float = (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier)
	#get tickrate from project settings and divide it by current time scale
	var engine_tick_multiplier : float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 66) / Engine.time_scale
	#return half of gravity as we apply gravity in halves
	return gravity / engine_tick_multiplier / 2.0

#endregion

#region crouching

#---
# Writing this in full cause im going insane...
# Character crouching is way more complex in source engine as it actually takes time for character to crouch or uncrouch
# If player wishes to crouch there are several checks done.
#	Check for state from last frame: if player changed their mind since last frame
#	Check if player wishes to crouch or uncrouch
#	Check if player is fully crouched already or is in process of uncrouching or uncrouching
#	Check if player is on the ground
#	Check if collider, for space that player would occupy by uncrouching, is colliding
#	Depending on checks there would be different outcomes and not only binary crouched/incrouched (I wish lmao)
#--- GibbDev 12AUG2025

## [b][u]PURPOSE[/u][/b]:
## [br]decodes player intention to uncrouch depending on player state
func handle_crouch() -> void:
	#check if player wants to uncrouch and ask engine to uncrouch as soon as possible
	if !wish_crouch and (is_crouched or is_crouching_animation): queue_uncrouch = true
	if queue_uncrouch:
		try_uncrouch()
		return
	#TODO: change state check to input gathering script
	#if state didnt change from last frame -> return
	if (wish_crouch == wish_crouch_last_frame): return
	#update state from last frame
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
				$CameraAnchor.position.y = 68 * 1.905 / 100
			return
		elif is_crouched:
			queue_uncrouch = true
			try_uncrouch()
			return

## [b][u]PURPOSE[/u][/b]:
## [br]Finalizes player crouching down
func crouch() -> void:
	#stop timers and update states
	crouch_timer.stop()
	uncrouch_timer.stop()
	is_crouching_animation = false
	is_uncrouching_animation = false
	is_crouched = true
	#update world collision hull
	wish_hull_size = crouch_hull_size
	update_hull()
	#affirm camera in new position in case it was bypassed 
	$CameraAnchor.position.y = 45 * 1.905 / 100

## [b][u]PURPOSE[/u][/b]:
## [br]Finalizes player uncrouching
func uncrouch() -> void:
	#reset need to uncrouch
	queue_uncrouch = false
	#stop timers and update states
	crouch_timer.stop()
	uncrouch_timer.stop()
	is_crouching_animation = false
	is_uncrouching_animation = false
	is_crouched = false
	#update world collision hull
	wish_hull_size = standart_hull_size
	update_hull()
	#affirm camera in new position in case it was bypassed 
	$CameraAnchor.position.y = 68 * 1.905 / 100

## [b][u]PURPOSE[/u][/b]:
## [br]Starts delayed crouch and shifts player camera down
func start_delayed_crouch() -> void:
	#if already crouching do nothing
	if is_crouching_animation: return
	#stop uncrouching
	is_uncrouching_animation = false
	uncrouch_timer.stop()
	#start crouching
	is_crouching_animation = true
	crouch_timer.start()
	#save camera for smooth transition
	$CameraAnchor.save_start_smoothing_position()
	#update camera position
	$CameraAnchor.position.y = 45 * 1.905 / 100

## [b][u]PURPOSE[/u][/b]:
## [br]Starts delayed uncrouch and shifts player camera up
func start_delayed_uncrouch() -> void:
	#if already uncrouching do nothing
	if is_uncrouching_animation: return
	#stop crouching
	is_crouching_animation = false
	crouch_timer.stop()
	#start uncrouching
	is_uncrouching_animation = true
	uncrouch_timer.start()
	#save camera for smooth transition
	$CameraAnchor.save_start_smoothing_position()
	#update camera position
	$CameraAnchor.position.y = 68 * 1.905 / 100

## [b][u]PURPOSE[/u][/b]:
## [br]Handles if player can successfully uncrouch. Main concern is if there is enough space to uncrouch. This is NOT how it is in team fortress 2, cus frankly in tf2 its complete bs.
## Game checks if player has enough space to uncrouch above collision hull. No matter the state. Meaning that player will be forced to remain crouched if player is too close to ceiling despite having space to uncrouch below them.
## In this interpretation of the movement player can uncrouch in air if there is enough space below them. If not then engine checks if there is enough space to uncrouch up
func try_uncrouch() -> void:
	#if grounded perform check to start uncrouching on the ground
	if is_on_floor():
		#update position of crouch_check_collider node. This positioned above player collision hull
		crouch_check_collider.position = Vector3(0, crouch_hull_size.y + ((standart_hull_size.y - crouch_hull_size.y) / 2.0), 0)
		#force an update to transforms
		crouch_check_collider.force_update_transform()
		#force collision detection
		crouch_check_collider.force_shapecast_update()
		#if there is no colliders start uncrouching
		if !crouch_check_collider.is_colliding(): start_delayed_uncrouch()
	#if not grounded try to 
	else:
		#update position of crouch_check_collider node. This positioned below player collision hull
		crouch_check_collider.position = Vector3(0, (standart_hull_size.y - crouch_hull_size.y) / -2.0, 0)
		#force an update to transforms
		crouch_check_collider.force_update_transform()
		#force collision detection
		crouch_check_collider.force_shapecast_update()
		#if there is no colliders uncrouch in air down
		if !crouch_check_collider.is_colliding():
			position.y -= standart_hull_size.y - crouch_hull_size.y
			uncrouch()

#endregion

#region jumping

## [b][u]PURPOSE[/u][/b]:
## [br]Hadles player intent to jump
func handle_jump() -> void:
	#check if airborne
	if !is_on_floor(): pass #TODO: make mid air jumping
	elif wish_jump and !is_crouched:
		#if player is crouching down perform a crouch jump.
		if is_crouching_animation: crouch_jump()
		#if player is uncrouching perform a ctap bug. 
		elif is_uncrouching_animation: ctap()
		#if no crouching interaction perform a regular jump
		else: velocity.y += jump_strength - get_gravity_tick()
		#if bhopping not a thing apply ground friction to horizontal movement
		if !is_bhop_bug_enabled:
			#TODO: add one tick of friction here
			pass
		#limit horizontal speed to jump_speed_cap. Almost immediate fix from valve in early cycle of team fortress 2 life.
		if limit_bhop_speed:
			#get horizontal velocity
			var horizontal_velocity : Vector2 = Vector2(velocity.x, velocity.z)
			#get horizontal speed of player
			var speed : float = horizontal_velocity.length()
			#if speed exceeds limit cap it to that limit
			if speed > maximum_walking_speed_base * max_ground_speed_multiplier * jump_speed_cap:
				#get new horizontal velocity
				horizontal_velocity = horizontal_velocity.normalized() * maximum_walking_speed_base * max_ground_speed_multiplier * jump_speed_cap
				#update player velocity
				velocity = Vector3(horizontal_velocity.x, velocity.y, horizontal_velocity.y)
		#make player airborne immediately and not in main stack where vertical velocity might be voided
		is_airborne = true
	#if auto jumping is disabled void player intent on jumping to prevent input buffering 
	if !is_auto_jump_enabled: wish_jump = false

## [b][u]PURPOSE[/u][/b]:
## [br]Forces player into jump crourching position. If [member is_crouch_jump_bug_enabled] is disabled shift player up same way as crouching while airborne, if not player jump force doesnt account for 1 tick of gravity. In TF2 it amounts to two hammer units difference in jump height
func crouch_jump() -> void: #invokled from jumping handle
	crouch()
	if is_crouch_jump_bug_enabled:
		velocity.y = jump_strength
	else:
		velocity.y = jump_strength - get_gravity_tick()
	position.y += standart_hull_size.y - crouch_hull_size.y

## [b][u]PURPOSE[/u][/b]:
## [br]Forces player into jump crourching position. If [member is_ctap_bug_enabled] is disabled shift player up same way as crouching while airborne
## [color=#7e7e7e][b][u]NOTE[/u][/b]:
## CTap or crouch tapping is a technique used in Team Fortress 2 that allows for player be considered crouched, airborne and as close to ground as possible to gain as much velocity from explosive knockback as possible
func ctap() -> void:
	crouch()
	velocity.y = jump_strength - get_gravity_tick()
	#if not bugged shift upwards.
	if !is_ctap_bug_enabled: position.y += standart_hull_size.y - crouch_hull_size.y

#endregion

#region acceleration

## [b][u]PURPOSE[/u][/b]:
## [br]Slows down [member velocity] when [CharacterBody3D] is considered grounded (see [method check_grounded])
## [b][u]PARAMETERS[/u][/b]:
## [br] delta - delta time of last physics frame
func apply_friction(delta: float) -> void:
	var speed : float = velocity.length() #Speed of player movement
	var friction : float = 1.0 #friction amount
	var control : float = 0.0 #control speed threshold
	#stop infinitelly slow movements
	if speed < (0.1 * 1.905 / 100.0):
		velocity = Vector3.ZERO
		return
	#apply ground friction
	if !is_airborne:
		friction = server_variable_friction * surface_friction
	#Bleed off some speed, but if we have less than the bleed threshold, bleed the threshold amount.
	if (speed < server_variable_stop_speed):
		control = server_variable_stop_speed
	else:
		control = speed
	#speed that needs to be dropped due to friction
	var drop : float = control * friction * delta
	#new speed after friction calculations
	var new_speed : float = max(0.0, speed - drop)
	#determine the proportion of new speed to old speed
	if new_speed != speed:
		new_speed /= speed
		velocity *= new_speed
	velocity -= (1.0-new_speed) * velocity

## [b][u]PURPOSE[/u][/b]:
## [br]Determines what type of acceleration to use
## [b][u]PARAMETERS[/u][/b]:
## [br] delta - delta time of last physics frame
func accelerate(delta: float) -> void:
	#upadte wish_direction
	get_view_rotations()
	#TODO: implement water acceleration
	wish_direction = get_wish_direction()
	if is_airborne: air_move(delta)
	else: ground_move(delta)

## [b][u]PURPOSE[/u][/b]:
## [br]Clips and aligns [member velocity] to surface 
## [b][u]PARAMETERS[/u][/b]:
## [br] surface_normal - normal of the face to align the velocity to
## [br] overbounce - [color=gold]NULLABLE[/color] - multiplier of surface pushback
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

## [b][u]PURPOSE[/u][/b]:
## [br]Changes [member velocity] when [CharacterBody3D] is considered airborne (see [method check_grounded])
## [b][u]PARAMETERS[/u][/b]:
## [br] delta - delta time of last physics frame
func air_move(delta: float) -> void:
	#rotated wish_direction by view rotation and normalized
	var dir : Vector3 = Vector3(wish_direction.x, 0, wish_direction.y).rotated(Vector3.UP, get_view_rotations().y).normalized()
	#this is a wrong way to get current speed but... its where magic happens ( ͡° ͜ʖ ͡°)
	var current_speed : float = velocity.dot(dir)
	#determine how much speed we want to add
	var add_speed : float = max_air_speed - current_speed
	#if speed is negative do nothing
	if add_speed <= 0: return
	#apply acceleration
	var accel_speed : float = delta * server_variable_air_acceleration * min(server_variable_max_speed, max_ground_speed)
	#cap accel_speed by add_speed
	accel_speed = min(accel_speed, add_speed)
	#update velocity
	velocity += accel_speed * dir

## [b][u]PURPOSE[/u][/b]:
## [br]Changes [member velocity] when [CharacterBody3D] is considered grounded (see [method check_grounded])
## [b][u]PARAMETERS[/u][/b]:
## [br] delta - delta time of last physics frame
func ground_move(delta: float) -> void:
	#rotated wish_direction by view rotation and normalized
	var dir : Vector3 = Vector3(wish_direction.x, 0, wish_direction.y).rotated(Vector3.UP, get_view_rotations().y).normalized()
	#this is a wrong way to get current speed but... its where magic happens ( ͡° ͜ʖ ͡°)
	var current_speed : float = velocity.dot(dir)
	#get speed multiplier
	max_ground_speed_multiplier = get_speed_multiplier()
	#determine how much speed we want to add
	var add_speed : float = clamp(ground_acceleration * max_ground_speed * delta, 0, max_ground_speed * max_ground_speed_multiplier - current_speed)
	#update velocity
	velocity += dir * add_speed

## [b][u]PURPOSE[/u][/b]:
## [br]Returns [Vector2] of keyboard input. TODO: change to hook from input gatheirng class.[br]
## [color=#ff7070]left is -x, right is +x[/color], [color=#7070ff]forward is -y, back is +y[/color]
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
	# if null movement isnt enabled jsut use simple integer math to determine direction
	else:
		wish_direction = Input.get_vector( "left", "right", "forward", "back")
	return wish_direction

## [b][u]PURPOSE[/u][/b]:
## [br]Returns [PackedVector3Array] containing [param forward], [param up] and [param right] direction vectors from [GodsourceCameraAnchor3D][br]
## [color=#7e7e7e][b][u]NOTE[/u][/b]:
## [br]Currently unused. Implemented just in case someone needs direction vector instead of rotating basis vectors by camera rotations[/color][br]
func get_view_angles() -> PackedVector3Array:
	var angles_array : PackedVector3Array
	angles_array.append($CameraAnchor.forward)
	angles_array.append($CameraAnchor.up)
	angles_array.append($CameraAnchor.right)
	return angles_array

## [b][u]PURPOSE[/u][/b]:
## [br]Returns [Vector3] containing [param pitch], [param yaw] and [param roll] from [GodsourceCameraAnchor3D]
func get_view_rotations() -> Vector3:
	return Vector3($CameraAnchor.pitch, $CameraAnchor.yaw, $CameraAnchor.roll)

## [b][u]PURPOSE[/u][/b]:
## [br]Returns multiplier of speed based on bunch of parameters. Crouching, status effects and so on
func get_speed_multiplier() -> float:
	var mult : float = 1.0
	if is_crouched:
		mult *= crouch_speed_multiplier
	if !is_crouched and wish_direction == Vector2(0, 1.0):
		mult *= backwards_speed_multiplier
	return mult
#endregion acceleration

#region collision hull editing
## [b][u]PURPOSE[/u][/b]:
## [br]Updates player [CollisionShape3D] hull shape size. Sets hull and [member stuck_check_collider] position to the center of parent node and raised to half of the vertical size.[br]
## [b][u]PARAMETERS[/u][/b]:
## [br][param new_size] - If provided sets dimensions of the collision hull to new_size. If not - set size to [member wish_hull_size]
func update_hull(new_size : Vector3 = wish_hull_size) -> void:
	if collision_hull.shape.size == new_size: return			#/if hull shape is already of new_size -> return.
																#\might cause possible descrepancy between hull shape and stuck_check_collider. If this is the case Ill go back and fix it
	collision_hull.position = Vector3(0.0, new_size.y/2.0, 0.0) # set new position of the hull
	collision_hull.shape.size = new_size 						# set new shape size
	stuck_check_collider.position = collision_hull.position 	# copy hull position
	stuck_check_collider.shape = collision_hull.shape 			# copy hull shape

#endregion collision hull editing

#region step up logic

# In general its good if game can get by without step up or down. Its all tested over the years
# and turns our sidden elevation changes and movement shooters do not mix well. use ramps instead where possible
# But without step up and down logic player will stub their toes on the smallest edges possible and get stopped. No bueno

## [b][u]PURPOSE[/u][/b]:
## [br] Method executed in [method _ready]. Sets up transforms of step up raycast and stepdown shapecast
func setup_casts_step_check() -> void:
	# making step down ShapeCast3D same size as player hull and height of max step up length
	$step_down_shape_cast.shape.size = Vector3(standart_hull_size.x, max_step_up + 0.1, standart_hull_size.z)

	# positioning step down ShapeCast3D at the bottom of player hull
	$step_down_shape_cast.position = Vector3(0, (max_step_up + 0.1)/ -2 - 0.01, 0)

	# making step up RayCast3d length be max step up length
	$step_up_ray_cast.target_position.y = -(max_step_up + 0.1)

## [b][u]PURPOSE[/u][/b]:[br] Checks if wall is at walkable angle to be able to step up onto it[br]
## [b][u]PARAMETERS[/u][/b]:[br] surface_normal - [Vector3] - normal of the wall
## [b][u]RETURN[/u][/b]:
## [br]returns true if surface is unwalkable
func is_wall_too_steep(surface_normal: Vector3) -> bool:
	# testing if surface angle is more than max walkable surface angle
	return surface_normal.angle_to(Vector3.UP) > floor_max_angle

## [b][u]PURPOSE[/u][/b]:
## [br] Perfoms a test motion of [CharacterBody3D] with [method PhysicsServer3D.body_test_motion][br]
## [b][u]PARAMETERS[/u][/b]:
## [br] from - original body transform
## [br] motion - test motion destination
## [br] result - [color=gold]NULLABLE[/color] - Describes the motion and collision result. If result is provided you can use it to get details about the collision test. See [PhysicsTestMotionResult3D][br]
## [b][u]RETURN[/u][/b]: [br]returns if motion was successful
func test_motion(from: Transform3D, motion: Vector3, result: PhysicsTestMotionResult3D = null) -> bool:
	# if result is null, instance new one
	if !result: result = PhysicsTestMotionResult3D.new()
	# instance new physics motion parameters
	var parameters: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
	# define motion in parameters
	parameters.from = from
	parameters.motion = motion
	# test and return motion
	return PhysicsServer3D.body_test_motion(get_rid(), parameters , result)

## [b][u]PURPOSE[/u][/b]:
## [br] Snaps player to ground upon walking off ledges shorter than max step up length to avoid slipping off stairs or setting player airborne for no reason
func step_down_check() -> void:
	# reset state of stepping down
	var stepped_down: bool = false
	# determine if player was on floor in last frame or current frame
	var was_on_floor_last_frame: bool = (Engine.get_physics_frames() - last_floored_frame <= 2)
	# see if ground below is close enough
	var is_ground_below: bool = ($step_down_shape_cast.is_colliding())
	# if airborne and was grounded last frame and intending to jump: true -> step down , false -> update last frame grounded
	if is_airborne and (stepped_down or was_on_floor_last_frame) and !wish_jump and velocity.y <= 0:
		# create new physics server test object
		var motion_test_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		# ask physics server testmotion if player can conplete step down movement and if there is ground to step down to
		if test_motion(global_transform, Vector3(0, -max_step_up - 0.01, 0), motion_test_result) and is_ground_below:
			# call camera smoothing method from [PlayerCameraComponent]
			$CameraAnchor.save_start_smoothing_position()
			# get travel distance from motion test
			var translate_y: float = motion_test_result.get_travel().y
			# tp player down
			position.y += translate_y
			# align player to floor, just in case
			apply_floor_snap()
			# stepdown success
			stepped_down = true
	# Update if player was snapped to ground with state of the method
	snapped_to_stairs_last_frame = stepped_down

## [b][u]PURPOSE[/u][/b]:
## [br] Moves player up if ledge height less than [member max_step_up].
## [br][b][color=gold]!!IMPORTANT!! THIS METHOD MOVES PLAYER! EXECUTING [method CharacterBody3D.move_and_slide] WILL RESULT IN ERRONIOUS DOUBLING OF MOVEMENT![/color][br]
## [b][u]PARAMETERS[/u][/b]:
## [br] delta - delta time of last physics frame
## [b][u]RETURN[/u][/b]:
## [br] returns if step up was successful. Use this return to prevent double movent with [method CharacterBody3D.move_and_slide]
func step_up_check(delta: float) -> bool:
	# If player is not grounded and wasnt snapped to floor: return false
	if !is_on_floor() and !snapped_to_stairs_last_frame: return false
	# If moving up or not moving horizontally: return false
	if velocity.y > 0 or (velocity * Vector3(1, 0, 1)).length() == 0: return false
	# Project next motion using delta and current velocity
	var expected_motion: Vector3 = velocity * Vector3(1, 0, 1) * delta
	# Predict next motion with step up in mind
	var step_pos_with_clearance: Transform3D = global_transform.translated(expected_motion + Vector3(0, max_step_up * 2, 0))
	# Create new physics collision check result instance
	var down_check_result: KinematicCollision3D = KinematicCollision3D.new()
	# Test if player can fit in desegnated place
	if test_move(step_pos_with_clearance, Vector3(0, -max_step_up * 2 ,0), down_check_result):
		# Determine travel distance
		var step_height: float = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - global_position).y - 0.001
		# If travel distance is invalid: return false
		if step_height > max_step_up or (down_check_result.get_position() - global_position).y > max_step_up: return false
		# Move raycast to the predicted motion destination
		$step_up_ray_cast.global_position = down_check_result.get_position() + Vector3(0, max_step_up, 0)
		# Force raycast update
		$step_up_ray_cast.force_raycast_update()
		# Check if step up spot is valid
		if not is_wall_too_steep($step_up_ray_cast.get_collision_normal()):
			# Call camera smoothing method from CamearAnchor node
			$CameraAnchor.save_start_smoothing_position()
			# Move player up the ledge
			global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			# Align with the floor
			apply_floor_snap()
			# Update snapped_to_stairs_last_frame state to be considered grounded for next frame calculations
			snapped_to_stairs_last_frame = true
			# On success send true which will cancel out move_and_slide
			return true
	# In case of fail just pass the method
	return false

#endregion step up logic
