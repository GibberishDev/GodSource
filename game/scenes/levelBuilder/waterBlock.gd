@tool
class_name GSLiquidBrush
extends Node3D

@export
## Size of water block in Hammer units
var cubeSize : Vector3i = Vector3i(50,50,50) : set = setSize

func setSize(val: Vector3i) -> void:
	cubeSize = val
	%vis.mesh.size = cubeSize * 1.905 / 100
	%vis.position.y = cubeSize.y * 1.905 / 200
	%shape.shape.size = cubeSize * 1.905 / 100
	%shape.position.y = cubeSize.y * 1.905 / 200

func _ready() -> void:
	bot = global_position.y
	top = bot + (cubeSize.y * 1.905 / 100)

@export
var waterDrag : float = 0.0
var top : float = 0.0
var bot : float = 0.0
