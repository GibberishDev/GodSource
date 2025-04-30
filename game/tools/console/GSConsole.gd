extends Window

class_name Console

signal console_opened
signal console_closed
signal console_unknown_command

@export var input: LineEdit
@export var output: RichTextLabel
@export var hints_menu: Window

var console_commands: Dictionary = {}
var console_alias_commands: Dictionary = {}
var console_history: Array = []
var console_history_index: int = 0

var enabled: bool = true

enum PrintTo {
	Godot,
	Console,
	Both
}

class ConsoleCommand:
	var function: Callable
	var arguments: PackedStringArray
	var required: int
	var infinite_arguments: bool

	func _init(in_function: Callable, in_arguments: PackedStringArray, in_required: int = 0, in_infinite_arguments: bool = false) -> void:
		function = in_function
		arguments = in_arguments
		required = in_required
		infinite_arguments = in_infinite_arguments

func _ready() -> void:
	add_command("echo", command_echo, -1, 1)
	add_command("clear", command_clear, 0)
	add_command("quit", command_quit, 0)
	add_command("map", command_map, 1, 1)
	add_command("exec", command_exec, 1, 1)
	add_command("disconnect", command_disconnect, 0, 0)
	add_command("alias", command_alias, -1, 2)

#region Console Code

func _on_close_pressed() -> void:
	toggle_console()

func _input(event: InputEvent) -> void:
	if (event is InputEventKey):
		if (event.is_action("console") and event.pressed):
			if (event.pressed):
				if GSGlobal.mouse_captured:
					GSGlobal.release_pointer()
				toggle_console()
		if (visible and event.pressed):
			if (event.keycode == KEY_DOWN):
				if (console_history_index < console_history.size()):
					console_history_index += 1
					if (console_history_index < console_history.size()):
						input.text = console_history[console_history_index]
						input.caret_column = console_history[console_history_index].length()
					else:
						input.text = ""
					input.grab_focus()
			if (event.keycode == KEY_UP):
				if (console_history_index > 0):
					console_history_index -= 1
					if (console_history_index >= 0):
						input.text = console_history[console_history_index]
						input.caret_column = console_history[console_history_index].length()
					else:
						input.text = ""
					input.grab_focus()

func _on_console_opened() -> void:
	input.grab_focus()

func escape_bbcode(bbcode_text: String) -> String:
	return bbcode_text.replace("[", "[lb]")

func disable() -> void:
	enabled = false
	toggle_console()

func enable() -> void:
	enabled = true

func toggle_console() -> void:
	if (enabled):
		visible = (!visible)
	else:
		visible = false

	if (visible):
		console_opened.emit()
	else:
		console_closed.emit()

func print_line(text: Variant, where: PrintTo) -> void:
	match where:
		PrintTo.Godot:
			print(str(text))
		PrintTo.Console:
			output.append_text(str(text))
			output.append_text("\n")
		PrintTo.Both:
			print(str(text))
			output.append_text(str(text))
			output.append_text("\n")

func parse_line_input(text: String) -> PackedStringArray:
	var out_array: PackedStringArray
	var in_quotes: bool = false
	var escaped: bool = false
	var token: String

	for c: String in text:
		if (c == '\\'):
			escaped = true
			continue
		elif escaped:
			if (c == 'n'):
				c = '\n'
			elif (c == 't'):
				c = '\t'
			elif (c == 'r'):
				c = '\r'
			elif (c == 'a'):
				c = '\a'
			elif (c == 'b'):
				c = '\b'
			elif (c == 'f'):
				c = '\f'

			escaped = false

		elif (c == '\"' or c == "\'"):
			in_quotes = !in_quotes
			continue

		elif (c == ' ' || c == '\t'):
			if (!in_quotes):
				out_array.push_back(token)
				token = ""
				continue

		token += c

	out_array.push_back(token)

	return out_array

func parse_commands_line_input(text: String) -> PackedStringArray:
	var out_array: PackedStringArray
	var in_quotes: bool = false
	var escaped: bool = false
	var token: String = ""
	var command_buffer: String = ""

	for c: String in text:
		if escaped:
			token += c
			escaped = false
			continue

		if c == "\\":
			escaped = true
			continue

		if c == "\"" || c == "'":
			in_quotes = !in_quotes
			token += c
			continue

		if c == ";" && !in_quotes:
			# Завершаем текущую команду
			command_buffer += token.strip_edges()
			if !command_buffer.is_empty():
				out_array.push_back(command_buffer)
			command_buffer = ""
			token = ""
			continue

		token += c

	command_buffer += token.strip_edges()
	if !command_buffer.is_empty():
		out_array.push_back(command_buffer)

	return out_array

func add_command(command_name: String, function: Callable, arguments: int = 0, required: int = 0) -> void:
	if arguments != -1:
		var param_array: PackedStringArray
		for i: int in range(arguments):
			param_array.append("arg_" + str(i + 1))
		console_commands[command_name] = ConsoleCommand.new(function, param_array, required, false)
	else:
		console_commands[command_name] = ConsoleCommand.new(function, PackedStringArray(), required, true)

func has_command(command_name: String) -> bool:
	if not console_commands.has(command_name):
		return false

	return true

func add_input_history(text: String) -> void:
	if (!console_history.size() || text != console_history.back()):
		console_history.append(text)
	console_history_index = console_history.size()

func on_text_entered(user_text: String) -> void:
	input.clear()

	add_input_history(user_text)
	print_line("[color=#b9b9b9]] " + escape_bbcode(user_text.strip_edges()) + "[/color]", PrintTo.Console)

	var commands: Array = parse_commands_line_input(user_text.strip_edges())
	for command: String in commands:
		init_command(command)

	get_tree().get_root().set_input_as_handled()

func on_input_button_entered() -> void:
	on_text_entered(input.text)
	input.grab_focus()

func init_command(command: String) -> void:
	var text_split: PackedStringArray = parse_line_input(command.strip_edges())
	var text_command: String = text_split[0]

	if text_command != "":
		if console_commands.has(text_command):
			init_command_from_console_commands(text_command, text_split)
		elif console_alias_commands.has(text_command):
			var alias_commands: PackedStringArray = console_alias_commands[text_command].get_commands()

			for alias_command: String in alias_commands:
				var alias_text_split: PackedStringArray = parse_line_input(alias_command.strip_edges())
				var alias_text_command: String = alias_text_split[0]

				if console_commands.has(alias_text_command):
					init_command_from_console_commands(alias_text_command, alias_text_split)
				elif console_alias_commands.has(alias_text_command):
					init_command(alias_command)
				else:
					console_unknown_command.emit(text_command)
					print_line_format("", "", 'Unknown command: "%s"' % [text_command], "white", PrintTo.Console)
					print_line_format("Error", "Console", 'Unknown command: "%s"' % [text_command], "red", PrintTo.Godot)
		else:
			console_unknown_command.emit(text_command)
			print_line_format("", "", 'Unknown command: "%s"' % [text_command], "white", PrintTo.Console)
			print_line_format("Error", "Console", 'Unknown command: "%s"' % [text_command], "red", PrintTo.Godot)

func init_command_from_console_commands(text_command: String, text_split: PackedStringArray) -> void:
	var arguments: Array = text_split.slice(1)

	if console_commands[text_command].infinite_arguments:
		if arguments.size() < console_commands[text_command].required:
			print_line_format("", "", "Too few arguments. ( Required %d )" % console_commands[text_command].required, "white", PrintTo.Console)
			print_line_format("Error", "Console", "Too few arguments. ( Required %d )" % console_commands[text_command].required, "red", PrintTo.Godot)
			return
	else:
		if arguments.size() < console_commands[text_command].required:
			print_line_format("", "", "Too few arguments. ( Required %d )" % console_commands[text_command].required, "white", PrintTo.Console)
			print_line_format("Error", "Console", "Too few arguments. ( Required %d )" % console_commands[text_command].required, "red", PrintTo.Godot)
			return
		elif arguments.size() > console_commands[text_command].arguments.size():
			print_line_format("", "", "Too many arguments. ( Expected %d )" % console_commands[text_command].arguments.size(), "white", PrintTo.Console)
			print_line_format("Error", "Console", "Too many arguments. ( Expected %d )" % console_commands[text_command].arguments.size(), "white", PrintTo.Godot)
			return
		while arguments.size() < console_commands[text_command].arguments.size():
			arguments.append("")

	console_commands[text_command].function.call(arguments)

func print_line_format(type: String, category: String, text: String, color: String, where: PrintTo) -> void:
	match where:
		PrintTo.Godot:
			print_rich("[color=%s]%s%s%s[/color]" % [color, ("[b]" + type + ":[/b] ") if type != "" else "", (category + " | ") if category != "" else "", text])
		PrintTo.Console:
			print_line("[color=%s]%s%s%s[/color]" % [color, ("[b]" + type + ":[/b] ") if type != "" else "", (category + " | ") if category != "" else "", text], PrintTo.Console)
		PrintTo.Both:
			print_rich("[color=%s]%s%s%s[/color]" % [color, ("[b]" + type + ":[/b] ") if type != "" else "", (category + " | ") if category != "" else "", text])
			print_line("[color=%s]%s%s%s[/color]" % [color, ("[b]" + type + ":[/b] ") if type != "" else "", (category + " | ") if category != "" else "", text], PrintTo.Console)

#endregion

#region Commands

func command_echo(arguments: Array) -> void:
	print_line(" ".join(arguments), PrintTo.Console)

func command_quit(_arguments: Array) -> void:
	get_tree().quit()

func command_clear(_arguments: Array) -> void:
	output.clear()

# TODO: change it for local/online servers
func command_map(arguments: Array) -> void:
	var map_name: String = arguments[0]
	var map_exists: bool = FileAccess.file_exists("res://assets/maps/%s.tscn" % [map_name])
	var map_name_path: String = "res://assets/maps/%s.tscn" % [map_name]

	if map_exists:
		var packed_map_scene: PackedScene = load(map_name_path)
		var map: Node3D = packed_map_scene.instantiate()
		var packed_player_scene: PackedScene = load("res://game/scenes/entities/GSPlayer.tscn")
		var player: Node3D = packed_player_scene.instantiate()

		for child: Node in get_tree().get_root().get_node("Root Scene").get_node("Game").get_node("Map").get_node("Map Scene").get_children():
			child.queue_free()

		for child: Node in get_tree().get_root().get_node("Root Scene").get_node("Game").get_node("Map").get_node("Players").get_children():
			child.queue_free()

		get_tree().get_root().get_node("Root Scene").get_node("Menu").hide_menu()
		get_tree().get_root().get_node("Root Scene").get_node("Game").get_node("Map").get_node("Map Scene").add_child(map)
		get_tree().get_root().get_node("Root Scene").get_node("Game").get_node("Map").get_node("Players").add_child(player)
		GSGlobal.grab_pointer()

		if (visible):
			toggle_console()
	else:
		print_line("Map %s does not exist." % [map_name])

# TODO: change it for local/online servers
func command_disconnect(_arguments: Array) -> void:
	if GSGlobal.menu.on_map:
		for child: Node in get_tree().get_root().get_node("Root Scene").get_node("Game").get_node("Map").get_node("Map Scene").get_children():
			child.queue_free()

		for child: Node in get_tree().get_root().get_node("Root Scene").get_node("Game").get_node("Map").get_node("Players").get_children():
			child.queue_free()

		GSGlobal.release_pointer()

func command_exec(arguments: Array) -> void:
	var filename: String = arguments[0]
	if filename.ends_with(".cfg"):
		filename = filename.substr(0, filename.length() - 4)

	var file: FileAccess = FileAccess.open(("user://cfg/" + filename + ".cfg"), FileAccess.READ)

	if file:
		var lines: Array = []
		while not file.eof_reached():
			var line: String = file.get_line()
			if line:
				lines.append(line)
		file.close()

		for line: String in lines:
			init_command(line)
	else:
		print_line("The file does not exist.")

func command_alias(arguments: Array) -> void:
	var alias_name: String = arguments[0]
	var alias_value: Array = arguments.slice(1, arguments.size())

	if !console_commands.has(alias_name):
		var new_alias: GSAlias = GSAlias.new(alias_name, " ".join(alias_value))
		console_alias_commands[alias_name] = new_alias

#endregion
