extends Control
const DEBUG_SCENE : String = "res://tests/game.tscn"

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print_rich("[color=gold][lb]GODSOURCE[rb]: launching dedicated server...")
		NetworkManager.host_game()
		get_tree().call_deferred(&"change_scene_to_packed", preload(DEBUG_SCENE))

func _on_signle_player() -> void:
	NetworkManager.single_player()
	get_tree().call_deferred(&"change_scene_to_packed", preload(DEBUG_SCENE))
	

func _on_host_game() -> void:
	NetworkManager.host_game()
	get_tree().call_deferred(&"change_scene_to_packed", preload(DEBUG_SCENE))

func _on_join_game() -> void:
	NetworkManager.join_game()

func _on_exit() -> void:
	get_tree().quit(0)
