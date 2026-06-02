@tool
extends Node
class_name GSOutlineComponent


class OutlineMesh:
	enum MESH_TYPE {
		OUTLINE_ONLY,
		TINT_ONLY,
		BOTH
	}

	var mesh : MeshInstance3D
	var type : MESH_TYPE

@export
var meshes : Dictionary = {}:
	set(val):
		if (val.size() > meshes.size()):
			for i:Variant in val:
				if !(i is OutlineMesh):
					print(i)
					# i = OutlineMesh.new()
					# i.mesh = null
					# i.type = OutlineMesh.MESH_TYPE.BOTH
		meshes = val;


@export
var outline : bool = false:
	set(val):
		outline = val;
		notify_property_list_changed();
@export_subgroup("Outline settings","outline_")
@export
var outline_automatic_toggle : OUTLINE_SHOW_CASE = 0:
	set(val):
		outline_automatic_toggle = val;
		notify_property_list_changed();
@export_range(0.0,100.0,0.01,"or_greater")
var outline_distance_minimum : float = 0.0; ## Minumum distance betwqeen player and object for outline to be visible
@export_range(0.0,100.0,0.01,"or_greater")
var outline_distance_maximum : float = 0.0; ## Maximum distance betwqeen player and object for outline to be visible. Set to 0 for no limit 
@export_range(0.0,360.0,0.01)
var outline_cone_of_vision : float = 5.0; ## Defines angle of the vision cone where outlines will be visible
@export
var outline_color : Color = Color(255,255,0); ## Defines color of the outline
@export_range(0.0,128.0,0.1,"or_greater")
var outline_width : float = 4.0; ## Defines width of the outline

enum MESH_TYPE {
	BASE,
	OUTLINE_ONLY,
	TINT_ONLY,
	OUTLINE_AND_TINT
}

enum OUTLINE_SHOW_CASE {
	NEVER, ##Outline is not automatically toggled
	ALWAYS, ##Outline is not automatically toggled. On by default
	PLAYER ##Outline visibility depends on player parameters
}

func _validate_property(property: Dictionary) -> void:
	if property.name.find("outline_",0) != -1 and outline == false:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "outline_distance_minimum" or\
	property.name == "outline_distance_maximum" or\
	property.name == "outline_cone_of_vision":
		if outline_automatic_toggle != OUTLINE_SHOW_CASE.PLAYER:
			property.usage = PROPERTY_USAGE_NONE
