shader_type canvas_item;


uniform float angle : hint_range(-90.0, 90.0, 0.1) = 0;

void vertex() {
  mat4 skew_matrix = mat4(
      vec4(1.0, angle/ -90., 0.0, 0.0),
      vec4(0.0, 1.0, 0.0, 0.0),
      vec4(0.0, 0.0, 1.0, 0.0),
      vec4(0.0, 0.0, 0.0, 1.0)
  );
	if (VERTEX_ID == 0)
		VERTEX.x = (MODEL_MATRIX * vec4(VERTEX.xy, 0.,0.) * skew_matrix).x / TEXTURE_PIXEL_SIZE.x;
}

void fragment() {
	COLOR.r = sin(TIME);
	COLOR.g = -sin(TIME);
}