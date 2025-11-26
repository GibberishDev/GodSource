extends Node

##Global class to load and maintain game configuration. Load .cfg files, provide configuration variables to the rest of the app

func load_cfg_file(path: String) -> void:
	if !path.ends_with(".cfg"):
		path += ".cfg"
	if !FileAccess.file_exists("res://src/cfg/" + path):
		GSConsole.send_output_message("ERROR: file not found")
		return
	var config_text : String = FileAccess.get_file_as_string("res://src/cfg/" + path)
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
	process_commands(commands)

func process_commands(commands: PackedStringArray) -> void:
	for i : String in commands:
		if !GSConsole.process_input(i):
			GSConsole.send_output_message("[color=pink]Error processing exec file at:[/color]\n [color=red]>>> \"" + i +"\"[/color]") 
			return