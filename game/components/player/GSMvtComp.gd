##[b][color=gold]!!! IMPORTANT !!![/color] - This component requires to be a child of [CharacterBody3D] to function properly[b][br][br]
##This component listens to user inputs to move parent node in 3D space. All default values aren an example implementation and are converted from TF2 and correspond to default movement of Soldier
class_name PlayerGSMvtComp
extends Node3D

#region node references
## [CharacterBody3D] parent.
@onready
var P : CharacterBody3D = get_node("..")
## Player bounding box. Collides with "WORLD" collision layer and does not rotate
@export
var bBox : CollisionShape3D;
## Reference to camera component
@export
var camComp : Node3D
#endregion

#region Variables

#TODO-IMPORTANT: MOVE MOST OF THE VARIABLES THAT ARE CONSIDERED CLASS SPECIFIC TO PLAYER SCRIPT AND CREATE METHODS FOR SET/GET THEM

# [value] * 1.905 / 100 <- Closest conversion from hammer units to meters. "Hammer Unit" is Source Engine's distance measuring unit
@export_category("Acceleration Variables")
## Gravitational acceleration.[br][br]Gravity is applied each physics frame(unless grounded) in two parts to improve precision and mitigate difference caused by perfomance problems
@export
var gravity := float(800 * 1.905 / 100)
@export
## Impulse that given to player upon jumping.
var jumpPower := float(289 * 1.905 / 100)
@export_subgroup("Grounded Movement")
@export
## Maximum speed while grounded. Default value is 240 HU/s which is TF2 Soldier's speed
var groundMaxSpeed := float(240.0 * 1.905 / 100)
@export
## How fast player gains speed while grounded. Default value is just ten times bigger than groundMaxSpeed
var groundAccel := float(2400.0 * 1.905 / 100)
@export
## How fast player looses speed while grounded. Default value is 400 HU/s
var groundFriction := float(400 * 1.905 / 100)
@export
## Any speed less than that value gets clipped. Player stops if moves slower than this value while on ground. Makes precise movements a bit more responsive
var groundSpeedCutOff := float(100 * 1.905 / 100)
@export_range(1.0, 2.0, 0.01, "or_greater")
## Maximum velocity cap. If [i]limitMaxVel[/i] is set to [i][color=lime]true[/color][/i] this will make so player velocity limited to their groundMaxSpeed * limitMaxVelAmount
var limitMaxVelAmount := float(1.2)
@export
## Detrmines maximum step up/down height
var maxStepUp := float(0.35)
@export_subgroup("Airborne Movement")
@export
## Maximum speed player can get without air strafing. Default value is 30 HU/s
var airMaxSpeed := float(30.0 * 1.905 / 100)
@export
##Determines how fast player needs to move upward to be considered airborne
var upwardVelocityGate := float(180 * 1.905 /100);
@export_subgroup("Movement flags")
@export
## Determines if player inputsare interpreted as "Null Movement"[br][color=#00000080][i]Null movement is type of movemnt interpretation where movement keys apply immediately and not on Basis summ of Rght - Left. That makes so if left key is pressed down and then right key is pressed movement direction is overriden to "move right"
var useNullMovement := bool(true)
@export
## Enable and disable automatic BHopping. 
var bHopCheat := bool(false)
@export
## Limit Max velocity upon landing. This is to nerf bunnyhopping to stop players from achieveing speeds above limitMaxVelAmount values.
var limitMaxVel := bool(true)
## Variable that shows if player was snapped to floor due to step up/step down last frame
var snappedToStairsLastFrame := bool(false)
## variable of last physics frame when player was on floor to not apply floor snap more than needed
var lastFloored := int(-INF)
## This variable is Player grounded state. If TRUE player is grounded
var grounded := bool(false)
var wishR := bool(false)
var wishL := bool(false)
var wishF := bool(false)
var wishB := bool(false)
var wishJump := bool(false)
var wishCrouch := bool(false)
##WishDir - player directional inputs mapped to vec2
var wDir := Vector2.ZERO
##Stacked knockback is Vec3 impulse given to player from knockback sources that is applied at projectile processing step and then set to 0 
var stackedKnockback : Vector3 = Vector3.ZERO
@export_subgroup("Knockback variables")
@export
##General multiplier of knockback. each class in TF2 has their kncockback mult. Soldier while grounded has 5.0, while airborne 10.0, demoman has 9.0
var knockbackMult := float(5.0)
@export
##Multiplier of knockback force.[br][color=#777][i]In source engine it is reffered as mass, despite being ratio to volume of bounding box while stanfing. And even then in tf2 it should be NOT 0.67 cause bounding box height got changed since release(from 55 hammer units to 62 hammer units high) but knockback mult kept as original to not mess up with mapping and knockback(explosive jumping in particular).  [color=#4040ff][url=https://www.dropbox.com/scl/fi/c0vxjztou9xj0of1zamer/Review.pdf?rlkey=rv9l35ze3uvhbk5llnwl1ld0k&e=2&dl=0]this document[/url][/color], Page 13 Section 6 Projectiles and Knockback by [color=#4040ff][url=https://steamcommunity.com/id/ildprut]Ildprut[/url][/color]
var crouchedKnockbackMult := float(0.67)
@export
##Multiplier of knockback while airborne
var airborneKnockbackMult := float(10.0)
@export
##Damage resistance from self damage while explosive jumping. In TF2 explosions deal reduced self damage(If no enemies caught in the blast. Otherwise it deals full self damage). Soldier has 0.6 mult when airborne, 1.0 mult when NOT IN AIR(not in air makes way for super jumps from water. that way player takes most self damge which translates to most amount of knockback). Demoman has 75% no matter the state
var selfBlastDamageReduction := float(1.0)
@export
##Damage resistance from self damage while explosive jumping while airborne.
var selfBlastDamageReductionAir := float(0.6)
var justJumped := bool(false)
@export_subgroup("Crouching")
@export
##How long it takes for player to coruch or ucrouch
var crouchingAnimationTime : float = 0.15
@export
##How much ground movement sopeed is multiplied when crouching
var crouchSpeedMultiplier : float = 0.3
@export
var bBoxHeightCrouched : float = 1.2
##Enable TF2 bug that allows to jump 2 hammer units higher if player crouch-jumps than jump crouches. If false crouch jumping and jump crouching is the same height[br][color=#777][i]This bug stems from small code error made by Valve. Usually half of one tick of gravity substracted from jump power when jumping. In case of crouch jumping it just isnt. If gravity is 0 impulse from jumping is the same. Better explanation by Shounic [color=#03b][url=https://www.youtube.com/watch?v=7z_p_RqLhkA]here[/url]
@export
##Enables bugged behavior when crouch jumping is highier than jump crouching [color=#888]This behavior stem from Valve forgetting to substract 1 gravity tick from jump power. In TF2 that results in 2 hammer unit difference in jump height 0.04m  
var crouchJumpBug : bool = true
##Enable TF2 bug that allows to jump, crouch in air and avoid upwards shift. If false player can jump as high as regular jump[br][color=#777][i]This bug stems from erronious behaviour. Regularly player should be shifted upwards when crouching in air. Since player havent finished uncrouching animation player then forced to stay crouched until space below player allows for uncrouching. That allows for closer to ground player origin calculation and explosions send player much highier. Better explanation by Shounic [color=#03b][url=https://www.youtube.com/watch?v=76HDJIWfVy4]here[/url]
@export
##Enable or disable bug from source engine that allows to crouch and shrink hitbox right on ground and bypass upwards shift to allows to get maximum blast foprce from explosive jumping
var cTapEnabled : bool = true
##State variable to show that player is in crouching down animation
var crouching : bool = false
##State variable to show that player is in uncrouching animation
var uncrouching : bool = false
##State variable that shows that player is crouched
var crouched : bool = false
##state variable that shows that player should be uncrouched as soon as world geometry allows it 
var queueUncrouching : bool = false
@onready
##Timer node reference
var uncrouchTimer : Timer = $uncrouching
@onready
##Timer node reference
var crouchTimer : Timer = $crouching
@onready
##Reference to the shpaecast node that checks if uncrouching on ground is blocked
var uncrouchCheckTop : ShapeCast3D = $uncrouchCastTop
@onready
##Reference to the shpaecast node that checks if uncrouching in air is blocked
var uncrouchCheckBottom : ShapeCast3D = $uncrouchCastBottom
@onready
##Gets Vec3 size of player bounding box
var bBoxSize : Vector3 = bBox.shape.size
##State variable that shows that player was snapped to groun in last frame, aka should be grounded
var crouchingStateLastFrame : bool = false
#endregion

#region built-in functions
func _ready() -> void:
	setupCrouching()
	setUpCastsStepCheck()
	
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("crouch"):
		wishCrouch = true
	elif !Input.is_action_pressed("crouch"):
		wishCrouch = false
	wishR = Input.is_action_pressed("right")
	wishL = Input.is_action_pressed("left")
	wishF = Input.is_action_pressed("forward")
	wishB = Input.is_action_pressed("back")
	if Input.is_action_just_pressed("jump"):
		wishJump = true
	elif !Input.is_action_pressed("jump"):
		wishJump = false
	if Input.is_key_pressed(KEY_F1): Engine.time_scale = 0.1;
	if Input.is_key_pressed(KEY_F2): Engine.time_scale = 1.0;

func _physics_process(delta):
	processMovement(delta)
	#TODO: Move to hud component later.
	var text_comp = "Velocity: [color=#f00]x: " + str(snapped(P.get_velocity().x * 100 / 1.905, .01)) + " [color=#0f0]y: " + str(snapped(P.get_velocity().y * 100 / 1.905, .01)) + " [color=#00f]z: " + str(snapped(P.get_velocity().z * 100 / 1.905, .01)) + "[color=#fff] -- Speed: " + str(snapped((P.get_velocity() * Vector3(1,0,1)).length() * 100 / 1.905, .01)) + " HU/s"
	text_comp += "\nPosition: [color=#f00]x: " + str(snapped(P.global_position.x / 1.905 * 100, 0.01)) + " [color=#0f0]y: " + str(snapped(P.global_position.y / 1.905 * 100, 0.01)) + " [color=#00f]z: " + str(-snapped(P.global_position.z / 1.905 * 100, 0.01)) + "[color=#fff]"
	text_comp += "\nAngle: [color=#f00]x: " + str(-snapped(rad_to_deg(camComp.getCamRot().x), 0.01)) + " [color=#0f0]y: " + str(snapped(fmod((rad_to_deg(camComp.getCamRot().y) + 270), 360.0) - 180.0, 0.01)) + " [color=#00f]z: " + str(snapped(rad_to_deg(camComp.getCamRot().z), 0.01)) + "[color=#fff]"
	%showpos.text = text_comp
#endregion

#region Main movement processor
## PURPOSE: combines all other movement altering methods and overwrites velocity of a parent. Follows Source Engine like physics frame update order.[br]
## To see full frame order look into [color=#4040ff][url=https://www.dropbox.com/scl/fi/c0vxjztou9xj0of1zamer/Review.pdf?rlkey=rv9l35ze3uvhbk5llnwl1ld0k&e=2&dl=0]this document[/url][/color], Page 5 Section 2.2.2 Player tick by [color=#4040ff][url=https://steamcommunity.com/id/ildprut]Ildprut[/url][/color] 
func processMovement(delta) -> void:
	#step 0: get current velocity
	var newVel : Vector3 = P.get_velocity()
	#step 1: become airborne if moving up too fast
	if newVel.y >= upwardVelocityGate: grounded = false
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
	if grounded and !justJumped:
		newVel = applyFriction(newVel, delta)
		newVel.y = 0.0
	#step 7: apply acceleration
	newVel = applyAcceleration(newVel, delta)
	#step 8: Move and collide
	if P.is_on_wall():
		newVel = clipVel(newVel,P.get_wall_normal())
	if P.is_on_floor() and newVel.length() > (groundMaxSpeed + 0.01):
		newVel = clipVel(newVel,P.get_floor_normal())
	#step 9: Check for ground to stand on.
	grounded = checkGrounded(newVel)
	#step 10: Apply second half of gravity 
	if !grounded: newVel.y -= gravity / 2 * delta
	#step 11: Check grounded and if so set vertical velocity to 0
	if grounded and !justJumped:
		newVel.y = 0.0
	#step 12: Limit max velocity. Implemented to nerf bunny hopping in a week since TF2s release.
	#Some games may benefit from bunny hopping but when heavy comes up to you with mach 5 speed, reved up and balsting your ass in 1 second... Nah...
	if grounded and limitMaxVel:
		if (newVel * Vector3(1,0,1)).length() > groundMaxSpeed * limitMaxVelAmount:
			newVel = ((newVel * Vector3(1,0,1)).normalized() * groundMaxSpeed * limitMaxVelAmount) + Vector3(0,newVel.y,0)
	#step 13.1 Move and slide player here instaed of source engine table
	newVel += stackedKnockback
	stackedKnockback = Vector3.ZERO
	P.velocity = newVel
	if !stepUpCheck(delta, newVel):
		stepDownCheck()
		P.move_and_slide()
	justJumped = false
	#step 13.2: Handle triggers collision - If hame has invisible triggers(like doors opening in tf2 this step is for checking the collision shapes with areas3D)
	#step 14: Update bounding box- !NOT NEEDED FOR ANYTHING ELSE BUT SERVER CLIENT STRUCTURE! 
	#step 15: Handle projectiles
#endregion

#region grounded check
## PURPOSE: Update player grounded state. If player is on floor and not moving up too fast function returns True
func checkGrounded(vel: Vector3) -> bool:
	return ((P.is_on_floor()) and (vel.y <= upwardVelocityGate)) or snappedToStairsLastFrame
#endregion

#region friction
## PURPOSE: returns velocity affected by ground friction
func applyFriction(vel, delta) -> Vector3:
	#if waterMove: return
	var speed = vel.length()
	var drop = 0
	if speed < 0.001905: return Vector3.ZERO
	if speed != 0.0:
		var control = max(groundSpeedCutOff, speed)
		drop = control * 4 * 0.8 * delta
	var newSpeed = speed - drop
	if newSpeed < 0 :
		newSpeed = 0
	if newSpeed != speed:
		newSpeed /= speed 
		vel *= newSpeed
	vel -= (1.0 - newSpeed) * vel
	return vel 
#endregion

#TODO: Rename to player move for clarity
#region acceleration
## PURPOSE: return modified velocity after accelerating
func applyAcceleration(vel, delta) -> Vector3:
	getWishDir()
	if grounded:
		vel = accelGround(vel, delta)
	else:
		vel = airMove(vel, delta)
	return vel
#endregion

#region ground movement
#right is negative X, left is positive
#back is negative Y, forward is positive
## PURPOSE: interprets user input
var prevInputs := {"R":wishR,"L":wishL,"F":wishF,"B":wishB,}
func getWishDir() -> void:
	if P.uiFocused: wDir = Vector2.ZERO;return
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
	if wDir == Vector2(0, -1):
		mult *= 0.9
	return mult
#endregion

#region air move
func airMove(vel: Vector3, delta: float) -> Vector3:
	var wishVel = Vector3(wDir.x,0,wDir.y).rotated(Vector3.UP, camComp.lookDir.y)
	var wishDir = wishVel
	var wishSpeed = wishDir.length()
	wishDir = wishDir.normalized()
	#clamp to defined movespeed variable
	if wishSpeed != 0 and (wishSpeed > 320 * 1.905 / 100):
		wishVel *= 320 * 1.905 / 100 / wishSpeed
		wishSpeed = 320 * 1.905 / 100
	vel = accelAir(vel, wishDir, wishSpeed, 10, delta)
	return vel

func accelAir(vel: Vector3, dir: Vector3, wSpeed: float, accel: float, delta: float) -> Vector3:
	wSpeed = min(wSpeed, airMaxSpeed)
	var currSpeed = vel.dot(dir)
	var addSpeed = wSpeed - currSpeed
	if addSpeed <= 0 : return vel
	var accelSpeed = accel * 320 * 1.905 / 100 * delta
	accelSpeed = min(accelSpeed, addSpeed)
	vel += accelSpeed * dir
	return vel
#endregion

#region jumping
func handleJump(vel) -> Vector3:
	if !grounded and wishJump and !bHopCheat:
		wishJump = false
		return vel
	if wishJump and grounded and !crouched:
		if !bHopCheat: wishJump = false
		justJumped = true
		if crouching:
			crouchJump()
			if crouchJumpBug: vel.y = jumpPower
			else: vel.y = jumpPower - (gravity / Engine.get_physics_ticks_per_second() / 2)
		elif uncrouching:
			if cTapEnabled:
				vel = cTap(vel)
			else:
				vel.y = jumpPower - (gravity / Engine.get_physics_ticks_per_second() / 2)
		else:
			vel.y = jumpPower - (gravity / Engine.get_physics_ticks_per_second() / 2)
		if limitMaxVel:
			if (vel * Vector3(1,0,1)).length() > groundMaxSpeed * limitMaxVelAmount:
				vel = ((vel * Vector3(1,0,1)).normalized() * groundMaxSpeed * limitMaxVelAmount) + Vector3(0,vel.y,0)
		return vel
	return vel
#endregion

#region crouching
func setupCrouching() -> void:
	crouchTimer.wait_time          = crouchingAnimationTime
	uncrouchTimer.wait_time        = crouchingAnimationTime
	uncrouchCheckTop.position.y    = bBoxHeightCrouched + (bBoxSize.y - bBoxHeightCrouched) / 2
	uncrouchCheckBottom.position.y = (bBoxSize.y - bBoxHeightCrouched) / -2
	uncrouchCheckTop.shape.size    = Vector3(bBoxSize.x,bBoxSize.y - bBoxHeightCrouched,bBoxSize.z)
	uncrouchCheckBottom.shape.size = Vector3(bBoxSize.x,bBoxSize.y - bBoxHeightCrouched,bBoxSize.z)
	uncrouchCheckTop.add_exception(P)
	uncrouchCheckBottom.add_exception(P)

func handleCrouching() -> void:
	if crouched and !wishCrouch:
		queueUncrouching = true
	if queueUncrouching:
		if tryUncrouch():
			queueUncrouching = false
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

func cTap(vel: Vector3) -> Vector3:
	crouchTimer.stop()
	uncrouchTimer.stop()
	crouched = true
	crouching = false
	uncrouching = false
	bBox.shape.size.y = bBoxHeightCrouched
	bBox.position.y = bBoxHeightCrouched / 2
	camComp.crouch()
	queueUncrouching = true
	return Vector3(vel.x, jumpPower - (gravity / Engine.get_physics_ticks_per_second() / 2), vel.z)
#endregion

#region velocity clip
##----------------------------------------[br]
##[b][u]PURPOSE[/u][/b]:[br] Method that alignes velocity along surface that allows for sliding along it. Leads to several bugs in source engine that define expressive movement. Among most importanat ones are "rampsliding" and "surfing"[br]
##[b][u]ARGS[/u][/b]:[br] vel - [Vector3] - incoming velocity[br] n - [Vector3] - surface normal[br] overbounce - [float] - [color=gold]NULLABLE[/color] - multiplier of pushback force. In source engine games controlled with "sv_bounce" cheat[br]
##[b][u]RETURN[/u][/b]:[br] [Vector3] - velocity aligned along the surface
##[br]----------------------------------------
func clipVel(vel: Vector3, n: Vector3, overbounce : float = 1.0) -> Vector3:
	#get modified velocity
	var pushBack := vel.dot(n)
	#if negative - cancell
	if pushBack >= 0: return vel
	#get reflected velocity component
	var change := n * pushBack * overbounce
	#modify and return velocity
	return vel - change
#endregion
#region step up/down logic. Honestly some sort of black magic with testing motion before doing it... 
# -- In general its good if game can get by without step up or down. Its all tested over the years
# -- and turns our sidden shot elevation changes and movement shooters do not mix well. use ramps instead.
##----------------------------------------[br]
##[b][u]PURPOSE[/u][/b]:[br] Method executed in [method _ready]. Sets up transforms of step up raycast and stepdown shapecast
##[br]----------------------------------------
func setUpCastsStepCheck() -> void:
	#making step down ShapeCast3D same saze as player bounding box and height of max step up length
	$stepDownShapeCast.shape.size = Vector3(bBoxSize.x, maxStepUp, bBoxSize.z)
	#positioning step down ShapeCast3D at the bottom of player bounding box
	$stepDownShapeCast.position = Vector3(0, maxStepUp + 0.01/ -2, 0)
	#making step up RayCast3d length be max step up length
	$stepUpRayCast.target_position.y = -(maxStepUp)
##----------------------------------------[br]
##[b][u]PURPOSE[/u][/b]:[br] Checks if wall is at walkable angle to be able to step up onto it[br]
##[b][u]ARGS[/u][/b]:[br] n - [Vector3] - normal of the wall
##[br]----------------------------------------
func isWallTooSteep(n: Vector3) -> bool:
	#testing if surface angle is more than max walkable surface angle
	return n.angle_to(Vector3.UP) > P.floor_max_angle
##----------------------------------------[br]
##[b][u]PURPOSE[/u][/b]:[br] Snaps player to ground upon walking off ledges shorter than max step up length
##[br]----------------------------------------
func stepDownCheck() -> void:
	#reset state of stepping down
	var steppedDown := bool(false)
	#determine if player was on floor in last frame or current frame
	var wasOnFloorLastFrame := bool(Engine.get_physics_frames() - lastFloored <= 1)
	#see if ground below is close enough and wlkable to be stepped down
	var isGroundBelow := bool($stepDownShapeCast.is_colliding() and !isWallTooSteep($stepDownShapeCast.get_collision_normal(0)))
	#if airborne and was grounded last frame and intending to jump: true -> step down , false -> update last frame grounded
	if !grounded and (steppedDown or wasOnFloorLastFrame) and !wishJump and P.velocity.y <= 0.1:
		#create new physics server test object
		var motionTestResult = PhysicsTestMotionResult3D.new()
		#ask physics server testmotion if player can conplete step down movement and if there is ground to step down to
		if testMotion(P.global_transform, Vector3(0,-maxStepUp,0), motionTestResult) and isGroundBelow:
			#call camera smoothing method from [PlayerCameraComponent]
			camComp.saveCamPos()
			#get travel distance from motion test
			var translateY = motionTestResult.get_travel().y
			#tp player down
			P.position.y += translateY
			#align player to floor, just in case
			P.apply_floor_snap()
			#stepdown success
			steppedDown = true
	#Update if player was snapped to ground with state of the method
	snappedToStairsLastFrame = steppedDown
##----------------------------------------[br]
##[b][u]PURPOSE[/u][/b]:[br] Moves player up if ledge height within step up length margin.[br][b][color=gold]!!IMPORTANT!! THIS METHOD MOVES PLAYER!
##EXECUTING [method CharacterBody3D.move_and_slide] WILL RESULT IN ERRONIOS DOUBLE MOVEMENT![/color][br]
##[b][u]ARGS[/u][/b]:[br] delta - [float] - delta time of last physics frame[br] newVel - [Vector3] - currently modifiable parent [CharacterBody3D] velocity[br]
##[b][u]RETURN[/u][/b]:[br] [bool] - returns if step up was successful. Use this return to prevent double movent with [method CharacterBody3D.move_and_slide]
##[br]----------------------------------------
func stepUpCheck(delta: float, newVel: Vector3) -> bool:
	#if player is not grounded and wasnt snapped to floor: cancell
	if !grounded and !snappedToStairsLastFrame: return false
	#if moving up or not moving horizontally: cancell
	if newVel.y > 0 or (newVel * Vector3(1,0,1)).length() == 0: return false
	#project next motion using delta and current velocity
	var expectedMotion = newVel * Vector3(1,0,1) * delta
	#Predict next motion with step up in mind
	var step_pos_with_clearance = P.global_transform.translated(expectedMotion + Vector3(0, maxStepUp * 2, 0))
	#new physics collision check instance
	var down_check_result = KinematicCollision3D.new()
	#test if player can fit in desegnated place and ground is either StaticBody3D or god forbid CSGShape3D. I guess rn you couldnt step up other players...
	if (P.test_move(step_pos_with_clearance, Vector3(0,-maxStepUp*2,0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		#determine travel distance
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - P.global_position).y
		#if travel distance is invalid: cancell
		if step_height > maxStepUp or step_height <= 0.01 or (down_check_result.get_position() - P.global_position).y > maxStepUp: return false
		#move raycast to the predicted motion destination
		$stepUpRayCast.global_position = down_check_result.get_position() + Vector3(0,maxStepUp,0) + expectedMotion.normalized() * 0.1
		#update raycast
		$stepUpRayCast.force_raycast_update()
		#check if step up spot is valid
		if $stepUpRayCast.is_colliding() and not isWallTooSteep($stepUpRayCast.get_collision_normal()):
			#call camera smoothing method from [PlayerCameraComponent]
			camComp.saveCamPos()
			#move player up the ledge
			P.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			#align with the floor
			P.apply_floor_snap()
			#update state
			snappedToStairsLastFrame = true
			#on success send true which will cancell out move_and_slide
			return true
	#in case of fail just pass the method
	return false
##----------------------------------------[br]
##[b][u]PURPOSE[/u][/b]:[br] Perfoms a test motion of Player parent with [method PhysicsServer3D.body_test_motion][br]
##[b][u]ARGS[/u][/b]:[br] from - [Transform3D] - original body transform[br] motion - [Vector3D] - test motion destination[br] result - [PhysicsTestMotionResult3D] - [color=gold]NULLABLE[/color] - Describes the motion and collision result[br]
##[b][u]RETURN[/u][/b]:[br] [bool] - returns if motion was successful 
##[br]----------------------------------------
func testMotion(from: Transform3D, motion: Vector3, result : PhysicsTestMotionResult3D = null) -> bool:
	#if result is null instance new one
	if !result: result = PhysicsTestMotionResult3D.new()
	#instance new physcs motion params
	var params = PhysicsTestMotionParameters3D.new()
	#define motion in prams
	params.from = from
	params.motion = motion
	#test motion
	return PhysicsServer3D.body_test_motion(P.get_rid(), params, result)
#endregion
#region applyImpulse(dir: Vector3, amt: float) -> void
##----------------------------------------[br]
## [u][b]PURPOSE[/u][/b]:[br] Adds knockback Vector3 impulses to be processed inside [method processMovement] at step 13[br]
## [u][b]ARGS[/u][/b]:[br] dir - [Vector3] - direction of knockback[br] amt - [float] - multiplier of dir
##[br]----------------------------------------
func applyImpulse(dir: Vector3, amt: float) -> void:
	stackedKnockback += dir * amt
#endregion