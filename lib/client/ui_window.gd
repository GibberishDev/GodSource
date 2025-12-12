class_name GSUIWindow
extends Control

var id : StringName = ""
var window_focus : bool = false
@export
var limit_to_screen : bool = true
@export
var default_size : Vector2 = Vector2(500,250)

var drag_window_enabled : bool = false
var drag_start_position : Vector2 = Vector2.ZERO
var drag_mouse_offset : Vector2 = Vector2.ZERO
var resize_window_enabled : bool = false
var resize_start_size : Vector2 = Vector2.ZERO

func _ready() -> void:
	get_tree().root.connect("size_changed", _on_app_window_resize)
	reset_resize()
	center_window()
	set_focused(true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and !event.pressed:
		drag_window_enabled = false
		resize_window_enabled = false
	if event is InputEventMouseMotion and drag_window_enabled:
		var new_pos : Vector2 = event.global_position - drag_mouse_offset
		if limit_to_screen:
			new_pos.x = clamp(new_pos.x, 0, get_tree().root.size.x - size.x)
			new_pos.y = clamp(new_pos.y, 0, get_tree().root.size.y - size.y)
		global_position =  new_pos
	if event is InputEventMouseMotion and resize_window_enabled:
		var new_size : Vector2 = event.global_position - position
		if limit_to_screen:
			new_size.x = clamp(new_size.x, 120, get_tree().root.size.x - global_position.x)
			new_size.y = clamp(new_size.y, 90, get_tree().root.size.y - global_position.y)
		size = new_size

func _on_titlebar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if event.double_click:
				center_window()
			if event.pressed and !drag_window_enabled:
				drag_start_position = global_position
				drag_mouse_offset = event.position
				drag_window_enabled = true
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and drag_window_enabled:
				global_position = drag_start_position
				drag_window_enabled = false
			

func _on_app_window_resize() -> void:
	if limit_to_screen:
		var new_size : Vector2 = size
		new_size.x = clamp(new_size.x, 0, get_tree().root.size.x)
		new_size.y = clamp(new_size.y, 0, get_tree().root.size.y)
		size = new_size
		var new_pos : Vector2 = global_position
		new_pos.x = clamp(new_pos.x, 0, get_tree().root.size.x - size.x)
		new_pos.y = clamp(new_pos.y, 0, get_tree().root.size.y - size.y)
		global_position =  new_pos

func _on_resize_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if event.double_click:
				reset_resize()
			if event.pressed and !resize_window_enabled:
				resize_window_enabled = true
				resize_start_size = size
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and resize_window_enabled:
				size = resize_start_size
				resize_window_enabled = false

func reset_resize() -> void:
	var new_size : Vector2 = Vector2(min(default_size.x, get_tree().root.size.x), min(default_size.y, get_tree().root.size.y))
	if limit_to_screen:
		new_size.x = clamp(new_size.x, 120, get_tree().root.size.x - global_position.x)
		new_size.y = clamp(new_size.y, 120, get_tree().root.size.y - global_position.y)
	size = new_size

func center_window() -> void:
	var new_pos : Vector2 = Vector2(
		(get_tree().root.size.x - size.x) / 2.0,
		(get_tree().root.size.y - size.y) / 2.0
	)
	global_position = new_pos

func add_contents(contents: PackedScene) -> void:
	var new_contents : Control = contents.instantiate()
	%body.add_child(new_contents)

func _on_close_button_pressed() -> void:
	GSUi.hide_window(self.id)

func set_window_name(new_name: String) -> void:
	%window_name.text = new_name

func set_focused(state: bool) -> void:
	if state:
		$VBoxContainer/titlebar.theme_type_variation = "focused_window_title"
		$bg.theme_type_variation = "focused_window_panel"
		modulate = Color(1,1,1,1)
	else:
		$VBoxContainer/titlebar.theme_type_variation = "unfocused_window_title"
		$bg.theme_type_variation = "unfocused_window_panel"
		modulate = Color(.75,.75,.75,.75)
		

func call_on_child(callable: StringName, arguments: Array = []) -> void:
	var child : Control = %body.get_child(0)
	if arguments == []:
		child.call(callable)
	else:
		child.call(callable, arguments)
