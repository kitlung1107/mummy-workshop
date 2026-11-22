shader_type canvas_item;
uniform float diameter;
varying vec2 seal_uv;
void vertex() { seal_uv = VERTEX / max(diameter, 1.0); }
void fragment() {
 float r = length(seal_uv - vec2(0.5));
 COLOR.a *= 1.0 - smoothstep(0.487, 0.5, r);
}
