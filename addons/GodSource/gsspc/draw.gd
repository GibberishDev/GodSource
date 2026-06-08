@tool
extends TextureRect

var grid_size : int = 10

var root : Control

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	if root == null : return
	draw_grid()

func draw_grid() -> void:
	var canvas_rect : Rect2 = Rect2(Vector2.ZERO, size)
	if canvas_rect.has_point((root.preview_offset + size/2) * root.preview_scale):
		draw_circle((root.preview_offset + size/2) * root.preview_scale,1, Color.RED)
	canvas_rect.position = -root.preview_offset
	print(canvas_rect)
