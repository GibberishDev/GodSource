class_name GSPlayerState
extends Node

var id: int = 0
var ducked: bool = false
var grounded: bool = false
var position: Vector3 = Vector3.ZERO
var look_direction: Vector3 = Vector3.ZERO
var scale: Vector3 = Vector3(1.0, 1.0, 1.0)
var velocity: Vector3 = Vector3.ZERO

enum WATER_LEVEL {
	NOT_IN_WATER, #not in water
	FEET, #standing in water but not submerged, regular walking rules apply. can be used to idk transmit electricity i guess
	WAIST, #in water waist high, watermove rules apply plus can extinguish players
	EYES #fully submerged. swimming and sinking
}

enum MOVE_TYPE {
	NOCLIP,
	WALK,
	SWIM,
	AIRBORNE,
	BLAST
}
