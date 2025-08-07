extends Node

func _ready() -> void:
	_register_console_commands()

func _register_console_commands() -> void:
	Console.add_command("help", help_command_callable, false, false, -1, "Show usage of provided command or if none provided print full list of registered commands.\n	Syntax: help <command name>\n	Is cheat: false - Is admin only: false")
	Console.add_command("echo", echo_command_callable, false, false, -1, "Prints suppled text in console output\n	Syntax: echo <text...>\n	Is cheat: false - Is admin only: false")
	Console.add_command("clear", clear_command_callable, false, false, -1, "Clears console\n	Syntax: clear\n	Is cheat: false - Is admin only: false")
	Console.add_command("quit", quit_command_callable, false, false, -1, "Shutdowns the aplication\n	Syntax: quit\n	Is cheat: false - Is admin only: false")
	Console.add_command("connect", connect_command_callable, false, false, -1, "Connect to a server\n   Syntax: connect <ip:port> <password>\n	Is cheat: false - Is admin only: false")
	Console.add_command("start_server", start_server_command_callable, false, false, -1, "Start erver at local ip with a port and number of avaliable connections\n   Syntax: create_server <port> <player limit>\n	Is cheat: false - Is admin only: false")

#region command callables


func help_command_callable(command_name_array: Array = []) -> void:
	var output_text: String = ""

	if command_name_array.size() == 0:
		output_text += ("All avaliable commands are:" + Console.get_all_commands())
		Console.send_output_message(output_text)

		return

	for i : int in range(command_name_array.size()):
		var command_name : String = command_name_array[i]

		if  Console.command_list.get(command_name) == null:
			output_text += ("\n] [color=pink]command not found: [/color][color=red][b]" + command_name + "[/b][/color]")
			output_text += ("\n] All avaliable commands are:" + Console.get_all_commands())

			break

		var description: String = Console.command_list[command_name].description

		output_text += ("\n] Help for [color=lime][b]" + str(command_name) + "[/b][/color] command:\n" + description)

	Console.send_output_message(output_text)


func echo_command_callable(arguments_array: Array = []) -> void:
	var output_text : String = ""
	for i : int in range(arguments_array.size()):
		output_text += str(arguments_array[i]) + " "
	Console.send_output_message(output_text)

func clear_command_callable(arguments_array: Array = []) -> void:
	var escape : String = PackedByteArray([0x1b]).get_string_from_ascii()
	if Console.output_node != null:
		Console.output_node.clear()
	printraw(escape + "[2J" + escape + "[;H")

func quit_command_callable(arguments_array: Array = []) -> void:
	get_tree().quit(0)

func connect_command_callable(arguments_array: Array = []) -> void:
	MultiplayerManager.connect_to_server.call_deferred("127.0.0.1", 8080)

func start_server_command_callable(arguments_array: Array = []) -> void:
	MultiplayerManager.start_server.call_deferred(8080, 8)


#endregion
