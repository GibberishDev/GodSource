class_name GSViewmodel
extends Node3D

@onready
var viewport : SubViewport = get_node("viewport_container/viewport")
@onready
var cam : Camera3D = viewport.get_node("viewmodel_camera")
@onready
var models : Node = viewport.get_node("models")

func _ready() -> void:
	get_viewport().get_window().size_changed.connect(change_viewport_size)
	GSResourceManager.resource_loaded.connect(loaded_model)
	await get_tree().create_timer(5).timeout
	load_viemodel("a")

func change_viewport_size() -> void:
	viewport.size = get_viewport().get_window().size

func _process(delta: float) -> void:
	cam.global_transform = get_parent().global_transform
	models.global_transform = get_parent().global_transform

func load_viemodel(id: String) -> void:
	GSResourceManager.threaded_load("res://assets/viewmodels/shotgun/shotgun.glb")
	
func loaded_model(path: String, res: Resource, timestamp: int) -> void:
	var GLTFScene : Node = res.instantiate()
	for i: Node in models.get_children(): i.queue_free()
	for node : Node in GLTFScene.get_children():
		if node is MeshInstance3D:
			var dupe : MeshInstance3D = node.duplicate()
			models.add_child(dupe)
			dupe.owner = get_tree().edited_scene_root
			dupe.mesh.resource_local_to_scene = true
	
