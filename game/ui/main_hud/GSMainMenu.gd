extends Control

@export var background: TextureRect

func _ready() -> void:
	var backgounds_array: Array = DirAccess.open("res://game/ui/main_hud/sprites/backgrounds/").get_files()

	for element: String in backgounds_array:
		if element.ends_with(".import"):
			backgounds_array.erase(element)
		
	for element: String in backgounds_array:
		if !element.contains("widescreen"):
			backgounds_array.erase(element)

	background.texture = load("res://game/ui/main_hud/sprites/backgrounds/" + backgounds_array.pick_random())

func _process(delta: float) -> void:
	background.visible = false if GSGlobal.menu.on_map else true
	%"Leave From Map".visible = true if GSGlobal.menu.on_map else false

func _on_start_server_pressed() -> void:
	GSConsole.command_map(["test"])

func _on_open_console_pressed() -> void:
	if !GSConsole.visible:
		GSConsole.toggle_console()

func _on_exit_pressed() -> void:
	GSConsole.command_quit([])

func _on_leave_from_map_pressed() -> void:
	GSConsole.command_disconnect([])
