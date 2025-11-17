extends Node

var server : ENetMultiplayerPeer

func start_server(port: int, slots: int) -> void:
	reset_multiplayer()
	if port >= 1024 and port <= 65535:
		server = ENetMultiplayerPeer.new()
		server.create_server(port, slots)
		Console.send_output_message("[color=lime]Created server at port " + str(port) + "[/color]")

		multiplayer.multiplayer_peer = server

		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
	else:
		Console.send_output_message("[color=red]Failed to create server. ERROR: Invalid port number [b]" + str(port) + ". Expected a number between 1024 and 65535[/b][/color]")
		return


func connect_to_server(ip: String, port: int) -> void:
	reset_multiplayer()
	var client_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	client_peer.create_client(ip, port)
	
	multiplayer.multiplayer_peer = client_peer
	
	multiplayer.connection_failed.connect(_client_failed_to_connect)
	multiplayer.connected_to_server.connect(_peer_connected_to_server)
	multiplayer.server_disconnected.connect(_peer_disconnected_from_server)

func _peer_connected(id: int) -> void:
	Console.send_output_message("[color=green]+++[/color] Peer connected.	Peer id: " + str(id))

func _peer_disconnected(id: int) -> void:
	Console.send_output_message("[color=red]---[/color] Peer disconnected.	Peer id: " + str(id))

func _peer_connected_to_server() -> void:
	Console.send_output_message("[color=green]Connected to server[/color]")

func _peer_disconnected_from_server() -> void:
	Console.send_output_message("[color=red]Disconnected from server[/color]")

func _client_failed_to_connect() -> void:
	Console.send_output_message("[color=red]Failed to connect to server[/color]")

func reset_multiplayer() -> void:
	if server != null:
		var peers : Array[int] = multiplayer.get_peers()
		for i : int in peers:
			server.disconnect_peer(i)
		server.close()
		server = null
	
	multiplayer.multiplayer_peer = null
	
	if multiplayer.peer_connected.is_connected(_peer_connected):
		multiplayer.peer_connected.disconnect(_peer_connected)
	if multiplayer.peer_disconnected.is_connected(_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_peer_disconnected)
	if multiplayer.connection_failed.is_connected(_client_failed_to_connect):
		multiplayer.connection_failed.disconnect(_client_failed_to_connect)
	if multiplayer.connected_to_server.is_connected(_peer_connected_to_server):
		multiplayer.connected_to_server.disconnect(_peer_connected_to_server)
	if multiplayer.server_disconnected.is_connected(_peer_disconnected_from_server):
		multiplayer.server_disconnected.disconnect(_peer_disconnected_from_server)
