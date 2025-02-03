shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_disabled,unshaded,shadows_disabled,world_vertex_coords,ambient_light_disabled,depth_prepass_alpha;

uniform sampler2D panorama_texture : source_color;

// Function from Godot source:  godot/drivers/gles3/shaders/cubemap_filter.glsl
vec4 texturePanorama(vec3 normal, sampler2D pano) {
	vec2 st = vec2(
			atan(normal.x, normal.z),
			acos(normal.y));

	if (st.x < 0.0)
		st.x += PI * 2.0;

	st /= vec2(PI * 2.0, PI);

	return textureLod(pano, st, 0.0);
}

void fragment() {
	vec3 normal = (INV_VIEW_MATRIX*vec4(VIEW,0)).xyz * vec3(-1, -1, 1);
	ALBEDO = texturePanorama(normal, panorama_texture).xyz;
}