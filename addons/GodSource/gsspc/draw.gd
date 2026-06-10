@tool
extends TextureRect

var grid_size : int = 50
var pattern_distance : float = 57.29
var roll_preview_subdivisions : float = 48.0
var deg_preview_subdivisions : int = 0
var rbs_range : float = 1.91
var length_guides : bool = true
var degree_guides : bool = true
var random_guides : bool = true

var root : Control

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	if root == null : return
	if length_guides:
		draw_grid()
	if degree_guides:
		draw_degrees()
	if random_guides:
		draw_circle((root.preview_offset + size/2) * root.preview_scale,pattern_distance * (sin(deg_to_rad(rbs_range))/(sin(deg_to_rad(90-rbs_range)))) * grid_size,Color(1,0,1,0.1),true,-1,true)
		draw_circle((root.preview_offset + size/2) * root.preview_scale,pattern_distance * (sin(deg_to_rad(rbs_range))/(sin(deg_to_rad(90-rbs_range)))) * grid_size,Color(1,0,1,0.2),false,1,true)

func draw_grid() -> void:
	if size.x <= 0 or size.y <= 0: return
	var canvas_rect : Rect2 = Rect2(Vector2.ZERO, size)
	if canvas_rect.has_point((root.preview_offset + size/2) * root.preview_scale):
		draw_circle((root.preview_offset + size/2) * root.preview_scale,1, Color.RED,true,-1,true)
	canvas_rect.position = -root.preview_offset
	var offset : Vector2 = Vector2(int(root.preview_offset.x) % int(size.x) % grid_size, int(root.preview_offset.y) % int(size.y) % grid_size)
	for i:float in range(ceil(size.x / grid_size) + 1):
		i -= int(ceil(size.x / grid_size) / 2)
		var x : float = grid_size * i + size.x/2 + int(offset.x)
		draw_line(Vector2(x, 0), Vector2(x, size.y),Color(1,0,0,0.15),1,true)
	for i in range(ceil(size.y / grid_size) + 1):
		i -= int(ceil(size.y / grid_size) / 2)
		var y : float = grid_size * i + size.y/2 + int(offset.y)
		draw_line(Vector2(0, y), Vector2(size.x, y),Color(0,1,0,0.05),1,true)

func draw_degrees() -> void:
	var canvas_rect : Rect2 = Rect2(Vector2.ZERO, size)
	canvas_rect.position = -root.preview_offset
	for i:float in range(roll_preview_subdivisions):
		i *= 360.0/roll_preview_subdivisions
		draw_line((root.preview_offset + size/2) * root.preview_scale + Vector2(0,10).rotated(deg_to_rad(i)), (root.preview_offset + size/2) * root.preview_scale + Vector2(0,size.y + root.preview_offset.length()).rotated(deg_to_rad(i)),Color(1,1,0,0.15),1,true)
	for i:int in range(90):
		i += 1
		draw_circle((root.preview_offset + size/2) * root.preview_scale,pattern_distance * (sin(deg_to_rad(i))/(sin(deg_to_rad(90-i)))) * grid_size,Color(0,1,1,0.2),false,1,true)
		if deg_preview_subdivisions !=0:
			var step:float = 1.0/(deg_preview_subdivisions + 1)
			for k : int in range(deg_preview_subdivisions):
				k+=1
				draw_circle((root.preview_offset + size/2) * root.preview_scale,pattern_distance * (sin(deg_to_rad(i-(k*step)))/(sin(deg_to_rad(90-(i-(k*step)))))) * grid_size,Color(0,1,1,0.1),false,1,true)

	

func _on_distance_changed(value: float) -> void:
	pattern_distance = value
	queue_redraw()


func _on_pitch_subdivisions_changed(value: float) -> void:
	deg_preview_subdivisions = value
	queue_redraw()

func _on_subdiv_roll_changed(value: float) -> void:
	roll_preview_subdivisions = float(value)
	queue_redraw()

func _on_rbs_range_changed(value: float) -> void:
	rbs_range = value
	queue_redraw()
	


func _on_length_guides_pressed() -> void:
	length_guides = !length_guides
	queue_redraw()

func _on_degree_guides_pressed() -> void:
	degree_guides = !degree_guides
	queue_redraw()


func _on_random_guides_pressed() -> void:
	random_guides = !random_guides
	queue_redraw()
