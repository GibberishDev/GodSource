extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$velocity_hu.text = "Velocity HU/S: x: " + str(snapped(GSUtils.to_hammer(owner.velocity.x),0.01)) + " y: " + str(snapped(GSUtils.to_hammer(owner.velocity.y),0.01)) + " z: " + str(snapped(GSUtils.to_hammer(owner.velocity.z),0.01))
	$jump_state.text = "Key pressed: " + str(GSInput.wish_sates["wish_jump"]) + " wish_jump: " + str(owner.wish_jump)
	$is_airborne.text = "Is airborne: " + str(owner.is_airborne) + " Is floored: " + str(owner.is_floored)
