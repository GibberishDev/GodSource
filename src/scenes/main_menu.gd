extends Control

func load_debug_map() -> void:
	var packed_scene_debug : PackedScene = load("res://debug_scene_delete_later.tscn")
	var debug_level : Node3D = packed_scene_debug.instantiate()
	get_tree().root.add_child(debug_level)
	GSUi.hide_ui()
	$cont_1/VBoxContainer/start.visible = false

func button_quit() -> void:
	GSConsole.process_commands(["quit"])
