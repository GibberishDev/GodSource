@tool
class_name GSEquipmentComponent extends Node

@export_range(0,10,1,"or_greater")
var max_slots : int = 3;
@export
var allow_selecting_empty : bool = false;

var inventory : Array = []
var slots : Array = []