@tool
class_name GSTrigger extends Area3D

@export
var size : Vector3 = Vector3(1.0,1.0,1.0) : set = set_size
@export
var type : StringName = "liquid"

func set_size(value: Vector3) -> void:
	self.get_node("coll").position = Vector3(0, value.y/2.0, 0)
	self.get_node("coll").shape.size = value
	self.get_node("mesh").position = Vector3(0, value.y/2.0, 0)
	self.get_node("mesh").mesh.size = value
	size = value
