extends Control

func load_debug_map() -> void:
	get_tree().change_scene_to_file("res://debug_scene_delete_later.tscn")

func button_quit() -> void:
	Console.process_commands(["quit"])
