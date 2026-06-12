class_name GSViewmodel
extends Node3D

@onready
var models : Node = get_node("models")

func _ready() -> void:
	GSResourceManager.resource_loaded.connect(loaded_model)
	GSConsole.connect("convar_changed", convar_changed_notifier)

#func _process(delta: float) -> void:
	#models.global_transform = get_parent().global_transform

func convar_changed_notifier(convar_name: StringName) -> void:
	if convar_name == &"cl_viewmodelfov":
		change_model_fov_override(models)

func load_viemodel(id: String) -> void:
	GSResourceManager.threaded_load("res://assets/viewmodels/shotgun/shotgun.glb")
	
func loaded_model(path: String, res: Resource, timestamp: int) -> void:
	if path.find(".glb",-1) == -1: return
	var GLTFScene : Node = res.instantiate()
	for i: Node in models.get_children(): i.queue_free()
	
	for node : Node in GLTFScene.get_children():
		var dupe : Node = node.duplicate()
		if dupe is AnimationPlayer:
			dupe.current_animation = &"idle"
			dupe.get_animation(&"idle").loop_mode = Animation.LOOP_LINEAR
		models.add_child(dupe)
		dupe.owner = get_tree().edited_scene_root
	process_models(models)
	change_model_fov_override(models)

func process_models(parent_node: Node) -> void:
	for node: Node in parent_node.get_children():
		if node.get_child_count() > 0: process_models(node)
		if node is MeshInstance3D:
			for i: int in node.mesh.get_surface_count():
				if node.mesh.surface_get_material(i) is StandardMaterial3D:
					var mat : StandardMaterial3D = node.mesh.surface_get_material(i)
					mat.use_z_clip_scale = true
					mat.z_clip_scale = 0.9
					mat.render_priority = 10
					mat.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
					mat.stencil_reference = 1
					mat.stencil_flags = 6

func change_model_fov_override(parent_node: Node) -> void:
	for node: Node in parent_node.get_children():
		if node.get_child_count() > 0: change_model_fov_override(node)
		if node is MeshInstance3D:
			for i: int in node.mesh.get_surface_count():
				if node.mesh.surface_get_material(i) is StandardMaterial3D:
					var mat : StandardMaterial3D = node.mesh.surface_get_material(i)
					mat.fov_override = GSConsole.convar_list["cl_viewmodelfov"]["value"]
	
