extends Node

func _ready() -> void:
	var is_dedicated : bool = OS.has_environment("dedicated")
	if !is_dedicated:
		#change scene
		#load resources
		#load main menu
		pass
	else:
		#load dedicated server
		pass