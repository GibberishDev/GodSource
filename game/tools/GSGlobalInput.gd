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

func _ready() -> void:
	for element: String in action_list.keys():
		var event: InputEventKey = InputEventKey.new()
		event.keycode = action_list[element]
		InputMap.add_action(element)
		InputMap.action_add_event(element, InputEventKey.new())

	for element: String in action_list.keys():
		action_list_commands[element] = ""
	
	GSGlobal.console.add_command("bind", command_bind, -1, 2)

func _input(event: InputEvent) -> void:
	if event.is_pressed() and !event.is_echo():
		if event is InputEventKey:
			for key: String in action_list.keys():
				if event.get_keycode_with_modifiers() == action_list[key]:
					on_action_pressed(action_list_commands[key])
		if event is InputEventMouseButton:
			for key: String in action_list.keys():
				if event.button_index == action_list[key]:
					on_action_pressed(action_list_commands[key])
	elif event.is_released():
		if event is InputEventKey:
			for key: String in action_list.keys():
				if event.get_keycode_with_modifiers() == action_list[key]:
					if action_list_commands[key].begins_with("+"):
						on_action_pressed("-" + action_list_commands[key].erase(0, 1))
		if event is InputEventMouseButton:
			for key: String in action_list.keys():
				if event.button_index == action_list[key]:
					if action_list_commands[key].begins_with("+"):
						on_action_pressed("-" + (action_list_commands[key]).erase(0, 1))

func on_action_pressed(key: String) -> void:
	var commands: PackedStringArray = GSGlobal.console.parse_commands_line_input(key.strip_edges())
	for command: String in commands:
		GSGlobal.console.init_command(command)

func command_bind(arguments: Array) -> void:
	var key: String = arguments[0]
	var value: Array = arguments.slice(1, arguments.size())

	if action_list_commands.has(key):
		action_list_commands.set(key, " ".join(value))
	else:
		GSGlobal.console.print_line('"%s" isnt a valid key' % [key])
