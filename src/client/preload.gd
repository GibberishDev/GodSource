extends Node

func _ready() -> void:
#	Determine if run with dedicated server tag
	if OS.get_cmdline_args().has("--dedicated"):
		load_dedicated_server()
	else:
		load_main_menu()

func load_dedicated_server() -> void:
	print("dedicated")
	pass

func load_main_menu() -> void:
	print("client")
	pass
