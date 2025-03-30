extends Node

var player_scene = preload("res://game/scenes/entities/GSPlayer.tscn")

@export var player_node : Node3D

var players_dict : Dictionary = {}

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
	if NetworkManager.is_host:
		_peer_connected(1)

func _peer_connected(peer_network_id: int) -> void:
	print_rich("[color=light_blue][lb]DEDICATED SERVER[rb]: [color=green]+++[color=light_blue] peer connected. peer id: " + str(peer_network_id))
	var player_to_add = player_scene.instantiate()
	player_to_add.name = str(peer_network_id)
	player_to_add.position = Vector3i(0, 5, 0)
	players_dict[peer_network_id] = player_to_add
	player_node.add_child(player_to_add)


func _peer_disconnected(peer_network_id: int) -> void:
	print_rich("[color=light_blue][lb]DEDICATED SERVER[rb]: [color=red]---[color=light_blue] peer disconnected. peer id: " + str(peer_network_id))
	var player_to_remove = players_dict[peer_network_id]
	player_to_remove.queue_free()
	players_dict.erase(peer_network_id)
