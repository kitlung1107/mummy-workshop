shader_type canvas_item;
uniform sampler2D edited_art : source_color, filter_linear;
uniform vec4 patch_pixels = vec4(894.0,450.0,128.0,71.0);
uniform vec2 original_size = vec2(1453.0,1083.0);
void fragment() {
 vec2 p=UV*original_size;
 vec2 low=p-patch_pixels.xy;
 vec2 high=patch_pixels.xy+patch_pixels.zw-p;
 float edge=min(min(low.x,low.y),min(high.x,high.y));
 float amount=smoothstep(0.0,3.0,edge);
 COLOR=mix(texture(TEXTURE,UV),texture(edited_art,UV),amount);
}
