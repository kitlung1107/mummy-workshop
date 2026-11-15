shader_type canvas_item;
uniform bool hollow=false;
uniform bool full_belly=false;
uniform bool damaged_head=false;
uniform bool head_decay=false;
uniform bool organ_stain=false;
uniform bool papyrus=false;
uniform int wet=0;
uniform float phase=0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*.58+noise(p*2.03)*.27+noise(p*4.09)*.15;}
float patch(vec2 p,vec2 c,vec2 s){vec2 d=(p-c)/s;return exp(-dot(d,d)*2.0);}
void fragment(){
 vec2 uv=UV;
 float torso=exp(-pow((uv.y-.42)/.20,2.0));
 // The unfilled sprite already has thin limbs and slack cloth. Retained organs
 // restore only abdominal volume, without making the limbs look padded.
 float factor=1.0-(full_belly?(hollow?.20:.07)*torso:0.0);
 uv.x=(uv.x-.5)*factor+.5;
 vec2 sample_uv=uv;
 if(hollow||wet>0){
  // Match the reviewed head/mask height while keeping the feet and body frame fixed.
  sample_uv.y=uv.y<.20?uv.y*1.35:.27+(uv.y-.20)*(.73/.8);
 }
 vec4 base=texture(TEXTURE,sample_uv);
 if(uv.x<0.0||uv.x>1.0)base.a=0.0;
 if(damaged_head&&uv.y<.072&&uv.x>.64+uv.y*1.7)base.a=0.0;
 float n=fbm(uv*vec2(21.0,58.0));
 float fine=fbm(uv*vec2(65.0,124.0));
 float head=patch(uv,vec2(.72,.10),vec2(.33,.09))+patch(uv,vec2(.34,.19),vec2(.26,.06))+patch(uv,vec2(.51,.215),vec2(.48,.045));
 float belly=patch(uv,vec2(.40,.34),vec2(.43,.14))+patch(uv,vec2(.64,.44),vec2(.36,.13));
 float stain=(head_decay?head:0.0)+(organ_stain?belly:0.0);
 stain=clamp(stain*(.35+n*.9),0.0,.84);
 vec3 old=base.rgb;
 vec3 decay=base.rgb*vec3(.43,.48,.32);
 base.rgb=mix(base.rgb,decay,stain);
 float specks=smoothstep(.67,.84,fine)*stain*.42;
 base.rgb=mix(base.rgb,vec3(.19,.20,.12),specks);
 if(hollow&&!full_belly)base.rgb*=1.0-.09*patch(uv,vec2(.5,.43),vec2(.20,.17));
 if(wet>0){
  float luminance=dot(old,vec3(.299,.587,.114));
  float ridges=smoothstep(.64,.86,luminance);
  float absorption=(1.0-ridges)*(.09+.08*n);
  base.rgb*=1.0-absorption;
  // Moving glints follow painted rivulets and wet fibers, never detached icons.
  float traveling=.5+.5*sin(uv.y*43.0-phase*1.4+n*4.0);
  float sheen=ridges*(.025+.045*traveling);
  vec3 liquid_light=wet==2?vec3(1.0,.76,.30):vec3(1.0,.99,.96);
  base.rgb+=liquid_light*sheen;
 }
 COLOR=base;
}
