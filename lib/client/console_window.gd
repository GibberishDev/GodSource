extends Control

@onready var input: LineEdit = %console_input
@onready var output: RichTextLabel = %console_output

func _ready() -> void:
	Console.output_node = output
	output.focus_mode = Control.FOCUS_NONE

func _exit_tree() -> void:
	Console.output_node = null

func _on_console_input_text_submitted(new_text: String) -> void:
	input.clear()
	#var regex_expression = RegEx.new()
	#regex_expression.compile("\\[.+?\\]")
	#var sanitized_text = regex_expression.sub(new_text, "", true).to_lower()
	if new_text == "": return

	output.add_text("\n> " + new_text)

	Console.process_input(new_text)

func input_focused() -> void:
	GSInput.ui_focused = true

func input_unfocused() -> void:
	GSInput.ui_focused = false


func _on_console_input_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		%console_input.grab_focus()
