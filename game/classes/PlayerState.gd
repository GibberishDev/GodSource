class_name GSPlayerState
extends Node

var id := int(0);
var ducked := bool(false);
var grounded := bool(false);
var position := Vector3.ZERO;
var lookDir := Vector3.ZERO;
var scale := Vector3(1.0,1.0,1.0);
var velocity := Vector3.ZERO;

enum WATER_LEVEL {
	WL_OUTSIDE, #not in water
	WL_FEET, #standing in water but not submerged, regular walking rules apply. can be used to idk transmit electricity i guess
	WL_WAIST, #in water waist high, watermove rules apply plus can extinguish players
	WL_EYES #fully submerged. swimming and sinking
}
