extends Panel

@onready var input: LineEdit = get_node("VBoxContainer/HBoxContainer/VBoxContainer/console_input")
@onready var output: RichTextLabel = get_node("VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/console_panel/console_output")

func _ready() -> void:
	Console.output_node = output
	output.focus_mode = Control.FOCUS_NONE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_console_input_text_submitted(new_text: String) -> void:
	input.clear()
	#var regex_expression = RegEx.new()
	#regex_expression.compile("\\[.+?\\]")
	#var sanitized_text = regex_expression.sub(new_text, "", true).to_lower()
	if new_text == "": return

	output.add_text("\n> " + new_text)

	Console.process_input(new_text)
