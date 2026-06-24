@tool
class_name GSHitscanSpawner extends Node3D
@onready
var pattern_json : JSON = preload("res://src/data/spread_patterns/tf_shotgun_square.json")
@onready
var tracer_scene : PackedScene = preload("res://src/scenes/bullet_tracer.tscn")
var pattern : Dictionary = {}
var random_spread_range : float = 2.0 ##Random bullet spread in degrees

func shoot() -> void:
	pattern = pattern_json.data
	var rays : Array[RayCast3D] = []
	if pattern.is_empty(): return;
	if !pattern.has("points") or pattern["points"].is_empty(): return
	var is_random : bool = !GSConsole.convar_list["gs_use_fixed_bullet_spread"]["value"]
	if pattern.has("is_burst") and !pattern["is_burst"]:
		pass
	else:
		for point : Dictionary in pattern["points"]:
			var ray : RayCast3D = RayCast3D.new()
			ray.collide_with_areas = true
			ray.collide_with_bodies = true
			ray.set_collision_mask_value(1,true)
			ray.set_collision_mask_value(3,true)
			ray.set_collision_mask_value(5,true)
			ray.set_collision_mask_value(6,true)
			ray.set_collision_mask_value(7,true)
			ray.hit_back_faces = true
			ray.debug_shape_custom_color = Color(1.0,0.5,0.0,0.5)
			ray.target_position = Vector3(0, 0, -1000)
			self.add_child(ray)
			rays.append(ray)
			if is_random:
				if point["fixed"]:
					ray.rotate_x(deg_to_rad(point["pitch"]))
					ray.rotate_z(deg_to_rad(point["roll"]))
				else:
					ray.rotate_x(deg_to_rad(random_spread_range * randf()))
					ray.rotate_z(deg_to_rad(360.0 * randf()))
			else:
				ray.rotate_x(deg_to_rad(point["pitch"]))
				ray.rotate_z(deg_to_rad(point["roll"]))
	for ray : RayCast3D in rays:
		ray.force_raycast_update()
		if ray.get_collider() != null:
			var tracer : Node3D = tracer_scene.instantiate()
			get_tree().root.get_node("GameRoot/Node3D").add_child(tracer)
			tracer.speed = 115.0
			tracer.scale_up_period = 2
			tracer.launch(ray.get_collision_point(),get_parent().get_parent().viewmodel.get_node("tracer_spawner").global_position)
			var collider : Variant = ray.get_collider()
			if collider is Area3D and collider.get_parent().has_method("_on_hit"):
				collider.get_parent()._on_hit(collider)
			ray.target_position = Vector3(0,0,-(ray.global_position.distance_to(ray.get_collision_point())))
		else:
			var tracer : Node3D = tracer_scene.instantiate()
			get_tree().root.get_node("GameRoot/Node3D").add_child(tracer)
			tracer.speed = 115.0
			tracer.scale_up_period = 2
			tracer.launch(ray.target_position.rotated(Vector3.RIGHT, ray.global_rotation.x).rotated(Vector3.UP, ray.global_rotation.y),get_parent().get_parent().viewmodel.get_node("tracer_spawner").global_position)
		if GSConsole.convar_list["debug_drawhitscan"]["value"]:
			ray.reparent(get_tree().root.get_node("GameRoot/Node3D"))
			var timer : SceneTreeTimer = get_tree().create_timer(3.0)
			timer.timeout.connect(func () -> void:ray.queue_free())
		else:
			ray.queue_free()

					


func set_pattern(id: String) -> void:
	if pattern.has("rbs_range"):
		random_spread_range = float(pattern["rbs_range"])
	pass
