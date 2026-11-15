shader_type canvas_item;
uniform vec2 uv_origin;
uniform vec2 uv_extent;
uniform bool hollow = false;
uniform bool full_belly = false;
uniform bool damaged_head = false;
uniform bool organ_stain = false;
uniform int wet = 0;
float patch(vec2 p, vec2 c, vec2 s) { return exp(-dot((p-c)/s,(p-c)/s)*2.0); }
void fragment() {
 vec2 uv=(UV-uv_origin)/uv_extent;
 float torso=exp(-pow((uv.y-.42)/.20,2.0));
 float factor=1.0+(hollow ? .22*torso : 0.0)-(full_belly ? .12*torso : 0.0);
 uv.x=(uv.x-.5)*factor+.5;
 vec4 base=texture(TEXTURE,uv_origin+uv*uv_extent);
 if(damaged_head && uv.y<.073 && uv.x>.64+uv.y*1.7) base.a=0.0;
 float grain=sin(uv.x*131.0+cos(uv.y*113.0))*sin(uv.y*89.0)*.09;
 float damp=clamp(patch(uv,vec2(.46,.32),vec2(.38,.17))+patch(uv,vec2(.60,.56),vec2(.34,.15))+patch(uv,vec2(.42,.85),vec2(.31,.13))+grain,0.0,1.0);
 if(wet>0) base.rgb=mix(base.rgb,base.rgb*(wet==2 ? vec3(.66,.40,.14):vec3(.33,.55,.64)),damp*.72);
 float stain=clamp(patch(uv,vec2(.40,.29),vec2(.29,.095))+patch(uv,vec2(.62,.40),vec2(.27,.12))+patch(uv,vec2(.44,.47),vec2(.27,.075))+grain,0.0,1.0);
 if(organ_stain) base.rgb=mix(base.rgb,vec3(.24,.09,.23),stain*.76);
 if(hollow) base.rgb*=1.0-.24*patch(uv,vec2(.5,.43),vec2(.20,.17));
 COLOR=base;
}
