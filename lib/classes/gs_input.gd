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
var mouse_motion_with_sens : Vector2 = Vector2.ZERO
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

func handleMouseMotion(event: InputEventMouseMotion) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_moved = true
		var fps : float = Performance.get_monitor(Performance.TIME_FPS)
		mouse_motion = event.screen_relative * (fps/144.0)
		mouse_motion_with_sens = Vector2(mouse_motion.x * GSConsole.convar_list[&"cl_mousesensx"]["value"], mouse_motion.y * GSConsole.convar_list[&"cl_mousesensy"]["value"])

func _physics_process(delta: float) -> void:
	if current_input_context == INPUT_CONTEXT.CHARACTER and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if mouse_motion == last_mouse_motion: mouse_moved = false
	last_mouse_motion = mouse_motion
	for i : int in keylist.keys():
		if !bound_keys.keys().has(str(i)): return #Needed in case button was unbound while processing command input
		if keylist[i]["state"]:
			if keylist[i]["queue_release"]:
				keylist[i] = {
					"state": false,
					"frame": Engine.get_physics_frames(),
					"queue_release": false
				}
			else:
				keylist.erase(i)
			GSConsole.process_input(bound_keys[str(i)]["command"])
		else:
			GSConsole.process_input(construct_negative_command(bound_keys[str(i)]["command"]))
			keylist.erase(i)

func handleMouseButton(event: InputEventMouseButton) -> void:
	if !bound_keys.keys().has(str(event.button_index)): return
	if event.pressed:
		keylist[event.button_index] = {
			"state": true,
			"frame": Engine.get_physics_frames(),
			"queue_release": false
		}
	else:
		if keylist.keys().has(event.button_index):
			if keylist[event.button_index]["frame"] == Engine.get_physics_frames():
				keylist[event.button_index] = {
					"state": true,
					"frame": Engine.get_physics_frames(),
					"queue_release": true
				}
				return
		keylist[event.button_index] = {
			"state": false,
			"frame": Engine.get_physics_frames(),
			"processed": false,
			"queue_release": false
		}

func handleKeyboardInput(event: InputEventKey) -> void:
	if resolve_key_state(event) == KEYSTATE.JUST_PRESSED and current_input_context == INPUT_CONTEXT.TEXT_INPUT:
		if event.keycode == 4194320: #keyboard UP button
			GSConsole.input_node.text = GSConsole.get_history_suggestion(true)
		if event.keycode == 4194322: #keyboard DOWN button
			GSConsole.input_node.text = GSConsole.get_history_suggestion(false)
	
	if !bound_keys.keys().has(str(event.keycode)): return
	if event.pressed:
		keylist[event.keycode] = {
			"state": true,
			"frame": Engine.get_physics_frames(),
			"queue_release": false
		}
	else:
		if keylist.keys().has(event.keycode):
			if keylist[event.keycode]["frame"] == Engine.get_physics_frames():
				keylist[event.keycode] = {
					"state": true,
					"frame": Engine.get_physics_frames(),
					"queue_release": true
				}
				return
		keylist[event.keycode] = {
			"state": false,
			"frame": Engine.get_physics_frames(),
			"processed": false,
			"queue_release": false
		}

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
	return mouse_buttons[id]

func get_mosue_button(button_name: StringName) -> StringName:
	if mouse_buttons.find_key(button_name) == null:
		return ""
	return mouse_buttons.find_key(button_name)
