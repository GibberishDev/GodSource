class_name GSAlias extends Resource

#constructed variables
var alias_name: StringName = "" ##Name is an identificator of an alias. Aliases cannot have same name. If alias with the same name is being created it will override old one 
var alias_value: String = "" ##String of commands alias executes upon being called with auth access of the actor calling it

##Class constructor
func _init(_alias_name: StringName, _alias_value: String) -> void:
	self.alias_name = _alias_name
	self.alias_value = _alias_value

##Gets array of commands from unified string.
func get_commands() -> PackedStringArray:
	var commands_array: PackedStringArray = alias_value.split(";")

	for i: int in commands_array.size():
		commands_array[i] = commands_array[i].strip_edges()

	return commands_array
