extends Node

func _ready() -> void:
	_register_console_commands()

func _register_console_commands() -> void:
	GSConsole.add_command("help", help_command_callable, "Show usage of provided command or if none provided print full list of registered commands.\n	Syntax: help <command name>\n	Is cheat: false - Is admin only: false",[])
	GSConsole.add_command("echo", echo_command_callable, "Prints suppled text in console output\n	Syntax: echo <text...>\n	Is cheat: false - Is admin only: false",[])
	GSConsole.add_command("clear", clear_command_callable, "Clears console\n	Syntax: clear\n	Is cheat: false - Is admin only: false",[])
	GSConsole.add_command("quit", quit_command_callable, "Shutdowns the aplication\n	Syntax: quit\n	Is cheat: false - Is admin only: false",[])
	GSConsole.add_command("toggle_console", toggle_console_ui_callable, "Show/hide console window\n   Syntax: toggle_console\n	Is cheat: false - Is admin only: false", [GSInput.INPUT_CONTEXT.UI, GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("alias", alias_command_callable, "Asign alias to list of commands\n   Syntax: alias [alias name] \"[commands]\"\n	Is cheat: false - Is admin only: false", [])
	GSConsole.add_command("remove_alias", remove_alias_command_callable, "Remove alias\n   Syntax: remove_alias [alias name] \n	Is cheat: false - Is admin only: false", [])
	GSConsole.add_command("exec", exec_command_callable, "load and execute configuration file at path\n   Syntax: exec [path, relative to cfg folder] \n	Is cheat: false - Is admin only: false", [])
	GSConsole.add_command("bind", bind_command_callable, "attach a command to a key\n   Syntax: bind [key](optional) \"[command](optional)\" \n	Is cheat: false - Is admin only: false", [])
	GSConsole.add_command("unbind", unbind_command_callable, "attach a command to a key\n   Syntax: bind [key](optional) \"[command](optional)\" \n	Is cheat: false - Is admin only: false", [])
	GSConsole.add_command("unbindall", unbind_all_command_callable, "Unbind all keys\n   Syntax: unbindall \n	Is cheat: false - Is admin only: false", [])
	GSConsole.add_command("noclip", noclip_command_callable, "Toggles noclip movement\n   Syntax: noclip \n	Is cheat: true - Is admin only: false", [])
	# GSConsole.add_command("connect", connect_command_callable, "Connect to a server\n   Syntax: connect <ip:port> <password>\n	Is cheat: false - Is admin only: false")
	# GSConsole.add_command("start_server", connect_command_callable, "Start erver at local ip with a port and number of avaliable connections\n   Syntax: create_server <port> <player limit>\n	Is cheat: false - Is admin only: false")
	
	GSConsole.add_command("+left", enable_wish_left, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-left", disable_wish_left, "")
	GSConsole.add_command("+right", enable_wish_right, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-right", disable_wish_right, "")
	GSConsole.add_command("+forward", enable_wish_forward, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-forward", disable_wish_forward, "")
	GSConsole.add_command("+back", enable_wish_back, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-back", disable_wish_back, "")
	GSConsole.add_command("+crouch", enable_wish_crouch, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-crouch", disable_wish_crouch, "")
	GSConsole.add_command("+jump", enable_wish_jump, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-jump", disable_wish_jump, "")
	GSConsole.add_command("+attack", enable_wish_attack, "", [GSInput.INPUT_CONTEXT.CHARACTER])
	GSConsole.add_command("-attack", disable_wish_attack, "")

#region command callables


func help_command_callable(arguments_array: Array = []) -> bool:
	var output_text: String = ""

	if arguments_array.size() == 0:
		output_text = "All avaliable commands are:\n[color=yellow]█ - commands[/color],[color=lime] █ - convars[/color],[color=pink] █ - aliases[/color]\n[color=yellow]"
		var commands : PackedStringArray = GSConsole.command_list.keys()
		commands.sort()
		for i : StringName in commands:
			output_text += i + "\n"
		output_text += "[/color][color=lime]"
		var convars : PackedStringArray = GSConsole.convar_list.keys()
		convars.sort()
		for i : StringName in convars:
			output_text += i + "\n"
		output_text += "[/color][color=pink]"
		var aliases : PackedStringArray = GSConsole.alias_list.keys()
		aliases.sort()
		for i : StringName in aliases:
			output_text += i + "\n"
		output_text += "[/color]"
		GSConsole.send_output_message(output_text)

		return true

	for i : int in range(arguments_array.size()):
		var command_name : String = arguments_array[i]

		if  GSConsole.command_list.get(command_name) == null:
			output_text += ("\n] [color=pink]command not found: [/color][color=red][b]" + command_name + "[/b][/color]")
			output_text += ("\n] All avaliable commands are:" + GSConsole.get_all_commands())

			break

		var description: String = GSConsole.command_list[command_name].description

		output_text += ("\n] Help for [color=lime][b]" + str(command_name) + "[/b][/color] command:\n" + description)

	GSConsole.send_output_message(output_text)
	return true


func echo_command_callable(arguments_array: Array = []) -> bool:
	var output_text : String = ""
	for i : int in range(arguments_array.size()):
		output_text += str(arguments_array[i]) + " "
	GSConsole.send_output_message(output_text)
	return true

func clear_command_callable(arguments_array: Array = []) -> bool:
	var escape : String = PackedByteArray([0x1b]).get_string_from_ascii()
	if GSConsole.output_node != null:
		GSConsole.output_node.clear()
	printraw(escape + "[2J" + escape + "[;H")
	return true

func quit_command_callable(arguments_array: Array = []) -> bool:
	GSConsole.send_output_message("Terminating application...")
	get_tree().quit(0)
	return true #Lol

# func connect_command_callable(arguments_array: Array = []) -> bool:
# 	MultiplayerManager.connect_to_server.call_deferred("127.0.0.1", 8080)

# func start_server_command_callable(arguments_array: Array = []) -> bool:
# 	MultiplayerManager.start_server.call_deferred(8080, 8)

func toggle_console_ui_callable(arguments_array: Array = []) -> bool:
	if !GSUi.opened_windows.keys().has("console"):
		var console_scene : PackedScene = load("res://lib/client/console.tscn")
		GSUi.add_window(console_scene, Vector2(800,600), "GSConsole", "console")
		GSUi.show_ui()
		GSUi.opened_windows["console"].call_on_child(&"focus_input")
	else:
		if GSUi.get_node("ui_windows").visible:
			if GSUi.focused_window != GSUi.opened_windows["console"] and GSUi.opened_windows["console"].visible:
				GSUi.focus_window("console")
				GSUi.opened_windows["console"].call_on_child(&"focus_input")
			elif GSUi.focused_window == GSUi.opened_windows["console"]:
				GSUi.hide_window("console")
			else:
				GSUi.show_window("console")
				GSUi.opened_windows["console"].call_on_child(&"focus_input")
		else:
			GSUi.show_window("console")
			GSUi.show_ui()
			GSUi.opened_windows["console"].call_on_child(&"focus_input")
	return true
				
func alias_command_callable(arguments_array: Array = [])-> bool:
	if arguments_array == []:
		var list : Array[GSConsole.Alias] = GSConsole.get_all_aliases()
		var alias_commands_string : String = ""
		for i : GSConsole.Alias in list:
			alias_commands_string += "\n" + i.alias_name
		GSConsole.send_output_message("All currently defined aliases are:" + alias_commands_string)
	else:
		var alias_name : StringName = arguments_array[0]
		if GSConsole.command_list.keys().has(alias_name):
			GSConsole.send_output_message("[color=red]Cannot asign alias name [b]" + alias_name + "[/b]: registered command with same name found.[/color]")
			return false
		if arguments_array.size() > 1:
			var command : String = arguments_array[1]
			GSConsole.add_alias(alias_name, command)
		else:
			if GSConsole.alias_list.keys().has(alias_name):
				GSConsole.send_output_message("Alias [b]" + alias_name + "[/b] has following command: \n" + GSConsole.alias_list[alias_name].command)
			else:
				GSConsole.send_output_message("Alias [b]" + alias_name + "[/b] not found")
	return true

func remove_alias_command_callable(arguments_array: Array = []) -> bool:
	if arguments_array.size() > 0 and GSConsole.alias_list.keys().has(arguments_array[0]):
		GSConsole.alias_list.erase(arguments_array[0])
		GSConsole.send_output_message("Removed [b]" + arguments_array[0] + "[/b] alias")
	return true

func exec_command_callable(arguments_array: Array = []) -> bool:
	if arguments_array.size() < 1:
		GSConsole.send_output_message("Not enough arguments. Please supply valid path to the file")
		return false
	else:
		GSConfig.load_cfg_file(arguments_array[0])
	return true

func bind_command_callable(arguments_array: Array = []) -> bool:
	if arguments_array.size() == 0:
		for i : String in GSInput.bound_keys.keys():
			var key : String = OS.get_keycode_string(int(i)).to_upper().strip_edges()
			if key == "":
				key = GSInput.get_mouse_key_names(i).to_upper()
			var command : String = GSInput.bound_keys[i]["command"].strip_edges()
			GSConsole.send_output_message("[" + key + "] - " + command)
		pass
	elif arguments_array.size() > 0:
		var keyname : String = arguments_array[0]
		var keycode : int = OS.find_keycode_from_string(keyname)
		var mouse_key : StringName = GSInput.get_mosue_button(keyname)
		if keycode == 0:
			if mouse_key == "":
				GSConsole.send_output_message("[color=red]ERROR: invalid keycode - \"" + keyname + "\"[/color]")
				return false
		if arguments_array.size() == 1:
			if !keycode == 0:
				var key : String = OS.get_keycode_string(keycode).to_upper()
				if GSInput.bound_keys.keys().has(str(keycode)):
					var command : String = GSInput.bound_keys[str(keycode)]["command"].strip_edges()
					GSConsole.send_output_message("[" + key + "] - " + command)
				else:
					GSConsole.send_output_message("[" + key + "] - not bound")
			else:
				if GSInput.bound_keys.keys().has(str(mouse_key)):
					var command : String = GSInput.bound_keys[str(mouse_key)]["command"].strip_edges()
					GSConsole.send_output_message("[" + keyname.to_upper() + "] - " + command)
				else:
					GSConsole.send_output_message("[" + keyname.to_upper() + "] - not bound")

		else:
			if !keycode == 0:
				GSInput.bound_keys[str(keycode)] = {"command":arguments_array[1]}
			else:
				GSInput.bound_keys[str(mouse_key)] = {"command":arguments_array[1]}

	return true

func unbind_command_callable(arguments_array: Array = []) -> bool:
	if arguments_array.size() == 0: return true
	else:

		var keyname : String = arguments_array[0]
		var keycode : int = OS.find_keycode_from_string(keyname)
		if keycode == 0:
			GSConsole.send_output_message("[color=red]ERROR: invalid keycode - \"" + keyname + "\"[/color]")
			return false
		GSInput.bound_keys.erase(str(keycode))
	return true

func unbind_all_command_callable(arguments_array: Array = []) -> bool:
	GSInput.bound_keys = {}
	return true

func noclip_command_callable(arguments_array: Array = []) -> bool:
	if GSConsole.convar_list[&"sv_cheats"]["value"] == true:
		#TODO: change to set noclip state of player owner or player from arguments
		if get_tree().root.get_node("GameRoot/Node3D/player") != null:
			var player : GSPlayer = get_tree().root.get_node("GameRoot/Node3D/player")
			if player.current_movement_type == player.MOVEMENT_TYPE.NOCLIP:
				player.current_movement_type = player.MOVEMENT_TYPE.AIRBORNE
			else:
				player.current_movement_type = player.MOVEMENT_TYPE.NOCLIP
		return true
	else:
		GSConsole.send_output_message("[color=red]Noclip command requires cheats enabled (\"sv_cheats 1\")[/color]")
		return false
#endregion

#region wish commands callables

func enable_wish_left(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_left"] = true
	return true
func disable_wish_left(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_left"] = false
	return true
func enable_wish_right(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_right"] = true
	return true
func disable_wish_right(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_right"] = false
	return true
func enable_wish_forward(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_forward"] = true
	return true
func disable_wish_forward(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_forward"] = false
	return true
func enable_wish_back(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_back"] = true
	return true
func disable_wish_back(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_back"] = false
	return true
func enable_wish_crouch(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_crouch"] = true
	return true
func disable_wish_crouch(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_crouch"] = false
	return true
func enable_wish_jump(arguments_array: Array = []) -> bool:
	GSInput.wish_sates["wish_jump"] = true
	return true
func disable_wish_jump(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_jump"] = false
	return true
func enable_wish_attack(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_attack"] = true
	#TODO: Exchange for proper attack script when ready
	# var player : GSPlayer = get_tree().root.get_node("Node3D/gs_player")
	# player.spawn_rocket()
	return true
func disable_wish_attack(arguments_array: Array = []) -> bool: 
	GSInput.wish_sates["wish_attack"] = false
	return true

#endregion
