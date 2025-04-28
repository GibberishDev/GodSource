extends Node

func _ready() -> void:
	var commands_array: Array = [
		"bind mouse1 +fire",
		"bind w +forward",
		"bind s +backward",
		"bind a +left",
		"bind d +right",
		"bind space +jump",
		"bind ctrl +crouch",
	]
	
	for element: String in commands_array:
		var commands: Array = GSConsole.parse_commands_line_input(element.strip_edges())
		for command: String in commands:
			GSConsole.init_command(command)
