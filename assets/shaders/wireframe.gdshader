shader_type spatial;
render_mode unshaded,wireframe,cull_disabled;

uniform vec4 wireColor : source_color = vec4(1.0,0.667,0.0,1.0);
uniform float wireWidth : hint_range(0.0, 50.0, 0.1) = 1.0;


void vertex() {
	vec4 wireframeMapping = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION = wireframeMapping;
}

void fragment() {
	ALBEDO = wireColor.rgb;
	ALPHA = wireColor.a;
}
