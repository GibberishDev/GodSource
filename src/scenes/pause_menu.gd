extends Control

func resume() -> void:
	GSUi.hide_ui()

func button_quit() -> void:
	GSConsole.process_commands(["quit"])
