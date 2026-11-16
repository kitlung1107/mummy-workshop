shader_type canvas_item;
render_mode unshaded;

// Display the illustrated panel only. Replace the obsolete painted control with
// adjacent blank parchment from the same image; retain every ornamental border.
uniform vec4 removed_rect;
void fragment() {
 vec2 source_uv = vec2(0.354, 0.087) + UV * vec2(0.638, 0.836);
 vec4 original = texture(TEXTURE, source_uv);
 vec2 local = (source_uv - removed_rect.xy) / removed_rect.zw;
 vec2 edge = smoothstep(vec2(0.0), vec2(0.045), local)
  * (vec2(1.0) - smoothstep(vec2(0.955), vec2(1.0), local));
 vec2 parchment_uv = vec2(0.440 + clamp(local.x, 0.0, 1.0) * 0.105, source_uv.y);
 COLOR = mix(original, texture(TEXTURE, parchment_uv), edge.x * edge.y);
}
