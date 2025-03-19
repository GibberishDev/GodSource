@tool
class_name GSLiquidBrush
extends Node3D

## Size of water block in Hammer units
@export var cube_size: Vector3i = Vector3i(50, 50, 50) : set = set_size
@export var water_drag: float = 0.0

var top: float = 0.0
var bot: float = 0.0

func set_size(value: Vector3i) -> void:
	cube_size = value
	%vis.mesh.size = cube_size * 1.905 / 100
	%vis.position.y = cube_size.y * 1.905 / 200
	%shape.shape.size = cube_size * 1.905 / 100
	%shape.position.y = cube_size.y * 1.905 / 200

func _ready() -> void:
	bot = global_position.y
	top = bot + (cube_size.y * 1.905 / 100)
