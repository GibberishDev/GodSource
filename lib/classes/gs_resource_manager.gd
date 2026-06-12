extends Node
class_name GSRM
signal resource_loaded ## Emitted when threaded loading of the resource finishes. Provides [String] [u]path[/u] to the resource, [Resource] [u]loaded resource[/u] and [int] [u]timestamp[/u] when resource was requested 
signal resource_load_failed ## Emitted when threaded loading of the resource fails. Provides [String] [u]path[/u] to the resource and [enum FAIL_REASON] [u]fail reason[/u]
signal resource_load_progress_changed ## Emitted when threaded loading of the resource progress changes. Provides [String] [u]path[/u] to the resource and [float] [u]loading progress[/u] (0.0-1.0)

## Contains objects for all currently loading resources on separate threads for loading progress tracking.
## Each entry consists of a [Dictionary] with following keys:[br]
## [code]"path"[/code] - [String] filepath for resource threaded loading[br]
## [code]"wasAltered"[/code] - [bool] if resource was overriden instead of being loaded from vanilla res://[br]
## [code]"progress"[/code] - [float] Resource loading progress (0.0-1.0)[br]
## [code]"track_progress"[/code] - [bool] Decides whether progress is tracked and [signal resource_load_progress_changed] will be emitted[br]
## [code]"timestamp"[/code] - [int] timestamp when resource was requested [method Time.get_ticks_msec()]
var loading_stack : Array[Dictionary] = []
var cached_resources : Dictionary = {}

enum FAIL_REASON {
	NOT_FOUND
}

## Initiated resource load from [member path] on separate thread. 
##
##
func threaded_load(path: String, track_progress:bool=false,force_refresh:bool=false, discard_cache:bool=false) -> void:
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
		"progress":0.0,
		"track_progress":track_progress,
		"timestamp":Time.get_ticks_msec()
	})
	print(loading_stack)

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
		print(progress)
		if progress != dict["progress"] and dict["track_progress"]:
			resource_load_progress_changed.emit(dict["path"],dict["progress"])
		if progress >= 1.0:
			var res : Variant = ResourceLoader.load_threaded_get(dict["path"])
			resource_loaded.emit(dict["path"],res,dict["timestamp"])
			cached_resources[dict["path"]] = {
				"resource":res,
				"timestamp":Time.get_ticks_msec()
			}
			loading_stack.erase(dict)
			GSConsole.send_output_message("[lb]ResourceLoader[rb] loaded [b]"+dict["path"]+"[/b] in " + str(Time.get_ticks_msec() - dict["timestamp"])+"msec")
