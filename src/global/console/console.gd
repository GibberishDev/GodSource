extends Node

var output_node : RichTextLabel = null
var command_list : Dictionary = {} #TODO: move to console class

class Command:
	var command_name          : StringName ##Trigger word which will let console know what command to execute
	var callable              : Callable ##Method which will be executed upon entering the command
	var operator_status_needed: bool ##Determines if command can be only exected by peers with operator status
	var is_cheat              : bool ##Determines if command is a cheat command. I dunno to disable achievements or smth, go figgure
	var arguments_number      : int ##Number of argumanets needed for command. 0 means no arguments needed, -1 means all arguments after the command is entered are passed to callable, any other positive number means exact amopunt of arguments must be present. any more will be dropped
	var description           : String ##Text description of command which will be shown to user when using with help command

	func _init(_command_name: StringName, _callable: Callable, _operator_status_needed: bool, _is_cheat: bool, _arguments_number: int = 0, _description: String = "NO DESCRIPTION PROVIDED") -> void:
		self.command_name           = _command_name
		self.callable               = _callable
		self.operator_status_needed = _operator_status_needed
		self.is_cheat               = _is_cheat
		self.arguments_number       = _arguments_number
		self.description            = _description

func add_command(command_name: StringName, callable: Callable, operator_status_needed: bool, is_cheat: bool, arguments_number: int = 0, description: String = "NO DESCRIPTION PROVIDED") -> Command:
	var new_command = Command.new(command_name, callable, operator_status_needed, is_cheat, arguments_number, description)
	self.command_list[command_name] = new_command
	return new_command

func get_all_commands() -> String:
	var output_string : String = ""
	for i in self.command_list:
		output_string += ("\n[color=gold]"
		+ str(i) + "[/color]: " + self.command_list[i].description
		)
	return output_string


func process_input(input_string: String) -> String:
	var commands_array : Array[String] = split_commands_input(input_string) #Split commands string into an array of commands
	process_commands(commands_array)
	return ""


func split_commands_input(input_string: String) -> Array[String]:
	var regex_selector = RegEx.new()
	regex_selector.compile("(\"(.*?)\"|[^;])*")
	var regex_matches : Array[RegExMatch] = regex_selector.search_all(input_string)
	var output : Array[String] = []
	for i in (regex_matches.size()):
		var match = regex_matches[i].get_string().strip_edges()
		if match != "":
			output.append(match)
	return output

func process_commands(commands_array: Array[String]) -> void:
	var regex_selector = RegEx.new()
	regex_selector.compile("^[a-zA-Z0-9_-]*")
	for i in range(commands_array.size()):
		var command_name = regex_selector.search(commands_array[i]).get_string()
		if !self.command_list.has(command_name):
			send_output_message("[color=pink]command not found: [/color][color=red][b]" + StringName(command_name) + "[/b][/color]")
		else:
			var input_arguments = commands_array[i].right(command_name.length() * -1)
			self.command_list[StringName(command_name)].callable.call(process_arguments(input_arguments))

func process_arguments(input_arguments: String) -> Array:
	var regex_expression =  RegEx.new()
	regex_expression.compile("(?<=\").*(?=\")|([a-zA-Z0-9_-]*)")
	var arguments_array = []
	var regex_matches = regex_expression.search_all(input_arguments)
	for i in range(regex_matches.size()):
		var match = regex_matches[i].get_string()
		if match != "":
			arguments_array.append(match)
	return arguments_array

func send_output_message(message: String) -> void:
	if output_node != null:
		output_node.append_text("\n] " + message)
	print_rich(message)
