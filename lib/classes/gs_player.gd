class_name godsource_player_movement
extends CharacterBody3D

@export
var upward_velocity_threshhold : float = 4.7625 #250 hammer units a second

var gravity_multiplier : float = 1.0

var is_grounded : bool = false
var is_airborne : bool = false
var current_movement_type : MOVEMENT_TYPE = MOVEMENT_TYPE.AIRBORNE

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

	


func _physics_process(delta: float) -> void:
	process_movement(delta)
	pass

func process_movement(delta: float) -> void:
	#step 1: check if stuck and try to unstuck and move to step 14
	#IMPORTANT! unstuck check is complex and requires writing more complex system to mimic source engine stuck behavior.
	#refer to source sdk 2013 code here untill explained better. good luck ffs :tf:
	#https://github.com/ValveSoftware/source-sdk-2013/blob/68c8b82fdcb41b8ad5abde9fe1f0654254217b8e/src/game/shared/gamemovement.cpp#L3233
	if stuck_check_collider.is_colliding():
		try_unstuck()
	if !stuck_check_collider.is_colliding(): #
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
	pass

func try_unstuck() -> void:
	pass

func test_motion(from: Transform3D, motion: Vector3, motion_result : PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()) -> bool:
	var player_rid : RID = self.get_rid()
	var motion_paramters : PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
	motion_paramters.from = from
	motion_paramters.motion = motion
	return PhysicsServer3D.body_test_motion(player_rid, motion_paramters, motion_result)
