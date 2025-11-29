extends Node

var current_input_context : INPUT_CONTEXT = INPUT_CONTEXT.UI

enum INPUT_CONTEXT {
	UI,
	TEXT_INPUT,
	CHARACTER
}

var ui_focused : bool = false

var wish_sates : Dictionary = {
	"wish_attack" : false,
	"wish_right": false,
	"wish_left": false,
	"wish_forward": false,
	"wish_back": false,
	"wish_jump": false,
	"wish_crouch": false,
}

var mouse_buttons : Dictionary = {
	&"1":&"mouse1",
	&"2":&"mouse2",
	&"3":&"mouse3",
	&"4":&"wheelup",
	&"5":&"wheeldown",
	&"6":&"wheelleft",
	&"7":&"wheelright",
	&"8":&"mouse4",
	&"9":&"mouse5"
}
var mouse_motion : Vector2 = Vector2.ZERO
var last_mouse_motion : Vector2 = Vector2.ZERO
var mouse_moved : bool = false

enum KEYSTATE {
	JUST_PRESSED,
	PRESSED,
	RELEASED,
}

var keylist : Dictionary = {}
var bound_keys : Dictionary = {}

func _ready()-> void:
	update_binds()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		handleMouseMotion(event)
	if event is InputEventMouseButton:
		handleMouseButton(event)
	if event is InputEventKey:
		handleKeyboardInput(event)

func _process(delta: float) -> void:
	if current_input_context == INPUT_CONTEXT.CHARACTER and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if mouse_motion == last_mouse_motion: mouse_moved = false
	last_mouse_motion = mouse_motion

func handleMouseMotion(event: InputEventMouseMotion) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_moved = true
		mouse_motion = event.screen_relative

func handleMouseButton(event: InputEventMouseButton) -> void:
	keylist[event.button_index] = {"state": event.pressed}
	var bind_command : String = ""
	if bound_keys.keys().has(str(event.button_index)):
		bind_command = bound_keys[str(event.button_index)]["command"]
	if event.pressed and current_input_context != INPUT_CONTEXT.TEXT_INPUT:
		if bind_command != "":
			GSConsole.process_input(bind_command)
	if !event.pressed:
		keylist.erase(event.button_index)
		if bind_command != "":
			bind_command = construct_negative_command(bind_command)
			GSConsole.process_input(bind_command)

func handleKeyboardInput(event: InputEventKey) -> void:
	keylist[event.keycode] = {"state": resolve_key_state(event)}
	var bind_command : String = ""
	if bound_keys.keys().has(str(event.keycode)):
		bind_command = bound_keys[str(event.keycode)]["command"]
	if resolve_key_state(event) == KEYSTATE.JUST_PRESSED and current_input_context != INPUT_CONTEXT.TEXT_INPUT:
		if bind_command != "":
			GSConsole.process_input(bind_command)
	if resolve_key_state(event) == KEYSTATE.JUST_PRESSED and current_input_context == INPUT_CONTEXT.TEXT_INPUT:
		if event.keycode == 4194320: #keyboard UP button
			GSConsole.input_node.text = GSConsole.get_history_suggestion(true)
		if event.keycode == 4194322: #keyboard DOWN button
			GSConsole.input_node.text = GSConsole.get_history_suggestion(false)
	if resolve_key_state(event) == KEYSTATE.RELEASED:
		keylist.erase(event.keycode)
		if bind_command != "":
			bind_command = construct_negative_command(bind_command)
			GSConsole.process_input(bind_command)
	# print(keylist)

func resolve_key_state(event: InputEventKey) -> KEYSTATE:
	if event.pressed and !event.echo: return KEYSTATE.JUST_PRESSED
	if event.pressed and event.echo: return KEYSTATE.PRESSED
	return KEYSTATE.RELEASED


func update_binds() -> void:
	#TODO: when settings are developed add default binds loading and user config loading
	bound_keys = {
		"96": {
			"command":" toggle_console"
		},
		"65": {
			"command":"+left"
		},
		"68": {
			"command":"+right"
		},
		"87": {
			"command":"+forward"
		},
		"83": {
			"command":"+back"
		},
		"4194326": {
			"command":"+crouch"
		},
		"32": {
			"command":"+jump"
		},
		"1": {
			"command":"+attack"
		}
	}

func construct_negative_command(bind_command: String) -> String:
	var commands_array : PackedStringArray = GSConsole.split_commands_input(bind_command)
	bind_command = ""
	for i : String in commands_array:
		if i[0] == "+":
			i[0] = "-"
			bind_command += i + ";"
	return bind_command

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func get_mouse_key_names(id: StringName) -> StringName:
	if !mouse_buttons.keys().has(id):
		return ""
	print(mouse_buttons[id])
	return mouse_buttons[id]

func get_mosue_button(button_name: StringName) -> StringName:
	if mouse_buttons.find_key(button_name) == null:
		return ""
	return mouse_buttons.find_key(button_name)
