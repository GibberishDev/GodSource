extends Node

const PLAYER_SCENE: PackedScene = preload("res://src/client/gs_player.tscn")
const SERVER_PORT: int = 3650
const SERVER_IP: String = "127.0.0.1"

var dedicated_server_instance: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func start_dedicated_server() -> void: # Move into dedicated server scripts to reduce dedicated server file size
	dedicated_server_instance.create_server(SERVER_PORT, 8)
	
	multiplayer.multiplayer_peer = dedicated_server_instance
	
	print_rich("Created server at [color=cyan]" + str(SERVER_IP) + ":" + str(SERVER_PORT) + "[/color]")
	
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	

func stop_dedicated_server() -> void:
	multiplayer.multiplayer_peer = dedicated_server_instance
	multiplayer.peer_connected.disconnect(_peer_connected)
	multiplayer.peer_disconnected.disconnect(_peer_disconnected)
	dedicated_server_instance.close() # write normal people handling closing server. Use ".close()" as crash handling measure.

func get_connected_peers() -> void:
	var peers : PackedInt32Array
	
	multiplayer.multiplayer_peer = dedicated_server_instance
	peers = multiplayer.get_peers()
	
	for i: int in range(peers.size()):
		var output: String = "Peer id: "
		output += str(peers[i])
		output += " - ping: " + str(dedicated_server_instance.get_peer(peers[i]).get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME))
		output += " - ip: " + str(dedicated_server_instance.get_peer(peers[i]).get_remote_address())
		
		print_rich(output)

func host_server() -> void:
	pass
	

func join_server() -> void:
	var client_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	client_peer.create_client("188.242.90.209", SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer
	
	multiplayer.connected_to_server.connect(_peer_connected_to_server)
	multiplayer.server_disconnected.connect(_peer_disconnected_from_server)
	
	print(client_peer)
	

func _peer_connected(id: int) -> void: # Duplicate into dedicated server scripts to reduce dedicated server file size
	print_rich("peer connected. id: [color=green] +++ " + str(id)+ "[/color]")
	var player: Node = PLAYER_SCENE.instantiate()
	player.peer_id = id
	player.name = str(id)
	get_tree().root.get_node("Node3D/Players").add_child(player, true)
	
func _peer_disconnected(id: int) -> void: # Duplicate into dedicated server scripts to reduce dedicated server file size
	print_rich("peer diconnected. id: [color=red] --- " + str(id)+ "[/color]")

func _peer_connected_to_server() -> void:
	print_rich("[color=green]CONNECTED TO SERVER: " + str(SERVER_IP) + ":" + str(SERVER_PORT) + "[/color]")

func _peer_disconnected_from_server() -> void:
	print_rich("[color=red]CONNECTION RESET BY SERVER.[/color]")
