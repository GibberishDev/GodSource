extends Node

const dedicated_server_scene_path : String = "lib/server/dedicated_server.tscn"
const main_menu_scene_path : String = "src/server/dedicated_server_gui.tscn"

func _ready() -> void:
	var is_dedicated : bool = OS.has_feature("dedicated")
	if !is_dedicated:
		get_tree().change_scene_to_file(main_menu_scene_path)
	else:
		get_tree().change_scene_to_file(dedicated_server_scene_path)
		
