extends Node
@export
var dedicated_server_scene_path : PackedScene = null
@export
var main_menu_scene_path : PackedScene = null

func _ready() -> void:
	if dedicated_server_scene_path == null or main_menu_scene_path == null:
		print_rich("[color=red]NOT ENOUGH PACKED SCENES DEFINED FOR SUCCESSFUL STARTUP. TERMINATING")
		get_tree().quit()
	var is_dedicated : bool = OS.has_feature("dedicated")
	if !is_dedicated:
		get_tree().change_scene_to_packed(main_menu_scene_path)
	else:
		get_tree().change_scene_to_packed(dedicated_server_scene_path)
		
