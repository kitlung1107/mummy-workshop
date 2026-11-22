extends RefCounted

const JADE = preload("res://assets/settings/jade.svg")
const STONE = preload("res://assets/settings/limestone.svg")
const DARK = preload("res://assets/settings/toggle.svg")
const TABLET = preload("res://assets/settings/tablet.svg")
const GEAR = preload("res://assets/settings/gear.svg")
const TEMPLE = preload("res://assets/settings/temple.svg")
const PLAY = preload("res://assets/settings/play.svg")
const VOLUME = preload("res://assets/settings/volume.svg")
const MUTE = preload("res://assets/settings/mute.svg")
const SOUND = preload("res://assets/settings/sound.svg")
const SWITCH_OFF = preload("res://assets/settings/switch-off.svg")
const SWITCH_ON = preload("res://assets/settings/switch-on.svg")
const WING = preload("res://assets/settings/wing.svg")

static func surface(texture:Texture2D, corners:Vector2, padding:Vector2)->StyleBoxTexture:
 var box=StyleBoxTexture.new()
 box.texture=texture
 for edge in [SIDE_LEFT,SIDE_RIGHT]:
  box.set_texture_margin(edge,corners.x)
  box.set_content_margin(edge,padding.x)
 for edge in [SIDE_TOP,SIDE_BOTTOM]:
  box.set_texture_margin(edge,corners.y)
  box.set_content_margin(edge,padding.y)
 return box

static func button(b:Button, material:Texture2D, glyph:Texture2D, font_size:int)->void:
 var ink=Color("44301d") if material==STONE else Color("ffedb5")
 b.icon=glyph
 b.add_theme_constant_override("icon_max_width",24)
 b.add_theme_constant_override("h_separation",7)
 b.add_theme_font_size_override("font_size",font_size)
 for state in ["normal","hover","pressed","disabled"]:
  var box=surface(material,Vector2(16,13),Vector2(8,4))
  if state=="hover":box.modulate_color=Color(1.14,1.12,1.07)
  if state=="pressed":box.modulate_color=Color(.80,.86,.85)
  b.add_theme_stylebox_override(state,box)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  b.add_theme_color_override(state,ink)
 var focus=StyleBoxFlat.new()
 focus.bg_color=Color.TRANSPARENT
 focus.border_color=Color("fff1ab")
 focus.set_border_width_all(2)
 focus.set_corner_radius_all(9)
 b.add_theme_stylebox_override("focus",focus)
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND

static func slider(control:HSlider)->void:
 control.custom_minimum_size.y=44
 control.min_value=0
 control.max_value=100
 control.step=1
 for pair in [["slider",preload("res://assets/settings/track.svg")],
   ["grabber_area",preload("res://assets/settings/level.svg")],
   ["grabber_area_highlight",preload("res://assets/settings/level.svg")]]:
  control.add_theme_stylebox_override(pair[0],surface(pair[1],Vector2(5,4),Vector2(5,5)))
 control.add_theme_icon_override("grabber",preload("res://assets/settings/thumb.svg"))
 control.add_theme_icon_override("grabber_disabled",preload("res://assets/settings/thumb.svg"))
 control.add_theme_icon_override("grabber_highlight",preload("res://assets/settings/thumb-focus.svg"))
 control.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND

static func picture(texture:Texture2D, extent:Vector2)->TextureRect:
 var image=TextureRect.new()
 image.texture=texture
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.custom_minimum_size=extent
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return image
