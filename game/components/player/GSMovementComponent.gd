## [b][color=gold]!!! IMPORTANT !!![/color] - This component requires to be a child of [CharacterBody3D] to function properly[b][br][br]
## This component listens to user inputs to move parent node in 3D space. All default values aren an example implementation and are converted from TF2 and correspond to default movement of Soldier
class_name PlayerGSMvtComp
extends Node3D


#region node references

## [CharacterBody3D] parent.
@export var player_root: CharacterBody3D

## Player bounding box. Collides with "WORLD" collision layer and does not rotate
@export var bounding_box: CollisionShape3D

## Reference to camera component
@export var camera_component: Node3D
#endregion


#region Variables
## TODO-IMPORTANT: MOVE MOST OF THE VARIABLES THAT ARE CONSIDERED CLASS SPECIFIC TO PLAYER SCRIPT AND CREATE METHODS FOR SET/GET THEM
## [value] * 1.905 / 100 <- Closest conversion from hammer units to meters. "Hammer Unit" is Source Engine's distance measuring unit
@export_category("Acceleration Variables")


## Gravitational acceleration.[br][br]Gravity is applied each physics frame(unless grounded) in two parts to improve precision and mitigate difference caused by perfomance problems
@export var gravity: float = 800 * 1.905 / 100

## Impulse that given to player upon jumping.
@export var jump_power: float = 289 * 1.905 / 100


@export_subgroup("Grounded Movement")


## Maximum speed while grounded. Default value is 240 HU/s which is TF2 Soldier's speed
@export var ground_max_speed: float = 240.0 * 1.905 / 100

## How fast player gains speed while grounded. Default value is just ten times bigger than ground_max_speed
@export var ground_acceleration: float = 2400.0 * 1.905 / 100

## How fast player looses speed while grounded. Default value is 400 HU/s
@export var ground_friction: float = 400 * 1.905 / 100

## Any speed less than that value gets clipped. Player stops if moves slower than this value while on ground. Makes precise movements a bit more responsive
@export var grounds_speed_cut_off: float = 100 * 1.905 / 100

## Maximum velocity cap. If [i]limit_max_velocity[/i] is set to [i][color=lime]true[/color][/i] this will make so player velocity limited to their ground_max_speed * limit_max_velocity_amount
@export_range(1.0, 2.0, 0.01, "or_greater") var limit_max_velocity_amount: float = 1.2

## Detrmines maximum step up/down height
@export var max_step_up: float = 0.35


@export_subgroup("Airborne Movement")

@export var air_max_speed: float = 30.0 * 1.905 / 100 #Maximum speed player can get without air strafing. Default value is 30 HU/s

#Determines how fast player needs to move upward to be considered airborne
@export var upward_velocity_gate: float = 250 * 1.905 /100


@export_subgroup("Movement flags")


## Determines if player inputsare interpreted as "Null Movement"[br][color=#00000080][i]Null movement is type of movemnt interpretation where movement keys apply immediately and not on Basis summ of Rght - Left. That makes so if left key is pressed down and then right key is pressed movement direction is overriden to "move right"
@export var use_null_movement: bool = true

## Enable and disable automatic BHopping. 
@export var bhop_cheat_enabled: bool = false

## Limit Max velocity upon landing. This is to nerf bunnyhopping to stop players from achieveing speeds above limit_max_velocity_amount values.
@export var limit_max_velocity: bool = true

## Variable that shows if player was snapped to floor due to step up/step down last frame
var snapped_to_stairs_last_frame: bool = false

## Variable of last physics frame when player was on floor to not apply floor snap more than needed
var last_floored: int = 0

## Is this Player grounded state. If TRUE player is grounded
var grounded: bool = false

var wish_right: bool = false
var wish_left: bool = false
var wish_forward: bool = false
var wish_backward: bool = false
var wish_jump: bool = false
var wish_crouch: bool = false
var wish_swim_up: bool = false

var old_wish_jump : bool = false

var previous_inputs: Dictionary = {
	"R": wish_right,
	"L": wish_left,
	"F": wish_forward,
	"B": wish_backward}

## Wish Dir - player directional inputs mapped to vec2
var wish_direction: Vector3 = Vector3.ZERO

var move_type: GSPlayerState.MOVE_TYPE = GSPlayerState.MOVE_TYPE.WALK

## Stacked knockback is Vec3 impulse given to player from knockback sources that is applied at projectile processing step and then set to 0 
var stacked_knockback: Vector3 = Vector3.ZERO
## Timer during which water jumping movement execuites
var water_jump_time : float = 0
## if player is in jumping out of water state
var state_water_jumping : bool = false
## jump power that player gains when jumping out of water
var water_jump_power: float = 400.0 * 1.905 / 100
## Code variable that dictates velocity that player will move with during jumping out of water
var water_jump_wish_velocity : Vector3 = Vector3.ZERO

@export_subgroup("Knockback variables")

## General multiplier of knockback. each class in TF2 has their kncockback mult. Soldier while grounded has 5.0, while airborne 10.0, demoman has 9.0
@export var knockback_multiplier: float = 5.0

## Multiplier of knockback force.[br][color=#777][i]In source engine it is reffered as mass, despite being ratio to volume of bounding box while stanfing. And even then in tf2 it should be NOT 0.67 cause bounding box height got changed since release(from 55 hammer units to 62 hammer units high) but knockback mult kept as original to not mess up with mapping and knockback(explosive jumping in particular).  [color=#4040ff][url=https://www.dropbox.com/scl/fi/c0vxjztou9xj0of1zamer/Review.pdf?rlkey=rv9l35ze3uvhbk5llnwl1ld0k&e=2&dl=0]this document[/url][/color], Page 13 Section 6 Projectiles and Knockback by [color=#4040ff][url=https://steamcommunity.com/id/ildprut]Ildprut[/url][/color]
@export var crouched_knockback_multiplier: float = 0.67

## Multiplier of knockback while airborne
@export var airborne_knockback_multiplier: float = 10.0

## Damage resistance from self damage while explosive jumping. In TF2 explosions deal reduced self damage(If no enemies caught in the blast. Otherwise it deals full self damage). Soldier has 0.6 mult when airborne, 1.0 mult when NOT IN AIR(not in air makes way for super jumps from water. that way player takes most self damge which translates to most amount of knockback). Demoman has 75% no matter the state
@export var self_blast_damage_reduction: float = 1.0

## Damage resistance from self damage while explosive jumping while airborne.
@export var self_blast_damage_reduction_air: float = 0.6

var just_jumped: bool = false


@export_subgroup("Crouching")


## How long it takes for player to coruch or ucrouch
@export var crouching_animation_time: float = 0.15

## How much ground movement sopeed is multiplied when crouching
@export var crouch_speed_multiplier: float = 0.3

## Bounding box height crouched
@export var bounding_box_height_crouched: float = 1.2

## Enable TF2 bug that allows to jump, crouch in air and avoid upwards shift. If false player can jump as high as regular jump[br][color=#777][i]This bug stems from erronious behaviour. Regularly player should be shifted upwards when crouching in air. Since player havent finished uncrouching animation player then forced to stay crouched until space below player allows for uncrouching. That allows for closer to ground player origin calculation and explosions send player much highier. Better explanation by Shounic [color=#03b][url=https://www.youtube.com/watch?v=76HDJIWfVy4]here[/url]
@export var crouch_jump_bug: bool = true

## Enable or disable bug from source engine that allows to crouch and shrink hitbox right on ground and bypass upwards shift to allows to get maximum blast foprce from explosive jumping
@export var ctap_enabled: bool = true

## State variable to show that player is in crouching down animation
var crouching: bool = false

## State variable to show that player is in uncrouching animation
var uncrouching: bool = false

## State variable that shows that player is crouched
var crouched: bool = false

## state variable that shows that player should be uncrouched as soon as world geometry allows it 
var queue_uncrouching: bool = false

## Uncrouch Timer node reference
@onready var uncrouch_timer: Timer = $uncrouching

## Crouch Timer node reference
@onready var crouch_imer: Timer = $crouching

## Reference to the shpaecast node that checks if uncrouching on ground is blocked
@onready var uncrouch_check_top: ShapeCast3D = $uncrouch_cast_top

## Reference to the shpaecast node that checks if uncrouching in air is blocked
@onready var uncrouch_check_bottom: ShapeCast3D = $uncrouch_cast_bottom

@onready var step_down_shape_cast: ShapeCast3D = $step_down_shape_cast

@onready var step_up_ray_cast: RayCast3D = $step_up_ray_cast

## Gets Vec3 size of player bounding box
@onready var bounding_box_size: Vector3 = bounding_box.shape.size

#State variable that shows that player was snapped to groun in last frame, aka should be grounded
var crouching_state_last_frame: bool = false

var in_water: bool = false
var can_swim: bool = (true)

var swimming_mastery: bool = false # This variable defined by valve but never used. If true 20% slowdown in water isnt applied
#endregion


#region built-in functions
func _ready() -> void:
	setup_crouching()
	setup_casts_step_check()
	
func _unhandled_input(_event: InputEvent) -> void:
	wish_right = Input.is_action_pressed("right")
	wish_left = Input.is_action_pressed("left")
	wish_forward = Input.is_action_pressed("forward")
	wish_backward = Input.is_action_pressed("back")
	wish_crouch = Input.is_action_pressed("crouch")
	wish_jump = Input.is_action_pressed("jump")

	if Input.is_key_pressed(KEY_F1):
		Engine.time_scale = 0.1

	if Input.is_key_pressed(KEY_F2):
		Engine.time_scale = 1.0
		
	if Input.is_action_just_pressed("noclip"):
		toggle_noclip()

func _physics_process(delta: float) -> void:
	#TODO: Move to hud component later.
	var text_comp: String = "Velocity: [color=#f00]x: " + str(snapped(player_root.get_velocity().x * 100 / 1.905, .01)) + " [color=#0f0]y: " + str(snapped(player_root.get_velocity().y * 100 / 1.905, .01)) + " [color=#00f]z: " + str(snapped(player_root.get_velocity().z * 100 / 1.905, .01)) + "[color=#fff] -- Speed: " + str(snapped(player_root.get_velocity().length() * 100 / 1.905, .01)) + " HU/s"
	text_comp += "\nPosition: [color=#f00]x: " + str(snapped(player_root.global_position.x / 1.905 * 100, 0.01)) + " [color=#0f0]y: " + str(snapped(player_root.global_position.y / 1.905 * 100, 0.01)) + " [color=#00f]z: " + str(-snapped(player_root.global_position.z / 1.905 * 100, 0.01)) + "[color=#fff]"
	text_comp += "\nAngle: [color=#f00]x: " + str(-snapped(rad_to_deg(camera_component.get_camera_rotation().x), 0.01)) + " [color=#0f0]y: " + str(snapped(fmod((rad_to_deg(camera_component.get_camera_rotation().y) + 270), 360.0) - 180.0, 0.01)) + " [color=#00f]z: " + str(snapped(rad_to_deg(camera_component.get_camera_rotation().z), 0.01)) + "[color=#fff]"
	text_comp += "\nWater jumping: " + str(state_water_jumping) + " - time: " + str(water_jump_time)
	%showpos.text = text_comp

	process_movement(delta)

	update_old_keys()
#endregion

#region input

func update_old_keys() -> void:
	old_wish_jump = wish_jump
#endregion

#region Main movement processor
## PURPOSE: combines all other movement altering methods and overwrites velocity of a parent. Follows Source Engine like physics frame update order.[br]
## To see full frame order look into [color=#4040ff][url=https://www.dropbox.com/scl/fi/c0vxjztou9xj0of1zamer/Review.pdf?rlkey=rv9l35ze3uvhbk5llnwl1ld0k&e=2&dl=0]this document[/url][/color], Page 5 Section 2.2.2 Player tick by [color=#4040ff][url=https://steamcommunity.com/id/ildprut]Ildprut[/url][/color] 
func process_movement(delta: float) -> void:
	# step 0: get current velocity
	var new_velocity : Vector3 = player_root.get_velocity()

	if move_type != GSPlayerState.MOVE_TYPE.NOCLIP:
		# step 1: become airborne if moving up too fast
		if new_velocity.y >= upward_velocity_gate: grounded = false

		# step 2: Handle crouching
		handle_crouching()

		# step 3: Apply first half of gravity
		if !grounded and move_type != GSPlayerState.MOVE_TYPE.SWIM:
			new_velocity.y -= gravity / 2 * delta

		# step 4: handle Jumping
		if move_type != GSPlayerState.MOVE_TYPE.SWIM:
			new_velocity = handle_jump(new_velocity)

		# step 5: Limit max velocity. This was implemented in TF2 to heavily nerf BunnyHopping. Max velocity is limited to 120% of ground_max_speed
		if grounded and limit_max_velocity:
			if (new_velocity * Vector3(1,0,1)).length() > ground_max_speed * limit_max_velocity_amount:
				new_velocity = ((new_velocity * Vector3(1,0,1)).normalized() * ground_max_speed * limit_max_velocity_amount) + Vector3(0,new_velocity.y,0)

		# step 6: if grounded - apply friction and set vertical velocity to 0
		if grounded and !just_jumped and move_type != GSPlayerState.MOVE_TYPE.SWIM:
			new_velocity = apply_friction(new_velocity, delta)
			new_velocity.y = 0.0

	# step 7: apply acceleration
	new_velocity = apply_acceleration(new_velocity, delta)

	if move_type != GSPlayerState.MOVE_TYPE.NOCLIP:
		# step 8: Move and collide
		if player_root.is_on_wall():
			new_velocity = clip_velocity(new_velocity,player_root.get_wall_normal())
		if player_root.is_on_floor() and new_velocity.length() > (ground_max_speed + 0.01):
			new_velocity = clip_velocity(new_velocity,player_root.get_floor_normal())

		# step 9: Check for ground to stand on.
		grounded = check_grounded(new_velocity)

		# step 10: Apply second half of gravity 
		if !grounded and move_type != GSPlayerState.MOVE_TYPE.SWIM:
			new_velocity.y -= gravity / 2 * delta

		# step 11: Check grounded and if so set vertical velocity to 0
		if grounded and !just_jumped and move_type != GSPlayerState.MOVE_TYPE.SWIM:
			new_velocity.y = 0.0

		# step 12: Limit max velocity. Implemented to nerf bunny hopping in a week since TF2s release.
		# Some games may benefit from bunny hopping but when heavy comes up to you with mach 5 speed, reved up and balsting your ass in 1 second... Nah...
		if grounded and limit_max_velocity and move_type != GSPlayerState.MOVE_TYPE.SWIM:
			if (new_velocity * Vector3(1,0,1)).length() > ground_max_speed * limit_max_velocity_amount:
				new_velocity = ((new_velocity * Vector3(1,0,1)).normalized() * ground_max_speed * limit_max_velocity_amount) + Vector3(0,new_velocity.y,0)

		# step 13.1 Move and slide player here instead of source engine table
		if stacked_knockback != Vector3.ZERO:
			water_jump_time = 0.0 #stop water jumping horizontal movement upon recieving knockback
		new_velocity += stacked_knockback

	stacked_knockback = Vector3.ZERO

	player_root.velocity = new_velocity

	if move_type == GSPlayerState.MOVE_TYPE.NOCLIP:
		player_root.move_and_slide()

	elif move_type != GSPlayerState.MOVE_TYPE.NOCLIP:
		if !step_up_check(delta, new_velocity):
			step_down_check()
			player_root.move_and_slide()

	just_jumped = false
	
	# TODO
	# step 13.2: Handle triggers collision - If hame has invisible triggers(like doors opening in tf2 this step is for checking the collision shapes with areas3D)
	# step 14: Update bounding box- !NOT NEEDED FOR ANYTHING ELSE BUT SERVER CLIENT STRUCTURE! 
	# step 15: Handle projectiles


#endregion

#region grounded check
## PURPOSE: Update player grounded state. If player is on floor and not moving up too fast function returns True
func check_grounded(velocity: Vector3) -> bool:
	var state: bool = ((player_root.is_on_floor()) and (velocity.y <= upward_velocity_gate)) or snapped_to_stairs_last_frame
	if state:
		last_floored = Engine.get_physics_frames()
		water_jump_time = 0
		state_water_jumping = false
	return state
#endregion

#region friction
## PURPOSE: returns velocity affected by ground friction
func apply_friction(velocity: Vector3, delta: float) -> Vector3:
	#if water_move:
		#return

	var speed: float = velocity.length()
	var drop: float = 0
	
	if speed < 0.001905:
		return Vector3.ZERO
		
	if speed != 0.0:
		var control: float = max(grounds_speed_cut_off, speed)
		drop = control * 4 * 0.8 * delta

	var new_speed: float = speed - drop
	
	if new_speed < 0:
		new_speed = 0

	if new_speed != speed:
		new_speed /= speed 
		velocity *= new_speed

	velocity -= (1.0 - new_speed) * velocity

	return velocity 
#endregion


#region acceleration
## PURPOSE: return modified velocity after accelerating
func apply_acceleration(velocity: Vector3, delta: float) -> Vector3:
	get_wish_dir()
	if velocity.y < 0:
		water_jump_time = 0
		state_water_jumping = false
	velocity = water_jump(velocity, delta)
	# get how deep player is in water
	if move_type == GSPlayerState.MOVE_TYPE.NOCLIP:
		velocity = noclip_move(velocity)
		return velocity

	if get_water_level() > 1:
		velocity = full_water_move(velocity, delta)
		return velocity

	if grounded:
		velocity = accelerate_ground(velocity, delta)
	else:
		velocity = air_move(velocity, delta)
	return velocity
#endregion

#region ground movement
## PURPOSE: interprets user input
func get_wish_dir() -> void:
	if player_root.ui_focused: 
		wish_direction = Vector3.ZERO
		return

	if !use_null_movement:
		wish_direction = Vector3(int(wish_forward) - int(wish_backward), 0, int(wish_right) - int(wish_left))
	else:
		if previous_inputs["R"] != wish_right:
			wish_direction.z = 1 if wish_right else -1 if wish_left else 0
			
		if previous_inputs["L"] != wish_left:
			wish_direction.z = -1 if wish_left else 1 if wish_right else 0
			
		if previous_inputs["F"] != wish_forward:
			wish_direction.x = 1 if wish_forward else -1 if wish_backward else 0
			
		if previous_inputs["B"] != wish_backward:
			wish_direction.x = -1 if wish_backward else 1 if wish_forward else 0
				
		previous_inputs = {
			"R": wish_right,
			"L": wish_left,
			"F": wish_forward,
			"B": wish_backward
		}

func get_speed_multiplier() -> float:
	var multiplier: float = 1.0

	if crouched:
		multiplier *= crouch_speed_multiplier

	if wish_direction.normalized() == Vector3(-1, wish_direction.y, 0):
		multiplier *= 0.9

	return multiplier

func accelerate_ground(velocity: Vector3, delta: float) -> Vector3:
	var direction: Vector3 = wish_direction.normalized().rotated(Vector3.UP, camera_component.look_direction.y)
	var current_speed: float = velocity.dot(direction)
	var speed_multiplier: float = get_speed_multiplier()
	var add_speed: float = clamp(0, ground_acceleration * delta * speed_multiplier, ground_max_speed * speed_multiplier - current_speed)

	velocity += add_speed * direction
	
	return velocity
#endregion

#region air move
func air_move(velocity: Vector3, delta: float) -> Vector3:
	var wish_velocity: Vector3 = wish_direction.normalized().rotated(Vector3.UP, camera_component.look_direction.y)
	var wish_direction_temp: Vector3 = wish_velocity
	var wish_speed: float = wish_direction_temp.length()
	wish_direction_temp = wish_direction_temp.normalized()

	if wish_speed != 0 and (wish_speed > 320 * 1.905 / 100):
		wish_velocity *= 320 * 1.905 / 100 / wish_speed
		wish_speed = 320 * 1.905 / 100

	velocity = accelerate_air(velocity, wish_direction_temp, wish_speed, 10, delta)
	return velocity

func accelerate_air(velocity: Vector3, direction: Vector3, wish_speed: float, accelerate: float, delta: float) -> Vector3:
	wish_speed = min(wish_speed, air_max_speed)

	var current_speed: float = velocity.dot(direction)
	var add_speed: float = wish_speed - current_speed

	if add_speed <= 0: 
		return velocity

	var accelerate_speed: float = accelerate * 320 * 1.905 / 100 * delta

	accelerate_speed = min(accelerate_speed, add_speed)
	velocity += accelerate_speed * direction

	return velocity
#endregion

#region jumping
func handle_jump(velocity: Vector3) -> Vector3:
	if get_water_level() > 1:
		return velocity

	if !grounded and old_wish_jump == wish_jump and !bhop_cheat_enabled:
		return velocity

	if wish_jump != old_wish_jump and wish_jump and grounded and !crouched:

		just_jumped = true

		if crouching:
			crouch_jump()
			if crouch_jump_bug: 
				velocity.y = jump_power
			else:
				velocity.y = jump_power - (gravity / Engine.get_physics_ticks_per_second() / 2)
		elif uncrouching:
			if ctap_enabled:
				velocity = ctap(velocity)
			else:
				velocity.y = jump_power - (gravity / Engine.get_physics_ticks_per_second() / 2)
		else:
			velocity.y = jump_power - (gravity / Engine.get_physics_ticks_per_second() / 2)

		if limit_max_velocity:
			if (velocity * Vector3(1, 0, 1)).length() > ground_max_speed * limit_max_velocity_amount:
				velocity = ((velocity * Vector3(1, 0, 1)).normalized() * ground_max_speed * limit_max_velocity_amount) + Vector3(0, velocity.y, 0)

		return velocity
	return velocity
#endregion

#region crouching

# TODO: try to consolidate methods to shrink code
func setup_crouching() -> void:
	update_bounding_box(bounding_box_size)

	crouch_imer.wait_time = crouching_animation_time
	uncrouch_timer.wait_time = crouching_animation_time
	uncrouch_check_top.position.y = bounding_box_height_crouched + (bounding_box_size.y - bounding_box_height_crouched) / 2
	uncrouch_check_bottom.position.y = (bounding_box_size.y - bounding_box_height_crouched) / -2
	uncrouch_check_top.shape.size = Vector3(bounding_box_size.x, bounding_box_size.y - bounding_box_height_crouched, bounding_box_size.z)
	uncrouch_check_bottom.shape.size = Vector3(bounding_box_size.x, bounding_box_size.y - bounding_box_height_crouched, bounding_box_size.z)
	uncrouch_check_top.add_exception(player_root)
	uncrouch_check_bottom.add_exception(player_root)

func handle_crouching() -> void:
	if crouched and !wish_crouch:
		queue_uncrouching = true

	if queue_uncrouching:
		if try_uncrouch():
			queue_uncrouching = false

	if crouching_state_last_frame == wish_crouch:
		return
		
	if wish_crouch and get_water_level() < 3:
		queue_uncrouching = false
		if !crouched or !crouching:
			crouch()
	else:
		if crouched or crouching:
			queue_uncrouching = true

	crouching_state_last_frame = wish_crouch

func crouch() -> void:
	uncrouching = false
	update_bounding_box(Vector3(bounding_box_size.x, bounding_box_height_crouched, bounding_box_size.z))
	camera_component.crouch()

	if player_root.is_on_floor():
		uncrouch_timer.stop()
		crouch_imer.start()
		crouching = true
	else:
		if !crouched:
			player_root.position.y += bounding_box_size.y - bounding_box_height_crouched
		
		crouching = false
		crouched = true

func end_crouch() -> void:
	crouched = true
	crouching = false

func try_uncrouch() -> bool:
	if !(player_root.is_on_floor() and !uncrouch_check_top.is_colliding()) and !(!player_root.is_on_floor() and !uncrouch_check_bottom.is_colliding()):
		queue_uncrouching = true
		return false

	crouched = false
	crouching = false

	update_bounding_box(bounding_box_size)

	camera_component.uncrouch()
	crouch_imer.stop()

	if player_root.is_on_floor():
		uncrouching = true
		uncrouch_timer.start()
	else:
		uncrouch_timer.stop()
		uncrouching = false
		player_root.position.y -= bounding_box_size.y - bounding_box_height_crouched

	return true

func end_uncrouch() -> void:
	crouched = false
	uncrouching = false

func crouch_jump() -> void:
	crouched = true
	crouching = false
	uncrouching = false
	update_bounding_box(Vector3(bounding_box_size.x, bounding_box_height_crouched, bounding_box_size.z))
	camera_component.crouch()
	player_root.position.y += bounding_box_size.y - bounding_box_height_crouched

func ctap(velocity: Vector3) -> Vector3:
	crouch_imer.stop()
	uncrouch_timer.stop()
	crouched = true
	crouching = false
	uncrouching = false
	update_bounding_box(Vector3(bounding_box_size.x, bounding_box_height_crouched, bounding_box_size.z))
	camera_component.crouch()
	queue_uncrouching = true

	return Vector3(velocity.x, jump_power - (gravity / Engine.get_physics_ticks_per_second() / 2), velocity.z)
#endregion

#region velocity clip
## TODO: Check valve implementation. I suspect some differences with how friction is applied,
##      which leads to behavior different from source engine ramp sliding
#----------------------------------------[br]
## [b][u]PURPOSE[/u][/b]:[br] Method that alignes velocity along surface that allows for sliding along it. Leads to several bugs in source engine that define expressive movement. Among most importanat ones are "rampsliding" and "surfing"[br]
## [b][u]ARGS[/u][/b]:[br] velocity - [Vector3] - incoming velocity[br] n - [Vector3] - surface normal[br] overbounce - [float] - [color=gold]NULLABLE[/color] - multiplier of pushback force. In source engine games controlled with "sv_bounce" cheat[br]
## [b][u]RETURN[/u][/b]:[br] [Vector3] - velocity aligned along the surface
## [br]----------------------------------------
func clip_velocity(velocity: Vector3, surface_normal: Vector3, overbounce: float = 1.0) -> Vector3:
	# get modified velocity
	var backoff: float = velocity.dot(surface_normal)
	# if negative - cancell
	if backoff >= 0:
		return velocity
	# get reflected velocity component
	var change: Vector3 = surface_normal * backoff * overbounce
	# modify and return velocity
	velocity -= change
	# iterate once to make sure we aren't still moving through the plane <- Valve
	var adjust: float = velocity.dot(surface_normal)
	if adjust < 0.0:
		velocity -= surface_normal * adjust
	return velocity
#endregion

#region step up/down logic. Honestly some sort of black magic with testing motion before doing it... 
# -- In general its good if game can get by without step up or down. Its all tested over the years
# -- and turns our sidden shot elevation changes and movement shooters do not mix well. use ramps instead.

## [b][u]PURPOSE[/u][/b]:[br] Method executed in [method _ready]. Sets up transforms of step up raycast and stepdown shapecast
func setup_casts_step_check() -> void:
	# making step down ShapeCast3D same saze as player bounding box and height of max step up length
	step_down_shape_cast.shape.size = Vector3(bounding_box_size.x, max_step_up + 0.1, bounding_box_size.z)
	
	# positioning step down ShapeCast3D at the bottom of player bounding box
	step_down_shape_cast.position = Vector3(0, (max_step_up + 0.1)/ -2, 0)
	
	# making step up RayCast3d length be max step up length
	step_up_ray_cast.target_position.y = -(max_step_up + 0.1)

## [b][u]PURPOSE[/u][/b]:[br] Checks if wall is at walkable angle to be able to step up onto it[br]
## [b][u]ARGS[/u][/b]:[br] n - [Vector3] - normal of the wall
func is_wall_too_steep(surface_normal: Vector3) -> bool:
	# testing if surface angle is more than max walkable surface angle
	return surface_normal.angle_to(Vector3.UP) > player_root.floor_max_angle

## [b][u]PURPOSE[/u][/b]:[br] Snaps player to ground upon walking off ledges shorter than max step up length
func step_down_check() -> void:
	# reset state of stepping down
	var stepped_down: bool = false
	# determine if player was on floor in last frame or current frame
	var was_on_floor_last_frame: bool = (Engine.get_physics_frames() - last_floored <= 2)
	# see if ground below is close enough and wlkable to be stepped down
	var is_ground_below: bool = (step_down_shape_cast.is_colliding() and !is_wall_too_steep(step_down_shape_cast.get_collision_normal(0)))
	
	# if airborne and was grounded last frame and intending to jump: true -> step down , false -> update last frame grounded
	if !grounded and (stepped_down or was_on_floor_last_frame) and !wish_jump and player_root.velocity.y <= 0.1:
		# create new physics server test object
		var motion_test_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		
		# ask physics server testmotion if player can conplete step down movement and if there is ground to step down to
		if test_motion(player_root.global_transform, Vector3(0,-max_step_up,0), motion_test_result) and is_ground_below:
			# call camera smoothing method from [PlayerCameraComponent]
			camera_component.save_camera_position()

			# get travel distance from motion test
			var translate_y: float = motion_test_result.get_travel().y
			
			# tp player down
			player_root.position.y += translate_y
			# align player to floor, just in case
			player_root.apply_floor_snap()
			# stepdown success
			stepped_down = true

	# Update if player was snapped to ground with state of the method
	snapped_to_stairs_last_frame = stepped_down

## [b][u]PURPOSE[/u][/b]:[br] Moves player up if ledge height within step up length margin.[br][b][color=gold]!!IMPORTANT!! THIS METHOD MOVES PLAYER!
## EXECUTING [method CharacterBody3D.move_and_slide] WILL RESULT IN ERRONIOS DOUBLE MOVEMENT![/color][br]
## [b][u]ARGS[/u][/b]:[br] delta - [float] - delta time of last physics frame[br] new_velocity - [Vector3] - currently modifiable parent [CharacterBody3D] velocity[br]
## [b][u]RETURN[/u][/b]:[br] [bool] - returns if step up was successful. Use this return to prevent double movent with [method CharacterBody3D.move_and_slide]
func step_up_check(delta: float, new_velocity: Vector3) -> bool:
	# If player is not grounded and wasnt snapped to floor: cancell
	if !player_root.is_on_floor() and !snapped_to_stairs_last_frame:
		return false
		
	# If moving up or not moving horizontally: cancell
	if new_velocity.y > 0 or (new_velocity * Vector3(1, 0 ,1)).length() == 0:
		return false

	# Project next motion using delta and current velocity
	var expected_motion: Vector3 = new_velocity * Vector3(1 ,0 ,1) * delta
	# Predict next motion with step up in mind
	var step_pos_with_clearance: Transform3D = player_root.global_transform.translated(expected_motion + Vector3(0, max_step_up * 2, 0))
	# New physics collision check instance
	var down_check_result: KinematicCollision3D = KinematicCollision3D.new()

	# Test if player can fit in desegnated place and ground is either StaticBody3D or god forbid CSGShape3D. I guess rn you couldnt step up other players...
	if (player_root.test_move(step_pos_with_clearance, Vector3(0, -max_step_up * 2 ,0), down_check_result) and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		# Determine travel distance
		var step_height: float = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - player_root.global_position).y
	
		# If travel distance is invalid: cancell
		if step_height > max_step_up or step_height <= 0.01 or (down_check_result.get_position() - player_root.global_position).y > max_step_up:
			return false
	
		# Move raycast to the predicted motion destination
		step_up_ray_cast.global_position = down_check_result.get_position() + Vector3(0,max_step_up,0) + expected_motion.normalized() * 0.1
		
		# Update raycast
		step_up_ray_cast.force_raycast_update()
	
		# Check if step up spot is valid
		if step_up_ray_cast.is_colliding() and not is_wall_too_steep(step_up_ray_cast.get_collision_normal()):
			# Call camera smoothing method from [PlayerCameraComponent]
			camera_component.save_camera_position()
			
			# Move player up the ledge
			player_root.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			
			# Align with the floor
			player_root.apply_floor_snap()
			
			# Update state
			snapped_to_stairs_last_frame = true
			
			# On success send true which will cancell out move_and_slide
			return true

	# In case of fail just pass the method
	return false

## [b][u]PURPOSE[/u][/b]:[br] Perfoms a test motion of Player parent with [method PhysicsServer3D.body_test_motion][br]
## [b][u]ARGS[/u][/b]:[br] from - [Transform3D] - original body transform[br] motion - [Vector3] - test motion destination[br] result - [PhysicsTestMotionResult3D] - [color=gold]NULLABLE[/color] - Describes the motion and collision result[br]
## [b][u]RETURN[/u][/b]:[br] [bool] - returns if motion was successful 

func test_motion(from: Transform3D, motion: Vector3, result: PhysicsTestMotionResult3D = null) -> bool:
	# if result is null instance new one
	if !result:
		result = PhysicsTestMotionResult3D.new()

	# instance new physcs motion parameters 
	var parameters : PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()

	# define motion in prams
	parameters.from = from
	parameters.motion = motion

	# test motion
	return PhysicsServer3D.body_test_motion(player_root.get_rid(), parameters , result)
#endregion

#region impulse
## apply_impulse(direction: Vector3, multiplier: float) -> void
## [u][b]PURPOSE[/u][/b]:[br] Adds knockback Vector3 impulses to be processed inside [method process_movement] at step 13[br]
## [u][b]ARGS[/u][/b]:[br] direction - [Vector3] - direction of knockback[br] multiplier - [float] - multiplier of dir
func apply_impulse(direction: Vector3, multiplier: float) -> void:
	stacked_knockback += direction * multiplier
#endregion

#region bounding box
func update_bounding_box(size: Vector3) -> void:
	bounding_box.shape.size = size
	bounding_box.position.y = size.y / 2.0
	%triggerbox_collision.shape.size.y = size.y
	%triggerbox_collision.position.y = size.y / 2.0
#endregion

#region noclip move
func toggle_noclip() -> bool:
	if move_type != GSPlayerState.MOVE_TYPE.NOCLIP:
		grounded = false
		move_type = GSPlayerState.MOVE_TYPE.NOCLIP
		bounding_box.disabled = true
		return true

	move_type = GSPlayerState.MOVE_TYPE.AIRBORNE
	bounding_box.disabled = false

	return false

func noclip_move(velocity: Vector3) -> Vector3:
	var direction: Vector3 = wish_direction.normalized().rotated(Vector3.FORWARD, -camera_component.look_direction.x).rotated(Vector3.UP, camera_component.look_direction.y)
	var wish_speed = 600 * 1.905 / 100 * direction.normalized()
	velocity = wish_speed

	return velocity
#endregion

#region water move
func get_water_level() -> GSPlayerState.WATER_LEVEL:
	var box: Area3D = %water_trigger

	if !box.has_overlapping_areas():
		move_type = GSPlayerState.MOVE_TYPE.WALK
		return GSPlayerState.WATER_LEVEL.NOT_IN_WATER

	var areas: Array[Area3D] = box.get_overlapping_areas()

	for i: int in range(areas.size()):
		if !areas[i].is_in_group("liquid"):
			in_water = false

		if areas[i].is_in_group("liquid"):
			var water: Node = areas[i].get_parent()

			if !(water is GSLiquidBrush):
				break

			var water_body_vertical_extends: Vector2 = Vector2(water.bot, water.top)
			var eyes_height: float = camera_component.get_node("head").global_position.y
			var waist_height: float = bounding_box.global_position.y + 12.5 * 1.905 / 100

			if eyes_height > water_body_vertical_extends.x and eyes_height < water_body_vertical_extends.y:
				# run extinguish and other being submerged in watter effects
				move_type = GSPlayerState.MOVE_TYPE.SWIM

				if crouched:
					try_uncrouch()

				return GSPlayerState.WATER_LEVEL.EYES

			elif waist_height > water_body_vertical_extends.x and waist_height < water_body_vertical_extends.y:
				# run extinguish and other being submerged in watter effects
				move_type = GSPlayerState.MOVE_TYPE.SWIM
				return GSPlayerState.WATER_LEVEL.WAIST

			move_type = GSPlayerState.MOVE_TYPE.WALK
			return GSPlayerState.WATER_LEVEL.FEET

	move_type = GSPlayerState.MOVE_TYPE.WALK
	return GSPlayerState.WATER_LEVEL.NOT_IN_WATER

func full_water_move(velocity: Vector3, delta: float) -> Vector3:

	if get_water_level() >= 1:
		velocity = check_water_jump(velocity, delta)
	
	if velocity.y < 0 and water_jump_time != 0.0:
		water_jump_time = 0.0
		state_water_jumping = false
	
	if wish_jump:
		velocity = check_water_jump_button(velocity, delta) #TODO: rename specific to waterr movement
	
	velocity = water_move(velocity, delta)

	if grounded:
		velocity.y = 0

	return velocity

func check_water_jump_button(velocity: Vector3, delta: float) -> Vector3: 
	if water_jump_time != 0.0:
		water_jump_time -= delta
		return velocity
	
	if get_water_level() >= 2:
		grounded = false
		if !can_swim:
			return velocity
		velocity.y = 100 * 1.905 / 100
		return velocity

	return velocity

func check_water_jump(velocity: Vector3, delta: float) -> Vector3:
	if water_jump_time != 0.0:
		water_jump_time -= delta
		if water_jump_time < 0:
			water_jump_time = 0
		return velocity
	
	if velocity.y < -180 * 1.905 / 100:
		return velocity
	
	var flat_velocity: Vector3 = Vector3(velocity.x, 0, velocity.z)

	var current_speed: float = flat_velocity.length()

	var flat_forward : Vector3 = camera_component.get_angle_vectors()[0] * wish_direction.x * ground_max_speed + camera_component.get_angle_vectors()[2] * wish_direction.z * ground_max_speed
	flat_forward.y = 0.0

	if current_speed != 0.0 and flat_velocity.normalized().dot(flat_forward.normalized()) < 0.0 and !wish_jump:
		return velocity
	
	var vector_start : Vector3 = bounding_box.global_position

	var vector_end : Vector3 = vector_start + 30.0*1.905/100 * flat_forward.normalized()

	%water_jump_destination_check.global_position = vector_start
	%water_jump_destination_check.target_position = vector_end
	%water_jump_destination_check.force_raycast_update()
	if !%water_jump_destination_check.is_colliding():
		return velocity
	var shore_wall_normal = %water_jump_destination_check.get_collision_normal()
	water_jump_wish_velocity = shore_wall_normal * -50 * 1.905 / 100
	vector_start.y = camera_component.get_node("head").global_position.y + 10*1.905/100
	vector_end = vector_start + 30.0*1.905/100 * flat_forward.normalized()
	%water_jump_destination_check.global_position = vector_start
	%water_jump_destination_check.target_position = vector_end
	%water_jump_destination_check.force_raycast_update()
	if %water_jump_destination_check.is_colliding():
		return velocity
	
	vector_start = vector_end
	vector_end.y -= 1024 * 1.905 / 100
	%water_jump_destination_check.global_position = vector_start
	%water_jump_destination_check.target_position = vector_end
	%water_jump_destination_check.force_raycast_update()
	if %water_jump_destination_check.is_colliding():
		var shore_normal = %water_jump_destination_check.get_collision_normal()
		if shore_normal.y >= 0.7 and !state_water_jumping:
			water_jump_time = 500.0
			state_water_jumping = true
			velocity.y = water_jump_power
			print("jumped")
	return velocity

func water_move(velocity: Vector3, delta: float) -> Vector3:
	var wish_velocity : Vector3 = camera_component.get_angle_vectors()[0] * wish_direction.x * ground_max_speed + camera_component.get_angle_vectors()[2] * wish_direction.z * ground_max_speed

	if !can_swim:
		wish_velocity.x *= 0.1
		wish_velocity.y = -60 * 1.905 / 100
		wish_velocity.z *= 0.1

	if wish_jump:
		wish_velocity.y += ground_max_speed
	elif wish_velocity == Vector3.ZERO:
		wish_velocity.y -= 60 * 1.905 / 100
	else:
		wish_velocity.y = ground_max_speed * camera_component.get_angle_vectors()[0].y
		grounded = false

	var wish_speed: float = wish_velocity.length()

	if wish_speed > ground_max_speed:
		wish_velocity *= ground_max_speed / wish_speed
		wish_speed = ground_max_speed

	if !swimming_mastery:
		wish_speed *= 0.8

	var speed: float = velocity.length()
	var new_speed: float = 0

	if speed != 0.0:
		new_speed = speed - delta * speed * 4 * 0.4

		if new_speed < 0.01:
			new_speed = 0

		velocity *= new_speed / speed
	else:
		new_speed = 0

	if wish_speed >= 0.1:
		var add_speed: float = wish_speed - new_speed

		if add_speed > 0:
			wish_velocity = wish_velocity.normalized()

			var accelerate_speed: float = ground_acceleration * wish_speed * delta * 0.8

			if accelerate_speed > add_speed:
				accelerate_speed = add_speed

			var delta_speed: Vector3 = accelerate_speed * wish_velocity

			velocity += delta_speed
	return velocity

func water_jump(velocity: Vector3, delta: float) -> Vector3:
	if water_jump_time > 10000:
		water_jump_time = 10000
	
	if water_jump_time == 0.0:
		return velocity
	
	if water_jump_time <= 0.0 or get_water_level() >= 1:
		water_jump_time = 0.0
		state_water_jumping = false
	
	water_jump_time -= 1000.0 * delta

		
	velocity.x = water_jump_wish_velocity.x
	velocity.z = water_jump_wish_velocity.z
	return velocity
#endregion
