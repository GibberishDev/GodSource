extends Panel

@onready
var input : LineEdit = get_node("VBoxContainer/HBoxContainer/VBoxContainer/console_input")
@onready
var output : RichTextLabel = get_node("VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/console_panel/console_output")


func _ready() -> void:
	output.focus_mode = Control.FOCUS_NONE
	Console.add_command("help", help_command_callable, false, false, -1,
	"Show usage of provided command or if none provided print full list of registered commands.\n	Syntax: help <command name>\n	Is cheat: false\n	Is admin only: false")
	Console.add_command("echo", echo_command_callable, false, false, -1,
	"Prints suppled text in console output\n	Syntax: echo <text...>\n	Is cheat: false\n	Is admin only: false")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_console_input_text_submitted(new_text: String) -> void:
	input.clear()
	var regex_expression = RegEx.new()
	regex_expression.compile("\\[.+?\\]")
	var sanitized_text = regex_expression.sub(new_text, "", true).to_lower()
	if sanitized_text == "": return
	output.add_text("\n> " + sanitized_text)
	var output_message = Console.process_input(sanitized_text)
	if output_message != "":
		output.append_text("\n] "+output_message)
	

func help_command_callable(command_name_array: Array = []) -> void:
	if command_name_array.size() == 0:
		output.append_text("\n] All avaliable commands are:" + Console.get_all_commands())
		return
	for i in range(command_name_array.size()):
		var command_name = command_name_array[i]
		if  Console.command_list.get(command_name) == null:
			output.append_text("\n] [color=pink]command not found: [/color][color=red][b]" + command_name + "[/b][/color]")
			output.append_text("\n] All avaliable commands are:" + Console.get_all_commands())
			return
		var description = Console.command_list[command_name].description
		output.append_text("\n] Help for [color=lime][b]" + str(command_name) + "[/b][/color] command:\n" + description)

func echo_command_callable(arguments_array: Array = []) -> void:
	var output_text = "\n] "
	for i in range(arguments_array.size()):
		output_text += str(arguments_array[i]) + " "
	output.append_text(output_text)
