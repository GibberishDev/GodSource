extends Node

var action_list: Dictionary = {
	"escape": KEY_ESCAPE,
	"tab": KEY_TAB,
	"capslock": KEY_CAPSLOCK,
	"shift": KEY_SHIFT,
	"ctrl": KEY_CTRL,
	"alt": KEY_ALT,
	"space": KEY_SPACE,
	"enter": KEY_ENTER,
	"backspace": KEY_BACKSPACE,

	"mouse1": MOUSE_BUTTON_LEFT,
	"mouse2": MOUSE_BUTTON_RIGHT,
	"mouse3": MOUSE_BUTTON_MIDDLE,
	"mouse4": MOUSE_BUTTON_XBUTTON2,
	"mouse5": MOUSE_BUTTON_XBUTTON1,

	"uparrow": KEY_UP,
	"downarrow": KEY_DOWN,
	"leftarrow": KEY_LEFT,
	"rightarrow": KEY_RIGHT,

	"insert": KEY_INSERT,
	"delete": KEY_DELETE,
	"pgdn": KEY_PAGEDOWN,
	"pgup": KEY_PAGEUP,
	"home": KEY_HOME,
	"end": KEY_END,
	"pause": KEY_PAUSE,

	"1": KEY_1,
	"2": KEY_2,
	"3": KEY_3,
	"4": KEY_4,
	"5": KEY_5,
	"6": KEY_6,
	"7": KEY_7,
	"8": KEY_8,
	"9": KEY_9,
	"0": KEY_0,

	"q": KEY_Q,
	"w": KEY_W,
	"e": KEY_E,
	"r": KEY_R,
	"t": KEY_T,
	"y": KEY_Y,
	"u": KEY_U,
	"i": KEY_I,
	"o": KEY_O,
	"p": KEY_P,
	"[": KEY_BRACKETLEFT,
	"]": KEY_BRACKETRIGHT,
	"a": KEY_A,
	"s": KEY_S,
	"d": KEY_D,
	"f": KEY_F,
	"g": KEY_G,
	"h": KEY_H,
	"j": KEY_J,
	"k": KEY_K,
	"l": KEY_L,
	"z": KEY_Z,
	"x": KEY_X,
	"c": KEY_C,
	"v": KEY_V,
	"b": KEY_B,
	"n": KEY_N,
	"m": KEY_M,
}

var action_list_commands: Dictionary = {}
var key_to_action: Dictionary = {}
var mouse_to_action: Dictionary = {}

var wish_forward: bool = false
var wish_backward: bool = false
var wish_left: bool = false
var wish_right: bool = false
var wish_jump: bool = false
var wish_duck: bool = false
var wish_fire: bool = false
var wish_use: bool = false

func _ready() -> void:
	for element: String in action_list.keys():
		action_list_commands[element] = ""

	for action: String in action_list:
		var code: Key = action_list[action]

		if code >= MOUSE_BUTTON_LEFT and code <= MOUSE_BUTTON_XBUTTON2:
			mouse_to_action[code] = action
		else:
			key_to_action[code] = action

	GSConsole.add_command("+forward", "", "", command_plus_forward, 0, 0)
	GSConsole.add_command("-forward", "", "", command_minus_forward, 0, 0)
	GSConsole.add_command("+back", "", "", command_plus_back, 0, 0)
	GSConsole.add_command("-back", "", "", command_minus_back, 0, 0)
	GSConsole.add_command("+left", "", "", command_plus_left, 0, 0)
	GSConsole.add_command("-left", "", "", command_minus_left, 0, 0)
	GSConsole.add_command("+right", "", "", command_plus_right, 0, 0)
	GSConsole.add_command("-right", "", "", command_minus_right, 0, 0)
	GSConsole.add_command("+jump", "", "", command_plus_jump, 0, 0)
	GSConsole.add_command("-jump", "", "", command_minus_jump, 0, 0)
	GSConsole.add_command("+duck", "", "", command_plus_duck, 0, 0)
	GSConsole.add_command("-duck", "", "", command_minus_duck, 0, 0)
	GSConsole.add_command("+fire", "", "", command_plus_fire, 0, 0)
	GSConsole.add_command("-fire", "", "", command_minus_fire, 0, 0)

	GSConsole.add_command("bind", 'bind <key> "<commands>"', "It is used to bind a key to one or several other commands.", command_bind, -1, 2)
	GSConsole.add_command("unbind", 'unbind <key>', "It is used to unbind a key.", command_unbind, 1, 1)

func _unhandled_key_input(event: InputEvent) -> void:
	if not GSGlobal.menu.on_map:
		return

	var keycode: int = event.get_keycode()

	if event.is_pressed() and not event.is_echo():
		if key_to_action.has(keycode):
			var action: String = key_to_action[keycode]
			var cmd: String = action_list_commands.get(action, "")
			on_action_pressed(cmd)

	elif event.is_released():
		if key_to_action.has(keycode):
			var action: String = key_to_action[keycode]
			var cmd: String = action_list_commands.get(action, "")
			if cmd.begins_with("+"):
				on_action_pressed("-" + cmd.trim_prefix("+"))

func _input(event: InputEvent) -> void:
	if not GSGlobal.menu.on_map:
		return

	if event is not InputEventMouseButton:
		return

	var button_index: int = event.button_index

	if mouse_to_action.has(button_index):
		var action: String = mouse_to_action[button_index]
		var cmd: String = action_list_commands.get(action, "")

		if event.is_pressed():
			on_action_pressed(cmd)
		elif event.is_released() and cmd.begins_with("+"):
			on_action_pressed("-" + cmd.trim_prefix("+"))

func on_action_pressed(key: String) -> void:
	if key.is_empty():
		return

	var commands: PackedStringArray = GSConsole.parse_commands_line_input(key.strip_edges())
	for command: String in commands:
		GSConsole.init_command(command)

func command_bind(arguments: Array) -> void:
	var key: String = arguments[0].to_lower()
	var value: Array = arguments.slice(1)

	if action_list_commands.has(key):
		action_list_commands[key] = " ".join(value)
		GSConsole.print_line_format("Bind", "Console", 'Bound "%s" is to "%s"' % [key, action_list_commands[key]], "green", Console.PrintTo.Godot)
	else:
		GSConsole.print_line('"%s" is not a valid key' % key, Console.PrintTo.Console)
		GSConsole.print_line_format("Error", "Console",'"%s" is not a valid key' % key, "green", Console.PrintTo.Godot)

func command_unbind(arguments: Array) -> void:
	var key: String = arguments[0]

	if action_list_commands.has(key):
		action_list_commands[key] = ""

func command_plus_forward(arguments: Array) -> void:
	wish_forward = true

func command_minus_forward(arguments: Array) -> void:
	wish_forward = false

func command_plus_back(arguments: Array) -> void:
	wish_backward = true

func command_minus_back(arguments: Array) -> void:
	wish_backward = false

func command_plus_left(arguments: Array) -> void:
	wish_left = true

func command_minus_left(arguments: Array) -> void:
	wish_left = false

func command_plus_right(arguments: Array) -> void:
	wish_right = true

func command_minus_right(arguments: Array) -> void:
	wish_right = false

func command_plus_jump(arguments: Array) -> void:
	wish_jump = true

func command_minus_jump(arguments: Array) -> void:
	wish_jump = false

func command_plus_duck(arguments: Array) -> void:
	wish_duck = true

func command_minus_duck(arguments: Array) -> void:
	wish_duck = false

func command_plus_fire(arguments: Array) -> void:
	wish_fire = true

func command_minus_fire(arguments: Array) -> void:
	wish_fire = false
