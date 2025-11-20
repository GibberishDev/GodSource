extends Node

var current_input_context : INPUT_CONTEXT = INPUT_CONTEXT.UI

enum INPUT_CONTEXT {
	UI,
	TEXT_INPUT,
	CHARACTER
}

var ui_focused : bool = false

var wish_sates : Dictionary = {
	"wish_right": false,
	"wish_left": false,
	"wish_forward": false,
	"wish_back": false,
	"wish_jump": false,
	"wish_crouch": false,
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


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if current_input_context == INPUT_CONTEXT.UI:
			current_input_context = INPUT_CONTEXT.CHARACTER
		elif current_input_context == INPUT_CONTEXT.CHARACTER:
			current_input_context = INPUT_CONTEXT.UI
			release_mouse()

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
	pass

func handleKeyboardInput(event: InputEventKey) -> void:
	keylist[event.keycode] = {"state": resolve_key_state(event)}
	var bind_command : String = determine_bind(event.keycode)

	if resolve_key_state(event) == KEYSTATE.JUST_PRESSED and current_input_context != INPUT_CONTEXT.TEXT_INPUT:
		if bind_command != "":
			Console.process_input(bind_command)
	if resolve_key_state(event) == KEYSTATE.RELEASED:
		keylist.erase(event.keycode)
		if bind_command != "":
			bind_command = construct_negative_command(bind_command)
			Console.process_input(bind_command)
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
		}
	}

func determine_bind(keycode: Key) -> String:
	var matches : Array = []
	for i : String in bound_keys.keys():
		if i.find(str(keycode)) != -1:
			matches.append(i)
	matches.sort_custom(GSUtils.sort_array_of_strings)
	for k : String in matches:
		var valid_match : bool = true
		var split_keys : PackedStringArray = k.split("+")
		for j : String in split_keys:
			if j == str(keycode): pass
			if j == "ctrl" and Input.is_key_pressed(KEY_CTRL) != true:
				valid_match = false
				break
			if j == "alt" and Input.is_key_pressed(KEY_ALT) != true:
				valid_match = false
				break
			if j == "shift" and Input.is_key_pressed(KEY_SHIFT) != true:
				valid_match = false
				break
		if valid_match == true:
			return bound_keys[k]["command"]
	return ""

func construct_negative_command(bind_command: String) -> String:
	var commands_array : PackedStringArray = Console.split_commands_input(bind_command)
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
