extends Node

func _ready() -> void:
	var commands_array: Array = [
		"echo [center]Source engine like console. All Based commands in complect. To see all available command, enter command all_commands[/center]",
		"echo ''",
		"bind mouse1 +fire",
		"bind w +forward",
		"bind s +back",
		"bind a +left",
		"bind d +right",
		"bind space +jump",
		"bind ctrl +duck",
		"bind tab echo 1"
	]

	for element: String in commands_array:
		var commands: Array = GSConsole.parse_commands_line_input(element.strip_edges())
		for command: String in commands:
			GSConsole.init_command(command)
