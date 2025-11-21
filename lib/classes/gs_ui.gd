extends Control

var opened_windows : Dictionary = {}
var focused_window : GSUIWindow = null

func add_window(window_contents_scene : PackedScene, default_size: Vector2, window_name: String, id: StringName) -> void:
	var ui_window_scene : PackedScene = load("res://lib/client/ui_window.tscn")
	var window : GSUIWindow = ui_window_scene.instantiate()
	window.name = id
	window.set_window_name(window_name)
	window.default_size = default_size
	window.add_contents(window_contents_scene)
	get_node("ui_windows").add_child(window)
	opened_windows[id] = window

func has_window(id: StringName) -> bool:
	return opened_windows.keys().has(id)

func show_ui() -> void:
	get_node("ui_windows").visible = true
	get_node("menu").visible = true
	GSInput.current_input_context = GSInput.INPUT_CONTEXT.UI
	GSInput.release_mouse()

func hide_ui() -> void:
	get_node("ui_windows").visible = false
	get_node("menu").visible = false
	GSInput.current_input_context = GSInput.INPUT_CONTEXT.CHARACTER

func show_window(id: StringName) -> void:
	var window : GSUIWindow = opened_windows[id]
	window.visible = true
	focused_window = window

func hide_window(id: StringName) -> void:
	var window : GSUIWindow = opened_windows[id]
	window.visible = false
	focused_window = null #TODO: change to be previously focused window instead

func cancelselect() -> void:
	focused_window = null

func ask_focus(window: GSUIWindow) -> void:
	if focused_window != null:
		focused_window.set_focused(false)
	focused_window = window
	window.set_focused(true)
	get_node("ui_windows").move_child(window, -1)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and GSInput.current_input_context == GSInput.INPUT_CONTEXT.UI and event.pressed:
		var window_id : StringName = get_window_at_position(event.global_position)
		if window_id != "":
			ask_focus(opened_windows[window_id])
		else:
			unfocus_all_windows()

func unfocus_all_windows() -> void:
	for i : StringName in opened_windows.keys():
		opened_windows[i].set_focused(false)
	focused_window = null

func get_window_at_position(point: Vector2) -> StringName:
	var clicked_windows : Array = []
	for i : StringName in opened_windows.keys():
		if opened_windows[i].get_global_rect().has_point(point):
			clicked_windows.append(i)
	var node_order : Array = []
	for i : Object in get_node("ui_windows").get_children():
		node_order.append(i.name)
	var window_ids : Array = []
	for i : StringName in clicked_windows:
		window_ids.append(node_order.find(i))
	if window_ids.size() > 0: return clicked_windows[window_ids.find(window_ids.max())]
	return ""
	
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var node : Control = Control.new()
	node.name = "hud"
	node.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	self.add_child(node)
	node = Control.new()
	node.name = "menu"
	node.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	self.add_child(node)
	node = Control.new()
	node.name = "ui_windows"
	node.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.add_child(node)
	var main_menu_scene : PackedScene = load("res://src/scenes/main_menu.tscn")
	node = main_menu_scene.instantiate()
	get_node("menu").add_child(node)
