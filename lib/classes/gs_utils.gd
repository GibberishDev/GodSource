extends Node

var environment : ENV
enum ENV {
	CLIENT, ## Headless version of the game used to host dedicated servers
	SERVER,
	HOST
}


func to_hammer(meters: float) -> float:
	return (meters / 1.905 * 100.0)

func to_meters(hammer_units: float) -> float:
	return (hammer_units * 1.905 / 100.0)

## [b][u]PURPOSE[/u][/b]:
## [br]Sorts arrays by [method Array.size] from biggest to smallest
func sort_array_of_arrays(a: Array, b: Array) -> bool:
	if a.size() > b.size(): return true
	return false
## [b][u]PURPOSE[/u][/b]:
## [br]Sorts arrays by [method String.length] from biggest to smallest
func sort_array_of_strings(a: String, b: String) -> bool:
	if a.length() > b.length(): return true
	return false

func _ready() -> void:
	environment = determine_environment()

func determine_environment() -> ENV:
	var is_dedicated : bool = OS.has_feature("dedicated")
	if is_dedicated:
		return ENV.SERVER
	return ENV.CLIENT