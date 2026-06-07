@tool
extends EditorPlugin

const PLUGIN_NAME = "GodSource"

func _enable_plugin() -> void:
	EditorInterface.set_plugin_enabled(PLUGIN_NAME + "/gsspc", true)


func _disable_plugin() -> void:
	EditorInterface.set_plugin_enabled(PLUGIN_NAME + "/gsspc", false)


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
