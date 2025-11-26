extends Node

#region variables

signal convar_changed(convar_name: StringName)

enum CONVAR_TYPE {
	STRING,
	INTEGER,
	FLOAT,
	BOOLEAN
}

var output_node : RichTextLabel = null
var input_node : LineEdit = null
var terminal_input_thread_semaphore : Semaphore = null

var command_list : Dictionary = {} 
var alias_list : Dictionary = {} 
var convar_list : Dictionary = {}
var valid_float_strings_true : PackedStringArray = ["true","True","1","1b","1.0"]
var valid_float_strings_false : PackedStringArray = ["false","False","0","0b","0.0"]

@export
var input_history_amount : int = 10
var input_history : Array[String] = []
var input_history_last_id : int = 0

#endregion

#region Command
class Command:
	var command_name : StringName ##Trigger word which will let console know what command to execute
	var callable : Callable ##Method which will be executed upon entering the command
	var description : String ##Text description of command which will be shown to user when using with help command
	var context : Array[GSInput.INPUT_CONTEXT] ## Determines what [enum GSInput.INPUT_CONTEXT] contexes are required to execute command. If Array is empty it will allow command execution in any context

	func _init(_command_name: StringName, _callable: Callable, _description: String = "NO DESCRIPTION PROVIDED", _context : Array[GSInput.INPUT_CONTEXT] = []) -> void:
		self.command_name = _command_name
		self.callable = _callable
		self.description = _description
		self.context = _context

func add_command(command_name: StringName, callable: Callable, description: String = "NO DESCRIPTION PROVIDED", context : Array[GSInput.INPUT_CONTEXT] = []) -> void:
	var new_command: Command = Command.new(command_name, callable, description, context)
	self.command_list[command_name] = new_command
	send_output_message("Registered command \"" + command_name + "\"")

func get_all_commands() -> String:
	var output_string: String = ""
	for i : StringName in self.command_list:
		output_string += ("\n[color=gold]" + str(i) + "[/color]")
	return output_string

func process_input(input_string: String) -> bool:
	var commands_array: PackedStringArray = split_commands_input(input_string) #Split commands string into an array of commands
	return process_commands(commands_array)

func split_commands_input(input_string: String) -> PackedStringArray:
	var regex_selector: RegEx = RegEx.new()

	regex_selector.compile("(\"(.*?)\"|[^;])*")

	var regex_matches: Array[RegExMatch] = regex_selector.search_all(input_string)
	var output: PackedStringArray = []

	for i: int in (regex_matches.size()):
		var match: String = regex_matches[i].get_string().strip_edges()
		if match != "":
			output.append(match)

	return output

func process_commands(commands_array: Array[String]) -> bool:
	var regex_selector: RegEx = RegEx.new()
	regex_selector.compile("^[a-zA-Z0-9_\\-\\+]*")

	for i: int in range(commands_array.size()):
		var command_name: StringName = regex_selector.search(commands_array[i]).get_string()
		if !self.command_list.has(command_name):
			if !self.alias_list.has(command_name):
				if !self.convar_list.has(command_name):
					send_output_message("[color=pink]command not found: [/color][color=red][b]" + StringName(command_name) + "[/b][/color]")
					return false
				else:
					var input_arguments: String = commands_array[i].right(command_name.length() * -1)
					return process_convar(command_name, process_arguments(input_arguments))
			else:
				return process_alias(command_name)
		else:
			if self.command_list[command_name].context == [] or self.command_list[command_name].context.has(GSInput.current_input_context):
				var input_arguments: String = commands_array[i].right(command_name.length() * -1)
				return self.command_list[command_name].callable.call(process_arguments(input_arguments))
			else:
				var return_message : String = "[color=light_gray]DEBUG INFO: Command [b]" + StringName(command_name) + "[/b] cannot be executed in [b]" + str(GSInput.INPUT_CONTEXT.keys()[GSInput.current_input_context]) + "[/b] context! It requires following contexes: "
				for idx : int in self.command_list[command_name].context:
					return_message += str(GSInput.INPUT_CONTEXT.keys()[idx]) + " "
				# print_rich(return_message)
				return true
	if terminal_input_thread_semaphore != null: terminal_input_thread_semaphore.post()
	return false

func process_arguments(input_arguments: String) -> Array:
	var regex_expression: RegEx =  RegEx.new()
	regex_expression.compile("(?<=\").*(?=\")|([a-zA-Z0-9_\\-\\+\\[\\]\\/\\.]*)")

	var arguments_array: Array = []
	var regex_matches: Array[RegExMatch] = regex_expression.search_all(input_arguments)

	for i: int in range(regex_matches.size()):
		var match: String = regex_matches[i].get_string()
		if match != "":
			arguments_array.append(match)

	return arguments_array

func send_output_message(message: String) -> void:
	print_rich(message)
	if output_node != null:
		output_node.append_text("\n " + message)
	
func get_history_suggestion(forward: bool) -> String:
	if input_history.size() < 1:
		return ""
	var output : String = input_history[input_history_last_id]
	if forward: input_history_last_id += 1
	else: input_history_last_id -= 1
	if input_history_last_id >= input_history.size():
		input_history_last_id = 0
	if input_history_last_id < 0:
		input_history_last_id = input_history.size() - 1
	return output

#endregion

#region Alias
class Alias:
	var alias_name     : StringName
	var command: String

	func _init(_alias_name: StringName, _command: String) -> void:
		self.alias_name      = _alias_name
		self.command = _command

func add_alias(alias_name: StringName, command: String) -> void:
	var alias : Alias = Alias.new(alias_name, command)
	self.alias_list[alias_name] = alias

func get_all_aliases() -> Array[Alias]:
	var array : Array[Alias] = []
	for i : StringName in alias_list.keys():
		array.append(alias_list[i])
	return array

func process_alias(id: StringName) -> bool:
	var command : String = alias_list[id].command
	return process_input(command) 

#endregion

#region ConVar

func add_convar(convar_name : StringName,type : CONVAR_TYPE,default_value: String,min_value : String = "",max_value: String = "",value : String = "", description: String = "") -> void:
	if value == "":
		value = default_value
	
	var convar_data : Dictionary = {
		"type" : type,
		"description" : description
	}
	match type:
		CONVAR_TYPE.STRING:
			convar_data["default_value"] = default_value
			convar_data["value"] = value
			if min_value != "":
				push_warning("Minimum value for convar \"" + convar_name + "\" of type String is not aplicable. Discarding min_value...")
			if max_value != "":
				push_warning("Maximum value for convar \"" + convar_name + "\" of type String is not aplicable. Discarding max_value...")
			convar_list[convar_name] = convar_data
		CONVAR_TYPE.INTEGER:
			if (!default_value.is_valid_int() or !default_value.is_valid_float()):
				push_error("Default value for convar \"" + convar_name + "\" cannot be converted to type int. Not registering...")
				return
			if (!value.is_valid_int() or !value.is_valid_float()) and value != "":
				push_error("Value for convar \"" + convar_name + "\" cannot be converted to type int. Not registering...")
				return
			if (!min_value.is_valid_int() or !min_value.is_valid_float()) and min_value != "":
				push_error("Minimum value for convar \"" + convar_name + "\" cannot be converted to type int. Not registering...")
				return
			if (!max_value.is_valid_int() or !max_value.is_valid_float()) and max_value != "":
				push_error("Maximum value for convar \"" + convar_name + "\" cannot be converted to type int. Not registering...")
				return
			
			convar_data["default_value"] = round(float(default_value))
			convar_data["value"] = round(float(value))
			if min_value != "":
				convar_data["min_value"] = round(float(min_value))
			if max_value != "":
				convar_data["max_value"] = round(float(max_value))
			if min_value != "" or max_value != "":
				if min_value != "" and max_value == "":
					convar_data["value"] = max(convar_data["value"], convar_data["min_value"])
				elif min_value == "" and max_value != "":
					convar_data["value"] = min(convar_data["value"], convar_data["max_value"])
				else:
					convar_data["value"] = clamp(convar_data["value"], convar_data["min_value"], convar_data["max_value"])
			convar_list[convar_name] = convar_data
		CONVAR_TYPE.FLOAT:
			if !default_value.is_valid_float():
				push_error("Default value for convar \"" + convar_name + "\" cannot be converted to type int. Not registering...")
				return
			if !value.is_valid_float() and value != "":
				push_error("Value for convar \"" + convar_name + "\" cannot be converted to type int. Not registering...")
				return
			if !min_value.is_valid_float() and min_value != "":
				push_error("Minimum value for convar \"" + convar_name + "\" cannot be converted to type int. Not registering...")
				return
			if !max_value.is_valid_float() and max_value != "":
				push_error("Maximum value for convar \"" + convar_name + "\" cannot be converted to type int. Not registering...")
				return
			
			convar_data["default_value"] = float(default_value)
			convar_data["value"] = float(value)
			if min_value != "":
				convar_data["min_value"] = float(min_value)
			if max_value != "":
				convar_data["max_value"] = float(max_value)
			if min_value != "" or max_value != "":
				if min_value != "" and max_value == "":
					convar_data["value"] = max(convar_data["value"], convar_data["min_value"])
				elif min_value == "" and max_value != "":
					convar_data["value"] = min(convar_data["value"], convar_data["max_value"])
				else:
					convar_data["value"] = clamp(convar_data["value"], convar_data["min_value"], convar_data["max_value"])
			convar_list[convar_name] = convar_data
		CONVAR_TYPE.BOOLEAN:
			if !valid_float_strings_true.has(default_value) and !valid_float_strings_false.has(default_value):
				push_error("Default value for convar \"" + convar_name + "\" cannot be converted to type boolean. Not registering...")
				return
			if !valid_float_strings_true.has(value) and !valid_float_strings_false.has(value) and value != "":
				push_error("Value for convar \"" + convar_name + "\" cannot be converted to type boolean. Not registering...")
				return
			if min_value != "":
				push_warning("Minimum value for convar \"" + convar_name + "\" of type Boolean is not aplicable. Discarding min_value...")
			if max_value != "":
				push_warning("Maximum value for convar \"" + convar_name + "\" of type Boolean is not aplicable. Discarding max_value...")
			if value == "":
				value = default_value
			
			if valid_float_strings_true.has(default_value):
				convar_data["default_value"] = true
			elif valid_float_strings_false.has(default_value):
				convar_data["default_value"] = false
			if valid_float_strings_true.has(value):
				convar_data["value"] = true
			elif valid_float_strings_false.has(value):
				convar_data["value"] = false
			convar_list[convar_name] = convar_data
		_:
			push_error("Invalid type for for convar \"" + convar_name + "\". Not regestering...")
			return
	send_output_message("Registered convar \"" + convar_name + "\"")

func get_convar_console_output(convar_name: StringName) -> String:
	var output : String = ""
	if convar_list[convar_name]["default_value"] != convar_list[convar_name]["value"]:
		output = "ConVar " + convar_name + " = " + str(convar_list[convar_name]["value"]) + " (def: " + str(convar_list[convar_name]["default_value"])
		if convar_list[convar_name].keys().has("min_value"):
			output += " min: " + str(convar_list[convar_name]["min_value"])
		if convar_list[convar_name].keys().has("max_value"):
			output += " max: " + str(convar_list[convar_name]["max_value"])
		output += ")"
	else:
		output = "ConVar " + convar_name + " = " + str(convar_list[convar_name]["value"])

	return output

func process_convar(convar_name: StringName, arguments_array : Array = []) -> bool:
	if arguments_array.size() == 0:
		send_output_message(get_convar_console_output(convar_name))
		return true
	else:
		return set_convar_value(convar_name, arguments_array[0])

func set_convar_value(convar_name: StringName, argument: String) -> bool:
	match convar_list[convar_name]["type"]:
		CONVAR_TYPE.STRING:
			convar_list[convar_name] = argument
		CONVAR_TYPE.INTEGER:
			if argument.is_valid_int() or argument.is_valid_float():
				var new_value : int = round(float(argument))
				convar_list[convar_name]["value"] = new_value
				if convar_list[convar_name].keys().has("min_value") or convar_list[convar_name].keys().has("max_value"):
					if convar_list[convar_name].keys().has("min_value") and !convar_list[convar_name].keys().has("max_value"):
						convar_list[convar_name]["value"] = max(convar_list[convar_name]["value"], convar_list[convar_name]["min_value"])
					elif !convar_list[convar_name].keys().has("min_value") and convar_list[convar_name].keys().has("max_value"):
						convar_list[convar_name]["value"] = min(convar_list[convar_name]["value"], convar_list[convar_name]["max_value"])
					else:
						convar_list[convar_name]["value"] = clamp(convar_list[convar_name]["value"], convar_list[convar_name]["min_value"], convar_list[convar_name]["max_value"])
			else:
				return false
		CONVAR_TYPE.FLOAT:
			if argument.is_valid_float():
				var new_value : float = float(argument)
				convar_list[convar_name]["value"] = new_value
				if convar_list[convar_name].keys().has("min_value") or convar_list[convar_name].keys().has("max_value"):
					if convar_list[convar_name].keys().has("min_value") and !convar_list[convar_name].keys().has("max_value"):
						convar_list[convar_name]["value"] = max(convar_list[convar_name]["value"], convar_list[convar_name]["min_value"])
					elif !convar_list[convar_name].keys().has("min_value") and convar_list[convar_name].keys().has("max_value"):
						convar_list[convar_name]["value"] = min(convar_list[convar_name]["value"], convar_list[convar_name]["max_value"])
					else:
						convar_list[convar_name]["value"] = clamp(convar_list[convar_name]["value"], convar_list[convar_name]["min_value"], convar_list[convar_name]["max_value"])
			else:
				return false
		CONVAR_TYPE.BOOLEAN:
			if valid_float_strings_true.has(argument):
				convar_list[convar_name]["value"] = true
			elif valid_float_strings_false.has(argument):
				convar_list[convar_name]["value"] = false
			else:
				return false
		_:
			send_output_message("[color=red]HOW did ya manage to reach this message??? anyways: error: invalid convar type at set_convar_value(). Blame dev if ya see it and point out improperly registered convar. Or insane stray electron from neutron star bitflipping your pc lmao - sincerely godsource dev GibbDev[/color]")
			return false
	emit_signal("convar_changed", convar_name)
	return true


#endregion
