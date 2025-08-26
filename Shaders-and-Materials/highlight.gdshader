shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform vec4 outline_color: source_color;
uniform float outline_width: hint_range(1.0, 1.5, 0.01) = 1.03;
uniform float alpha: hint_range(0.0, 1.0, 0.01) = 0.0;

varying vec3 world_position;

void vertex() {
    VERTEX *= outline_width;
	//world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    ALBEDO = outline_color.rgb;
    ALPHA = (1.0 - float(FRONT_FACING)) * alpha;
}
