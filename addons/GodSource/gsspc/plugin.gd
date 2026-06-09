@tool
extends EditorPlugin

var dock : EditorDock

func _enter_tree() -> void:
	var dock_scene : Control = preload("./gsspc.tscn").instantiate()
	dock = EditorDock.new()
	dock.add_child(dock_scene)
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	dock.title = "GDSPC"
	dock.custom_minimum_size = Vector2i(422+150,256)
	dock.available_layouts = EditorDock.DOCK_LAYOUT_ALL
	dock.dock_icon = load("res://addons/GodSource/gsspc/assets/icons/point_fixed.svg")
	add_dock(dock)
	dock.close()


func _exit_tree():
	remove_dock(dock)
	dock.queue_free()
