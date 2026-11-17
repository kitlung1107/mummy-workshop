extends RefCounted
## Reuse the game's illustrated gold, lotus and papyrus surfaces at any size.
const ATLAS=preload("res://assets/questions/workshop-background.png")
const PAPER=Rect2(579,118,1064,734)
const GREEN=Rect2(2,1,1667,105)
static var surfaces={}

static func skin(green:bool=false)->StyleBoxTexture:
 var style=StyleBoxTexture.new()
 if not surfaces.has(green):
  # Render-sized nine-patch textures keep the original painted ornament small.
  var pixels=ATLAS.get_image().get_region(GREEN if green else PAPER)
  pixels.resize(600 if green else 400,38 if green else 276,Image.INTERPOLATE_LANCZOS)
  surfaces[green]=ImageTexture.create_from_image(pixels)
 style.texture=surfaces[green]
 for edge in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
  style.set_texture_margin(edge,32 if not green else (44 if edge in [SIDE_LEFT,SIDE_RIGHT] else 8))
  style.set_expand_margin(edge,0)
 style.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
 style.axis_stretch_vertical=StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
 return style

static func panel(host:Control,rect:Rect2,green:bool=false)->Panel:
 var p=Panel.new();p.position=rect.position;p.size=rect.size
 p.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_theme_stylebox_override("panel",skin(green));host.add_child(p)
 return p

static func button(b:Button,font_size:int=18)->void:
 for state in ["normal","hover","pressed","disabled"]:
  var style=skin(true)
  style.modulate_color=Color(1.18,1.18,1.12) if state=="hover" else Color(.72,.80,.77) if state=="disabled" else Color(.8,.9,.85) if state=="pressed" else Color.WHITE
  b.add_theme_stylebox_override(state,style)
 b.add_theme_font_size_override("font_size",font_size)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(state,Color("fff0bd"))
 b.add_theme_color_override("font_disabled_color",Color("c4c5ab"))
