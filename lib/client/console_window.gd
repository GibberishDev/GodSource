extends Control

@onready var input: LineEdit = %console_input
@onready var output: RichTextLabel = %console_output

func _ready() -> void:
	GSConsole.output_node = output
	GSConsole.input_node = input
	output.focus_mode = Control.FOCUS_NONE

#release focus of input node on click outside
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		if !Rect2(%console_input.global_position, abs(%console_input.size)).has_point(event.global_position):
			%console_input.release_focus()
			GSInput.current_input_context = GSInput.INPUT_CONTEXT.UI

func _exit_tree() -> void:
	GSConsole.output_node = null
	GSConsole.input_node = null

func _on_console_input_text_submitted(new_text: String) -> void:
	input.clear()
	#var regex_expression = RegEx.new()
	#regex_expression.compile("\\[.+?\\]")
	#var sanitized_text = regex_expression.sub(new_text, "", true).to_lower()
	if new_text == "": return

	output.add_text("\n> " + new_text)

	GSConsole.process_input(new_text)
	if !GSConsole.input_history.has(new_text):
		GSConsole.input_history.insert(0,new_text)
		if GSConsole.input_history.size() > GSConsole.input_history_amount:
			GSConsole.input_history.resize(GSConsole.input_history_amount)

func input_focused() -> void:
	GSInput.current_input_context = GSInput.INPUT_CONTEXT.TEXT_INPUT

func focus_input() -> void:
	GSInput.current_input_context = GSInput.INPUT_CONTEXT.UI
	GSInput.release_mouse()
