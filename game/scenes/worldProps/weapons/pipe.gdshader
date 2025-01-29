shader_type spatial;

render_mode unshaded, depth_test_disabled, cull_back;

uniform bool visible = true;
uniform vec4 silhouetteColor : source_color = vec4(1.0,1.0,0.0,1.0);
uniform float outline_width = 2.0; 

void fragment() {
	if (!visible) {
		discard;
	}
	ALBEDO = silhouetteColor.rgb;
}
