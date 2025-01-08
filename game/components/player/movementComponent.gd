##[b][color=#f0b000]!!! IMPORTANT !!![/color] - This component requires to be a child of [CharacterBody3D] to function properly[b][br][br]
##This component listens to user inputs to move parent node in 3D space. All default values aren an example implementation and are converted from TF2 and correspond to default movement of Soldier
class_name PlayerMovementComponent
extends Node3D

## [CharacterBody3D] parent.
@onready
var P : CharacterBody3D = get_node("..")
## Player bounding box. Collides with "WORLD" collision layer and does not rotate
@export
var bBox : CollisionShape3D;
## Reference to camera component
@export
var camComp : Node3D


func _physics_process(delta):
	processMovement(delta)

# Acceleration Variables

# [value] * 1.905 / 100 <- Closest conversion from hammer units to meters. "Hammer Unit" is Source Engine's distance measuring unit

@export_category("Acceleration Variables")

## Gravitational acceleration.[br][br]Gravity is applied each physics frame(unless grounded) in two parts to improve precision and mitigate difference caused by perfomance problems
@export
var gravity : float = 800 * 1.905 / 100
@export
var jumpPower : float = 289 * 1.905 / 100
@export_subgroup("Grounded Movement")
## Maximum speed while grounded. Default value is 240 HU/s which is TF2 Soldier's speed
@export
var groundMaxSpeed : float = 240.0 * 1.905 / 100
## How fast player gains speed while grounded. Default value is just ten times bigger than groundMaxSpeed
@export
var groundAccel : float = 2400.0 * 1.905 / 100
## How fast player looses speed while grounded. Default value is 400 HU/s
@export
var groundFriction : float = 400 * 1.905 / 100
## Any speed less than that value gets clipped. Player stops if moves slower than this value while on ground. Makes precise movements a bit more responsive
@export
var groundSpeedCutOff : float = 20 * 1.905 / 100
## Limit Max velocity upon landing. This is to nerf bunnyhopping to stop players from achieveing speeds above limitMaxVelAmount values.
@export
var limitMaxVel : bool = false
## Maximum velocity cap. If [i]limitMaxVel[/i] is set to [i][color=lime]true[/color][/i] this will make so player velocity limited to their groundMaxSpeed * limitMaxVelAmount
@export_range(1.0, 2.0, 0.01, "or_greater")
var limitMaxVelAmount : float = 1.2
@export_subgroup("Airborne Movement")
## Maximum speed player can get without air strafing. Default value is 30 HU/s
@export
var airMaxSpeed : float = 30.0 * 1.905 / 100
@export_subgroup("Movement flags")
## Determines if player inputsare interpreted as "Null Movement"[br][color=#00000080][i]Null movement is type of movemnt interpretation where movement keys apply immediately and not on Basis summ of Rght - Left. That makes so if left key is pressed down and then right key is pressed movement direction is overriden to "move right"
var useNullMovement : bool = true

#SCRIPT VARIABLES
var wDir := Vector2.ZERO

#STATE VARIABLES
## This variable is Player grounded state. If TRUE player is grounded
var grounded : bool = false

## PURPOSE: combines all other movement altering methods and overwrites velocity of a parent. Follows Source Engine like physics frame update order.[br]
## To see full frame order look into [color=#4040ff][url=https://www.dropbox.com/scl/fi/c0vxjztou9xj0of1zamer/Review.pdf?rlkey=rv9l35ze3uvhbk5llnwl1ld0k&e=2&dl=0]this document[/url][/color], Page 5 Section 2.2.2 Player tick by [color=#4040ff][url=https://steamcommunity.com/id/ildprut]Ildprut[/url][/color] 
func processMovement(delta) -> void:
	#step 0: get current velocity
	var newVel : Vector3 = P.velocity
	#step 1: Check grounded
	grounded = checkGrounded()
	#step 2: Handle crouching
	handleCrouching()
	#step 3: Apply first half of gravity
	if !grounded: newVel.y -= gravity / 2 * delta
	#step 4: handle Jumping
	newVel = handleJump(newVel)
	#step 5: Limit max velocity. This was implemented in TF2 to heavily nerf BunnyHopping. Max velocity is limited to 120% of groundMaxSpeed
	if grounded and limitMaxVel:
		if (newVel * Vector3(1,0,1)).length() > groundMaxSpeed * limitMaxVelAmount:
			newVel = ((newVel * Vector3(1,0,1)).normalized() * groundMaxSpeed * limitMaxVelAmount) + Vector3(0,newVel.y,0)
	#step 6: if grounded - apply friction and set vertical velocity to 0
	if grounded:
		newVel = applyFriction(newVel, delta)
		newVel.y = 0.0
	#step 7: apply acceleration
	newVel = applyAcceleration(newVel, delta)
	#step 8: Move and collide. In godot CharacterBody3D Does that automatically and without rewriting 3D physics it is close enough to just let move_and_slide() handle this
	if P.is_on_wall():
		newVel = clipVel(newVel,P.get_wall_normal())
	if (newVel * Vector3(1.0,0,1.0)).length() > groundMaxSpeed * 1.2:
		newVel = clipVel(newVel,P.get_floor_normal()) 
	#step 9: Check for ground to stand on. Not the same implementation as in Source Engine
	if grounded: P.apply_floor_snap()
	#step 10: Apply second half of gravity
	if !grounded: newVel.y -= gravity / 2 * delta
	#step 11: Check grounded and if so set vertical velocity to 0
	if grounded:
		newVel.y = 0.0
	#step 12: Limit max velocity
	if grounded and limitMaxVel:
		if (newVel * Vector3(1,0,1)).length() > groundMaxSpeed * limitMaxVelAmount:
			newVel = ((newVel * Vector3(1,0,1)).normalized() * groundMaxSpeed * limitMaxVelAmount) + Vector3(0,newVel.y,0)
	#step 13: Handle triggers collision
	#step 14: Update bounding box
	#step 15: Handle projectiles
	%velScale.scale.y = (P.velocity * Vector3(1,0,1)).length() * 0.25
	%velPointer.rotation = -Vector2(P.velocity.x,P.velocity.z).rotated(camComp.lookDir.y).angle_to(Vector2.DOWN)
	%dirScale.scale.y = wDir.length() * groundMaxSpeed * 0.25
	%dirPointer.rotation = -wDir.angle_to(Vector2.DOWN)
	P.velocity = newVel
	P.move_and_slide()
	# print_rich("Speed: " + str((newVel * Vector3(1,0,1)).length() * 100 / 1.905) + " [color=red]X: " + str(newVel.x / 1.905 * 100) + "[/color] [color=#1080ff]Y: " + str(newVel.y / 1.905 * 100) + "[/color] [color=lime]Z: " + str(newVel.z / 1.905 * 100) + "[/color]")

## PURPOSE: Update player grounded state. If player is on floor and not moving up too fast function returns True
func checkGrounded() -> bool:
	return (
		(P.is_on_floor()) and
		(P.velocity.y <= 180 *1.905 / 100)
		)# or snappedToStairLastFrame


## PURPOSE: returns velocity affected by ground friction
func applyFriction(vel, delta) -> Vector3:
	var speed = (vel * Vector3(1,0,1)).length()
	if speed != 0.0:
		var clippedSpeed = max(groundSpeedCutOff, speed)
		var speedDrop = clippedSpeed * groundFriction * delta
		vel *= max(speed - speedDrop, 0) / speed
	return vel 

## PURPOSE: return modified velocity after accelerating
func applyAcceleration(vel, delta) -> Vector3:
	getWishDir()
	if grounded:
		vel = accelGround(vel, delta)
	else:
		vel = accelAir(vel, delta)
	return vel


#right is negative X, left is positive
#back is negative Y, forward is positive
## PURPOSE: interprets user input
var prevInputs := {"R":wishR,"L":wishL,"F":wishF,"B":wishB,}
func getWishDir() -> void:
	if P.uiFocused: return
	if !useNullMovement:
		wDir = Vector2(
			int(wishL) - int(wishR),
			int(wishF) - int(wishB)
		)
	else:
		if !wishR:
			if wishL: wDir.x = 1
			else: wDir.x = 0
		if !wishL:
			if wishR: wDir.x = -1
			else: wDir.x = 0
		if !wishF:
			if wishB: wDir.y = -1
			else: wDir.y = 0
		if !wishB:
			if wishF: wDir.y = 1
			else: wDir.y = 0
		if prevInputs["R"] == false and wishR:
			wDir.x = -1
		if prevInputs["R"] == true and !wishR:
			if wishL: wDir.x = 1
			else: wDir.x = 0
		if prevInputs["L"] == false and wishL:
			wDir.x = 1
		if prevInputs["L"] == true and !wishL:
			if wishR: wDir.x = -1
			else: wDir.x = 0
		if prevInputs["F"] == false and wishF:
			wDir.y = 1
		if prevInputs["F"] == true and !wishF:
			if wishB: wDir.y = -1
			else: wDir.y = 0
		if prevInputs["B"] == false and wishB:
			wDir.y = -1
		if prevInputs["B"] == true and !wishB:
			if wishF: wDir.y = 1
			else: wDir.y = 0
		prevInputs = {"R":wishR,"L":wishL,"F":wishF,"B":wishB,}
	wDir = wDir.normalized()


func accelGround(vel:Vector3,delta:float)->Vector3:
	var dir = Vector3(wDir.x,0,wDir.y).rotated(Vector3.UP, camComp.lookDir.y)
	var currSpeed = vel.dot(dir)
	var speedMult = getSpeedMult()
	var addSpeed = clamp(0, groundAccel * delta * speedMult, groundMaxSpeed * speedMult - currSpeed)
	vel += addSpeed * dir
	return vel

func getSpeedMult() -> float:
	var mult = 1.0
	if crouched:
		mult *= crouchSpeedMultiplier
	if wDir.y < 0:
		mult *= 0.9
	return mult

func accelAir(vel:Vector3,delta:float)->Vector3:
	var dir = Vector3(wDir.x,0,wDir.y).rotated(Vector3.UP, camComp.lookDir.y)
	var currSpeed = vel.dot(dir)
	#This measure is in place to stop players from slowly climbing up non walkable walls but allow it when surfing with highj enough horizontal speed.
	if (vel * Vector3(1,0,1)).length()/5 < 0.25 and isWallTooSteep(P.get_wall_normal()): return vel
	var addSpeed = airMaxSpeed - currSpeed
	if addSpeed >= 0:
		vel += min(600 * delta, addSpeed) * dir
	return vel

var wishR := bool(false)
var wishL := bool(false)
var wishF := bool(false)
var wishB := bool(false)
var wishJump := bool(false)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("crouch"):
		wishCrouch = true
	elif !Input.is_action_pressed("crouch"):
		wishCrouch = false
	wishR = Input.is_action_pressed("right")
	wishL = Input.is_action_pressed("left")
	wishF = Input.is_action_pressed("forward")
	wishB = Input.is_action_pressed("back")
	if Input.is_action_pressed("jump"):
		wishJump = true
	elif !Input.is_action_pressed("jump"):
		wishJump = false
	if Input.is_key_pressed(KEY_F1): Engine.time_scale = 0.1;
	if Input.is_key_pressed(KEY_F2): Engine.time_scale = 1.0;

func _ready() -> void:
	setupCrouching()



func handleJump(vel) -> Vector3:
	if wishJump and grounded and !crouched:
		grounded = false
		if crouching:
			crouchJump()
			if jumpCrouchBug: vel.y = jumpPower
			else: vel.y = jumpPower - (gravity / Engine.get_physics_ticks_per_second() / 2)
		elif uncrouching:
			vel.y = jumpPower - (gravity / Engine.get_physics_ticks_per_second() / 2)
			if cTapEnabled:
				cTap()
		else:
			vel.y = jumpPower - (gravity / Engine.get_physics_ticks_per_second() / 2)
		if limitMaxVel:
			if (vel * Vector3(1,0,1)).length() > groundMaxSpeed * limitMaxVelAmount:
				vel = ((vel * Vector3(1,0,1)).normalized() * groundMaxSpeed * limitMaxVelAmount) + Vector3(0,vel.y,0)
		return vel
	return vel

#region crouching
#TODO: Move to variables space once done developing crouching
@export_subgroup("Crouching")
@export
var crouchingAnimationTime : float = 0.15
@export
var crouchSpeedMultiplier : float = 0.3
@export
var bBoxHeightCrouched : float = 1.2
##Enable TF2 bug that allows to jump 2 hammer units higher if player crouch-jumps than jump crouches. If false crouch jumping and jump crouching is the same height[br][color=#777][i]This bug stems from small code error made by Valve. Usually half of one tick of gravity substracted from jump power when jumping. In case of crouch jumping it just isnt. If gravity is 0 impulse from jumping is the same. Better explanation by Shounic [color=#03b][url=https://www.youtube.com/watch?v=7z_p_RqLhkA]here[/url]
@export
var jumpCrouchBug : bool = true
##Enable TF2 bug that allows to jump, crouch in air and avoid upwards shift. If false player can jump as high as regular jump[br][color=#777][i]This bug stems from erronious behaviour. Regularly player should be shifted upwards when crouching in air. Since player havent finished uncrouching animation player then forced to stay crouched until space below player allows for uncrouching. That allows for closer to ground player origin calculation and explosions send player much highier. Better explanation by Shounic [color=#03b][url=https://www.youtube.com/watch?v=76HDJIWfVy4]here[/url]
@export
var cTapEnabled : bool = true
var crouching : bool = false
var uncrouching : bool = false
var crouched : bool = false
var queueUncrouching : bool = false
var wishCrouch : bool = false
@onready
var uncrouchTimer : Timer = $uncrouching
@onready
var crouchTimer : Timer = $crouching
@onready
var uncrouchCheckTop : ShapeCast3D = $uncrouchCastTop
@onready
var uncrouchCheckBottom : ShapeCast3D = $uncrouchCastBottom
@onready
var bBoxSize : Vector3 = bBox.shape.size
var crouchingStateLastFrame : bool = false

func setupCrouching() -> void:
	uncrouchCheckTop.position.y = bBoxHeightCrouched + (bBoxSize.y - bBoxHeightCrouched) / 2
	uncrouchCheckBottom.position.y = (bBoxSize.y - bBoxHeightCrouched) / -2
	uncrouchCheckTop.shape.size = Vector3(bBoxSize.x,bBoxSize.y - bBoxHeightCrouched,bBoxSize.z)
	uncrouchCheckBottom.shape.size = Vector3(bBoxSize.x,bBoxSize.y - bBoxHeightCrouched,bBoxSize.z)
	uncrouchCheckTop.add_exception(P)
	uncrouchCheckBottom.add_exception(P)
	crouchTimer.wait_time = crouchingAnimationTime
	uncrouchTimer.wait_time = crouchingAnimationTime

func handleCrouching() -> void:
	if crouched and !wishCrouch:
		queueUncrouching = true
	if queueUncrouching:
		if tryUncrouch():
			queueUncrouching = false
		else: pass
	if crouchingStateLastFrame == wishCrouch : return
	if wishCrouch:
		queueUncrouching = false
		if !crouched or !crouching:
			crouch()
	else:
		if crouched or crouching:
			queueUncrouching = true
	crouchingStateLastFrame = wishCrouch

func crouch() -> void:
	uncrouching = false
	bBox.shape.size.y = bBoxHeightCrouched
	bBox.position.y = bBoxHeightCrouched / 2
	camComp.crouch()
	if P.is_on_floor():
		uncrouchTimer.stop()
		crouchTimer.start()
		crouching = true
	else:
		if !crouched: P.position.y += bBoxSize.y - bBoxHeightCrouched
		crouching = false
		crouched = true
func endCrouch() -> void:
	crouched = true
	crouching = false

func tryUncrouch() -> bool:
	if !(P.is_on_floor() and !uncrouchCheckTop.is_colliding()) and !(!P.is_on_floor() and !uncrouchCheckBottom.is_colliding()):
		queueUncrouching = true
		return false
	crouched = false
	crouching = false
	bBox.shape.size.y = bBoxSize.y
	bBox.position.y = bBoxSize.y / 2
	camComp.uncrouch()
	crouchTimer.stop()
	if P.is_on_floor():
		uncrouching = true
		uncrouchTimer.start()
	else:
		uncrouchTimer.stop()
		uncrouching = false
		P.position.y -= bBoxSize.y - bBoxHeightCrouched
	return true
func endUncrouch() -> void:
	crouched = false
	uncrouching = false

func crouchJump() -> void:
	crouched = true
	crouching = false
	uncrouching = false
	bBox.shape.size.y = bBoxHeightCrouched
	bBox.position.y = bBoxHeightCrouched / 2
	camComp.crouch()
	P.position.y += bBoxSize.y - bBoxHeightCrouched

func cTap() -> void:
	crouchTimer.stop()
	uncrouchTimer.stop()
	crouched = true
	crouching = false
	uncrouching = false
	bBox.shape.size.y = bBoxHeightCrouched
	bBox.position.y = bBoxHeightCrouched / 2
	camComp.crouch()
	queueUncrouching = true
#endregion

		
func clipVel(vel:Vector3,n: Vector3) -> Vector3:
	var pushBack := vel.dot(n)
	if pushBack >= 0: return vel
	var change := n * pushBack
	return (vel - change)

func isWallTooSteep(n) -> bool:
	return n.angle_to(Vector3.UP) > P.floor_max_angle
