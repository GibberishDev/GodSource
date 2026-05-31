extends Node

signal resource_loaded
signal resource_load_failed
signal resource_load_progress_changed

var loading_stack : Array[Dictionary] = []
var cached_resources : Dictionary = {}

enum FAIL_REASON {
	NOT_FOUND
}

func threaded_load(path: String, track_progress:bool=false) -> void:
	# TODO: make resource loader cache loaded resources or have option to discard on load finish. if cached whether to return cached or reload
	var verified_path : String = verify_path(path)
	if verified_path == "null":
		GSConsole.send_output_message("[color=red][lb]ResourceLoader[rb] Cant find resource at path: [b]"+path+"[/b][/color]")
		resource_load_failed.emit(path,FAIL_REASON.NOT_FOUND)
		return
	ResourceLoader.load_threaded_request(path,"",false,ResourceLoader.CACHE_MODE_IGNORE)
	loading_stack.push_back({
		"path":path,
		"wasAltered":false, #for when resource loading was altered by mods
		"resource":null,
		"progress":0.0,
		"track_progress":track_progress,
		"timestamp":Time.get_ticks_msec()
	})

func _process(delta: float) -> void:
	check_load()
	

func verify_path(path: String) -> String:
	# TODO: mod loading and resource overrides
	if path.find("res://",0) != -1 and ResourceLoader.exists(path):
		return path
	else:
		return "null"

func check_load() -> void:
	for dict:Dictionary in loading_stack:
		var progress : float = ResourceLoader.load_threaded_get_status(dict["path"])
		if progress != dict["progress"] and dict["track_progress"]:
			resource_load_progress_changed.emit(dict["path"],dict["progress"])
		if progress == 1.0:
			dict["resource"] = ResourceLoader.load_threaded_get(dict["path"])
			resource_loaded.emit(dict["path"],dict["resource"],dict["timestamp"])
			cached_resources[dict["path"]] = {
				"resource":dict["resource"],
				"timestamp":Time.get_ticks_msec()
			}
			loading_stack.erase(dict)
			GSConsole.send_output_message("[lb]ResourceLoader[rb] loaded [b]"+dict["path"]+"[/b] in " + str(Time.get_ticks_msec() - dict["timestamp"])+"msec")
