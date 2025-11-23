extends Node

func _ready() -> void:
	_register_console_commands()

func _register_console_commands() -> void:
	GSConsole.add_command("help", help_command_callable, -1, "Show usage of provided command or if none provided print full list of registered commands.\n	Syntax: help <command name>\n	Is cheat: false - Is admin only: false")
	GSConsole.add_command("echo", echo_command_callable, -1, "Prints suppled text in console output\n	Syntax: echo <text...>\n	Is cheat: false - Is admin only: false")
	GSConsole.add_command("clear", clear_command_callable, -1, "Clears console\n	Syntax: clear\n	Is cheat: false - Is admin only: false")
	GSConsole.add_command("quit", quit_command_callable, -1, "Shutdowns the aplication\n	Syntax: quit\n	Is cheat: false - Is admin only: false")
	# GSConsole.add_command("connect", connect_command_callable, -1, "Connect to a server\n   Syntax: connect <ip:port> <password>\n	Is cheat: false - Is admin only: false")
	# GSConsole.add_command("start_server", false, -1, "Start erver at local ip with a port and number of avaliable connections\n   Syntax: create_server <port> <player limit>\n	Is cheat: false - Is admin only: false")
	GSConsole.add_command("toggle_console", toggle_console_ui_callable, -1, "Show/hide console window\n   Syntax: toggle_console\n	Is cheat: false - Is admin only: false", [GSInput.INPUT_CONTEXT.UI, GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("alias", alias_command_callable, -1, "Asign alias to list of commands\n   Syntax: alias [alias name] \"[commands]\"\n	Is cheat: false - Is admin only: false", [])
	GSConsole.add_command("remove_alias", remove_alias_command_callable, -1, "Remove alias\n   Syntax: remove_alias [alias name] \n	Is cheat: false - Is admin only: false", [])
	
	GSConsole.add_command("+left", enable_wish_left, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-left", disable_wish_left, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("+right", enable_wish_right, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-right", disable_wish_right, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("+forward", enable_wish_forward, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-forward", disable_wish_forward, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("+back", enable_wish_back, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-back", disable_wish_back, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("+crouch", enable_wish_crouch, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-crouch", disable_wish_crouch, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("+jump", enable_wish_jump, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-jump", disable_wish_jump, -1, "", [GSInput.INPUT_CONTEXT.CHARACTER])

#region command callables


func help_command_callable(arguments_array: Array = []) -> void:
	var output_text: String = ""

	if arguments_array.size() == 0:
		output_text += ("All avaliable commands are:" + GSConsole.get_all_commands())
		GSConsole.send_output_message(output_text)

		return 

	for i : int in range(arguments_array.size()):
		var command_name : String = arguments_array[i]

		if  GSConsole.command_list.get(command_name) == null:
			output_text += ("\n] [color=pink]command not found: [/color][color=red][b]" + command_name + "[/b][/color]")
			output_text += ("\n] All avaliable commands are:" + GSConsole.get_all_commands())

			break

		var description: String = GSConsole.command_list[command_name].description

		output_text += ("\n] Help for [color=lime][b]" + str(command_name) + "[/b][/color] command:\n" + description)

	GSConsole.send_output_message(output_text)


func echo_command_callable(arguments_array: Array = []) -> void:
	var output_text : String = ""
	for i : int in range(arguments_array.size()):
		output_text += str(arguments_array[i]) + " "
	GSConsole.send_output_message(output_text)

func clear_command_callable(arguments_array: Array = []) -> void:
	var escape : String = PackedByteArray([0x1b]).get_string_from_ascii()
	if GSConsole.output_node != null:
		GSConsole.output_node.clear()
	printraw(escape + "[2J" + escape + "[;H")

func quit_command_callable(arguments_array: Array = []) -> void:
	GSConsole.send_output_message("Terminating application...")
	get_tree().quit(0)

# func connect_command_callable(arguments_array: Array = []) -> void:
# 	MultiplayerManager.connect_to_server.call_deferred("127.0.0.1", 8080)

# func start_server_command_callable(arguments_array: Array = []) -> void:
# 	MultiplayerManager.start_server.call_deferred(8080, 8)

func toggle_console_ui_callable(arguments_array: Array = []) -> void:
	if !GSUi.opened_windows.keys().has("console"):
		var console_scene : PackedScene = load("res://lib/client/console.tscn")
		GSUi.add_window(console_scene, Vector2(800,600), "GSConsole", "console")
		GSUi.show_ui()
	else:
		if GSUi.get_node("ui_windows").visible:
			if GSUi.focused_window != GSUi.opened_windows["console"] and GSUi.opened_windows["console"].visible:
				GSUi.focus_window("console")
			elif GSUi.focused_window == GSUi.opened_windows["console"]:
				GSUi.hide_window("console")
			else:
				GSUi.show_window("console")
		else:
			GSUi.show_window("console")
			GSUi.show_ui()
				
func alias_command_callable(arguments_array: Array = [])-> void:
	if arguments_array == []:
		var list : Array[GSConsole.Alias] = GSConsole.get_all_aliases()
		var alias_commands_string : String = ""
		for i : GSConsole.Alias in list:
			alias_commands_string += "\n" + i.id
		GSConsole.send_output_message("All currently defined aliases are:" + alias_commands_string)
	else:
		var alias_name : StringName = arguments_array[0]
		if GSConsole.command_list.keys().has(alias_name):
			GSConsole.send_output_message("[color=red]Cannot asign alias name [b]" + alias_name + "[/b]: registered command with same name found.[/color]")
			return
		if arguments_array.size() > 1:
			var command : String = arguments_array[1]
			GSConsole.add_alias(alias_name, command)
		else:
			if GSConsole.alias_list.keys().has(alias_name):
				GSConsole.send_output_message("Alias [b]" + alias_name + "[/b] has following command: \n" + GSConsole.alias_list[alias_name].command)
			else:
				GSConsole.send_output_message("Alias [b]" + alias_name + "[/b] not found")

func remove_alias_command_callable(arguments_array: Array = []) -> void:
	if arguments_array.size() > 0 and GSConsole.alias_list.keys().has(arguments_array[0]):
		GSConsole.alias_list.erase(arguments_array[0])
		GSConsole.send_output_message("Removed [b]" + arguments_array[0] + "[/b] alias")
			

#endregion

#region wish commands callables

func enable_wish_left(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_left"] = true
func disable_wish_left(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_left"] = false
func enable_wish_right(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_right"] = true
func disable_wish_right(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_right"] = false
func enable_wish_forward(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_forward"] = true
func disable_wish_forward(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_forward"] = false
func enable_wish_back(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_back"] = true
func disable_wish_back(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_back"] = false
func enable_wish_crouch(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_crouch"] = true
func disable_wish_crouch(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_crouch"] = false
func enable_wish_jump(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_jump"] = true
func disable_wish_jump(arguments_array: Array = []) -> void: GSInput.wish_sates["wish_jump"] = false

#endregion
