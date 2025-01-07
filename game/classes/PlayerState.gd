class_name PlayerState
extends Node

var id := int(0);
var ducked := bool(false);
var grounded := bool(false);
var position := Vector3.ZERO;
var rotation := Vector3.ZERO; ##Contrary to usual stuff parent object of player has constant rotation. This variable used to store player view rotation
var scale := Vector3(1.0,1.0,1.0);
var velocity := Vector3.ZERO;




