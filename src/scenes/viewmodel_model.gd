@tool
extends Node3D

@export
var viewmodel_shader : ShaderMaterial
@export_tool_button("Convert mesh shaders to viewmodel shders","") var convert_action : Callable = tool_load_viewmodel

func _ready() -> void:
	if Engine.is_editor_hint() : return
	if find_child("test_camera") != null: $test_camera.queue_free()
	#set_fov(GSConsole.convar_list["cl_viewmodelfov"]["value"])
	GSConsole.connect("convar_changed", convar_changed_notifier)

func set_fov(new_fov: float) -> void:
	new_fov= clamp(new_fov, 0.0,180.0)
	for surface : int in $mesh.mesh.get_surface_count():
		var mat : Material = $mesh.mesh.surface_get_material(surface)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("fov", new_fov)

func convar_changed_notifier(convar_name: StringName) -> void:
	if convar_name == &"cl_viewmodelfov": set_fov(GSConsole.convar_list["cl_viewmodelfov"]["value"])

func tool_load_viewmodel() -> void:
	var GLTFScene : Node = load("res://assets/viewmodels/test/test.glb").instantiate()
	if find_children("meshes") != []: remove_child($meshes)
	var meshes_node : MeshInstance3D = MeshInstance3D.new()
	meshes_node.name = "meshes"
	self.add_child(meshes_node)
	$meshes.owner = get_tree().edited_scene_root
	EditorInterface.mark_scene_as_unsaved()

	for node : Node in GLTFScene.get_children():
		if node is MeshInstance3D:
			var dupe : MeshInstance3D = node.duplicate()
			$meshes.add_child(dupe)
			dupe.owner = get_tree().edited_scene_root
			dupe.resource_local_to_scene = true
			EditorInterface.mark_scene_as_unsaved()
			dupe.mesh.resource_local_to_scene = true
			for i: int in dupe.mesh.get_surface_count():
				var temp : Material = dupe.mesh.surface_get_material(i)

				var new_shader : ShaderMaterial = ShaderMaterial.new()
				new_shader.shader = viewmodel_shader.shader
				dupe.mesh.surface_set_material(i, new_shader)
				copy_shader(temp, new_shader)

func copy_shader(source: StandardMaterial3D, destination: ShaderMaterial) -> void:
	# albedo
	destination.set_shader_parameter("albedo",source.albedo_color)
	destination.set_shader_parameter("texture_albedo",source.albedo_texture)
	destination.set_shader_parameter("roughness",source.roughness)
	destination.set_shader_parameter("texture_metallic",source.metallic_texture)
	destination.set_shader_parameter("metallic_texture_channel",source.metallic_texture_channel)
	destination.set_shader_parameter("texture_roughness",source.roughness_texture)
	destination.set_shader_parameter("roughness_texture_channel",source.roughness_texture_channel)
	destination.set_shader_parameter("roughness_texture_channel",source.roughness_texture_channel)
	destination.set_shader_parameter("specular",source.metallic_specular)
	if source.emission_enabled:
		destination.set_shader_parameter("emission_enabled",true)
		if source.emission_texture != null:
			destination.set_shader_parameter("emission",Color.BLACK)
			destination.set_shader_parameter("texture_emission",source.emission_texture)
		else:
			destination.set_shader_parameter("emission",source.emission)
		destination.set_shader_parameter("emission_energy",source.emission_energy_multiplier)
	if source.normal_enabled:
		destination.set_shader_parameter("normal_enabled",true)
		destination.set_shader_parameter("texture_normal",source.normal_texture)
		destination.set_shader_parameter("normal_scale",source.normal_scale)
	if source.bent_normal_enabled:
		destination.set_shader_parameter("bent_normal_enabled",true)
		destination.set_shader_parameter("texture_bent_normal",source.bent_normal_texture)
	if source.rim_enabled:
		destination.set_shader_parameter("rim_enabled",true)
		destination.set_shader_parameter("rim",source.rim)
		destination.set_shader_parameter("rim_tint",source.rim_tint)
		destination.set_shader_parameter("texture_rim",source.rim_texture)
	if source.clearcoat_enabled:
		destination.set_shader_parameter("clearcoat_enabled",true)
		destination.set_shader_parameter("clearcoat",source.clearcoat)
		destination.set_shader_parameter("clearcoat_roughness",source.clearcoat_roughness)
		destination.set_shader_parameter("texture_clearcoat",source.clearcoat_texture)
	# if source.anisotropy_enabled:
	# 	destination.set_shader_parameter("anisotropy_enabled",true)
	# 	destination.set_shader_parameter("anisotropy_ratio",source.anisotropy)
	# 	destination.set_shader_parameter("texture_flowmap",source.anisotropy_flowmap)
	if source.ao_enabled:
		destination.set_shader_parameter("ao_enabled",true)
		destination.set_shader_parameter("texture_ambient_occlusion",source.ao_texture)
		destination.set_shader_parameter("ao_texture_channel",source.ao_texture_channel)
		destination.set_shader_parameter("al_light_affect",source.ao_light_affect)
	if source.detail_enabled:
		destination.set_shader_parameter("detail_enabled",true)
		destination.set_shader_parameter("texture_detail_albedo",source.detail_albedo)
		destination.set_shader_parameter("texture_detail_normal",source.detail_normal)
		destination.set_shader_parameter("texture_detail_mask",source.detail_mask)
		destination.set_shader_parameter("detail_mode",source.detail_blend_mode)
	if source.subsurf_scatter_enabled:
		destination.set_shader_parameter("subsurface_enabled",true)
		destination.set_shader_parameter("subsurface_scattering_strength",source.subsurf_scatter_strength)
		destination.set_shader_parameter("texture_subsurface_scattering",source.subsurf_scatter_texture)
	if source.backlight_enabled:
		destination.set_shader_parameter("backlight_enabled",true)
		destination.set_shader_parameter("backlight",source.backlight)
		destination.set_shader_parameter("texture_backlight",source.backlight_texture)
	if source.heightmap_enabled:
		destination.set_shader_parameter("heightmap_enabled",true)
		destination.set_shader_parameter("texture_heightmap",source.heightmap_texture)
		destination.set_shader_parameter("heightmap_scale",source.heightmap_scale)
		if source.heightmap_flip_texture:
			destination.set_shader_parameter("heightmap_flip", Vector2(1,1))
		else:
			destination.set_shader_parameter("heightmap_flip", Vector2(0,0))
	destination.set_shader_parameter("uv1_scale",source.uv1_scale)
	destination.set_shader_parameter("uv1_offset",source.uv1_offset)
	destination.set_shader_parameter("uv2_scale",source.uv2_scale)
	destination.set_shader_parameter("uv2_offset",source.uv2_offset)
# UNDO REDO https://godotforums.org/d/41196-undoredo-and-tool-scripts
	
