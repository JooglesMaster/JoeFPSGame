shader_type spatial;
render_mode blend_add, cull_disabled, unshaded;

uniform float fade_factor : hint_range(0, 1) = 1.0;

void vertex() {
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
    float center = 1.0 - abs(UV.y - 0.5) * 2.0;
    center = pow(center, 3.0);  // Adjust power for sharper or softer center
    
    vec3 trail_color = mix(vec3(0.5, 0.5, 0.5), vec3(1.0, 1.0, 1.0), center);
    float alpha = center * fade_factor;
    
    ALBEDO = trail_color;
    ALPHA = alpha;
    EMISSION = trail_color * 2.0;  // Adjust multiplier for glow intensity
}