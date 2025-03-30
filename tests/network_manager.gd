extends Node

var _enet_network = preload("res://tests/enet_network.tscn")
var is_host : bool = false

const DEBUG_SCENE : String = "res://tests/game.tscn"

func single_player() -> void:
	is_host = true
	print_rich("[color=gold][lb]GODSOURCE[rb]: launched singleplayer instance. Networking is off")
	

func host_game() -> void:
	is_host = true
	var active_network = _enet_network.instantiate()
	add_child(active_network)
	active_network.create_server_peer()
	print_rich("[color=light_blue][lb]DEDICATED SERVER[rb]: launched dedicated server at "+str(active_network.SERVER_IP)+":"+str(active_network.SERVER_PORT))
	 

func join_game() -> void:
	is_host = false
	get_tree().call_deferred(&"change_scene_to_packed", preload(DEBUG_SCENE))
	
	var active_network = _enet_network.instantiate()
	add_child(active_network)
	active_network.create_client_peer()
	
