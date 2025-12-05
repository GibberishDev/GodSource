extends Node

##Global class to load and maintain game configuration. Load .cfg files, provide configuration variables to the rest of the app

var current_config : String = ""

func load_cfg_file(cfg_name: String) -> void:
	if !cfg_name.ends_with(".cfg"):
		cfg_name += ".cfg"
	var path : String = get_config_folder() + cfg_name
	if !FileAccess.file_exists(path):
		path = "res://src/cfg/" + cfg_name
		if !FileAccess.file_exists(path):
			GSConsole.send_output_message("ERROR: file not found at path \"" + path + "\"")
			return
	var config_text : String = FileAccess.get_file_as_string(path)
	var config_lines : Array = config_text.split("\n")
	var commands : PackedStringArray = []
	var regex : RegEx = RegEx.new()
	regex.compile("(?:^).*?(?:(?:(?<!(\\\"|\\\'))(?:[\\#])(?!.*(\\\"|\\\')))|$)") #Im bad at regex...
	for i : String in config_lines:
		var regex_match : String = regex.search(i).get_string()
		if regex_match.ends_with("#"):
			regex_match = regex_match.left(regex_match.length() - 1)
		regex_match = regex_match.strip_edges()
		if regex_match != "": commands.append(regex_match)
	process_commands(commands, cfg_name)

func process_commands(commands: PackedStringArray, filename: String) -> void:
	for i : String in commands:
		if !GSConsole.process_input(i):
			GSConsole.send_output_message("[color=pink]Error processing exec file \"" + filename + "\" at:[/color]\n [color=red]>>> \"" + i +"\"[/color]") 
			return

func get_config_folder() -> String:
	if OS.has_feature("editor"):
		return "res://src/cfg/"
	else:
		var exec_dir : DirAccess = DirAccess.open(OS.get_executable_path().get_base_dir())
		var error : Error
		if !exec_dir.dir_exists(ProjectSettings.get("application/config/godsource_id") + "/cfg"):
			error = exec_dir.make_dir_recursive(ProjectSettings.get("application/config/godsource_id") + "/cfg")
		if error == OK:
			return "./" + ProjectSettings.get("application/config/godsource_id") + "/cfg/"
		else:
			push_error("COULD NOT CREATE CFG FOLDER")
			return ""

func apply_saved_settings() -> void:
	if OS.has_feature("editor"):
		print("Game running in editor. Applying default settings...")
		var output_string : String = ""

		for i : StringName in GSConsole.convar_list.keys():
			if GSConsole.convar_list[i]["flags"].has(GSConsole.CONVAR_FLAGS.SETTING):
				output_string += i + " " + GSConsole.get_convar_text_value(i) + "\n"

		current_config += output_string
		load_cfg_file("default")
		print(current_config)
		return