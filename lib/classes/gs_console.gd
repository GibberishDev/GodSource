extends Node

var output_node : RichTextLabel = null
var terminal_input_thread_semaphore : Semaphore = null

var command_list : Dictionary = {} 
var alias_list : Dictionary = {} 
var convar_list : Dictionary = {}

class Command:
	var command_name : StringName ##Trigger word which will let console know what command to execute
	var callable : Callable ##Method which will be executed upon entering the command
	var arguments_number : int ##Number of argumanets needed for command. 0 means no arguments needed, -1 means all arguments after the command is entered are passed to callable, any other positive number means exact amopunt of arguments must be present. any more will be dropped
	var description : String ##Text description of command which will be shown to user when using with help command
	var context : Array[GSInput.INPUT_CONTEXT] ## Determines what [enum GSInput.INPUT_CONTEXT] contexes are required to execute command. If Array is empty it will allow command execution in any context

	func _init(_command_name: StringName, _callable: Callable, _arguments_number: int = 0, _description: String = "NO DESCRIPTION PROVIDED", _context : Array[GSInput.INPUT_CONTEXT] = []) -> void:
		self.command_name = _command_name
		self.callable = _callable
		self.arguments_number = _arguments_number
		self.description = _description
		self.context = _context

func add_command(command_name: StringName, callable: Callable, arguments_number: int = 0, description: String = "NO DESCRIPTION PROVIDED", context : Array[GSInput.INPUT_CONTEXT] = []) -> void:
	var new_command: Command = Command.new(command_name, callable, arguments_number, description, context)
	self.command_list[command_name] = new_command

func get_all_commands() -> String:
	var output_string: String = ""
	for i : StringName in self.command_list:
		output_string += ("\n[color=gold]" + str(i) + "[/color]")
	return output_string

func process_input(input_string: String) -> void:
	var commands_array: PackedStringArray = split_commands_input(input_string) #Split commands string into an array of commands
	process_commands(commands_array)

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

func process_commands(commands_array: Array[String]) -> void:
	var regex_selector: RegEx = RegEx.new()
	regex_selector.compile("^[a-zA-Z0-9_\\-\\+]*")

	for i: int in range(commands_array.size()):
		var command_name: StringName = regex_selector.search(commands_array[i]).get_string()
		if !self.command_list.has(command_name):
			if !self.alias_list.has(command_name):
				send_output_message("[color=pink]command not found: [/color][color=red][b]" + StringName(command_name) + "[/b][/color]")
			else:
				process_alias(command_name)
		else:
			if self.command_list[command_name].context == [] or self.command_list[command_name].context.has(GSInput.current_input_context):
				var input_arguments: String = commands_array[i].right(command_name.length() * -1)
				self.command_list[command_name].callable.call(process_arguments(input_arguments))
			else:
				var return_message : String = "[color=light_gray]DEBUG INFO: Command [b]" + StringName(command_name) + "[/b] cannot be executed in [b]" + str(GSInput.INPUT_CONTEXT.keys()[GSInput.current_input_context]) + "[/b] context! It requires following contexes: "
				for idx : int in self.command_list[command_name].context:
					return_message += str(GSInput.INPUT_CONTEXT.keys()[idx]) + " "
				# print_rich(return_message)
	if terminal_input_thread_semaphore != null: terminal_input_thread_semaphore.post()

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

class Alias:
	var id     : StringName
	var command: String

	func _init(_id: StringName, _command: String) -> void:
		self.id      = _id
		self.command = _command

func add_alias(id: StringName, command: String) -> void:
	var alias : Alias = Alias.new(id, command)
	self.alias_list[id] = alias

func get_all_aliases() -> Array[Alias]:
	var array : Array[Alias] = []
	for i : StringName in alias_list.keys():
		array.append(alias_list[i])
	return array

func process_alias(id: StringName) -> void:
	var command : String = alias_list[id].command
	process_input(command) 