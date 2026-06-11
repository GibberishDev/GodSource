@tool
class_name GDSPCPoint extends Control

@export
var texture_normal: DPITexture
@export
var texture_fixed: DPITexture
var pitch : float = 0.0
var roll : float = 0.0
var input_node : Control

signal gdspc_signal_point_clicked
signal gdspc_signal_point_moved

func _ready() -> void:
	get_window().focus_exited.connect(_on_window_focus_exited)

func _process(delta: float) -> void:
	if get_parent() is Control:
		self.scale = Vector2.ONE/get_parent().scale

@export
var fixed : bool = false :
	set(val):
		fixed = val
		if val:
			$image.texture = texture_fixed
		else:
			$image.texture = texture_normal
@export
var selected : bool = false :
	set(val):
		selected = val
		if val:
			$image.modulate = Color(0,1,1,1)
		else:
			$image.modulate = Color(1,1,1,1)

@export
var id : int = 0 :
	set(val):
		id = val
		$id.text = str(val)

func _enter_tree() -> void:
	if (get_parent().get_parent().root):
		for connection:Dictionary in gdspc_signal_point_clicked.get_connections():
			if connection.callable != get_parent().get_parent().root._point_clicked:
				gdspc_signal_point_clicked.disconnect(connection.callable)
		if not gdspc_signal_point_clicked.is_connected(get_parent().get_parent().root._point_clicked):
			gdspc_signal_point_clicked.connect(get_parent().get_parent().root._point_clicked)
		input_node = get_parent().get_parent().root.input_node

var click_pos : Vector2 = Vector2.ZERO
var dragging : bool = false
var drag_pos : Vector2
var not_dragging : bool = true
var drag_start_pos : Vector2 = Vector2.ZERO

func _on_hitbox_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.pressed:
			gdspc_signal_point_clicked.emit(self)
			click_pos = event.position
			drag_start_pos = position
			drag_pos = position
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT and !event.pressed:
			dragging = false
			not_dragging = true
			mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and event.pressed and dragging:
			dragging = false
			mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND
			position = drag_start_pos
	elif event is InputEventMouseMotion:
		var canvas_pos : Vector2 = event.global_position - input_node.get_global_transform().origin - input_node.size/2.0
		if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT) and event.position.distance_to(click_pos) > 5 and not_dragging:
			dragging = true
			not_dragging = false
		if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT) and dragging:
			if get_parent().get_parent().root is GDSPC:
				drag_pos += event.screen_relative
				var point_data : Array[Vector2] = get_parent().get_parent().root.get_new_point_pos(canvas_pos)
				position = point_data[0]
				pitch = point_data[1].x
				roll = point_data[1].y
				mouse_default_cursor_shape = CursorShape.CURSOR_DRAG
				gdspc_signal_point_moved.emit(self)

func _on_window_focus_exited() -> void:
	dragging = false
	not_dragging = true
