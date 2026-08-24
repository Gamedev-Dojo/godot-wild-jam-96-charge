shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

const float cell_size = 1.0;
const float line_width = 0.02;
const vec4 grid_color = vec4(1.0, 1.0, 1.0, 0.20);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz / cell_size;
	vec2 d = abs(fract(p + 0.5) - 0.5);

	float line = step(0.5 - line_width, max(d.x, d.y));

	ALBEDO = grid_color.rgb;
	ALPHA = grid_color.a * line;
}
