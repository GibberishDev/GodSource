class_name DedicatedServer
extends Node

var input_thread : Thread;
var escape: String = PackedByteArray([0x1b]).get_string_from_ascii()

func _ready() -> void:
	print(IP.resolve_hostname("www.google.com", IP.TYPE_IPV4))
	
	if DisplayServer.get_name() == "headless":
		printraw(escape + "[2J" + escape + "[;H")
		print_rich("[color=green]Staring Godsource " + ProjectSettings.get_setting("application/config/version") +  " in CLI mode.")
		input_thread = Thread.new()
		input_thread.start(_cli_input)
	else:
		print("Display server: ", DisplayServer.get_name())
		MultiplayerManager.join_server()
		

func _cli_input() -> void:
	if OS.is_debug_build() and OS.has_feature("editor"):
		print_rich("[color=red]Godot terminal doesnt support terminal input. Shutting down input thread...[/color]\r\n")
		return
	var text : String = ""
	while text != "quit":
		printraw.call_deferred("> ")
		text = OS.read_string_from_stdin(4096).strip_edges()
		#add command processor here
		if text != "quit":
			match text:
				"clear":
					printraw(escape + "[2J" + escape + "[;H")
				"start":
					print_rich("[color=green]Starting godsource server[/color]")
					MultiplayerManager.start_dedicated_server.call_deferred()
				"stop":
					print_rich("[color=red]Stopping godsource server[/color]")
					MultiplayerManager.stop_dedicated_server.call_deferred()
				"list":
					MultiplayerManager.get_connected_peers.call_deferred()
				_:
					text = text.replace("[", "[\u200b")
					text = text.replace("]", "\u200b]")
					print_rich("[color=yellow]Unrecognized command: \"[b]" + text + "[/b]\"[/color]")
	if text == "quit":
		print_rich("[color=red]Shutting down server ...[/color]")
		get_tree().quit()

func _exit_tree() -> void:
	if DisplayServer.get_name() == "headless":
		input_thread.wait_to_finish()
