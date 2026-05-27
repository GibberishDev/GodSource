extends Node3D

@export
var mesh : MeshInstance3D

func _ready() -> void:
	if find_child("test_camera") != null: $test_camera.queue_free()
	set_fov(GSConsole.convar_list["cl_viewmodelfov"]["value"])
	GSConsole.connect("convar_changed", convar_changed_notifier)

func set_fov(new_fov: float) -> void:
	new_fov= clamp(new_fov, 0.0,180.0)
	for surface : int in $mesh.mesh.get_surface_count():
		var mat : Material = $mesh.mesh.surface_get_material(surface)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("fov", new_fov)


func convar_changed_notifier(convar_name: StringName) -> void:
	if convar_name == &"cl_viewmodelfov": set_fov(GSConsole.convar_list["cl_viewmodelfov"]["value"])
