extends RefCounted
## Entry screens are isolated from question/result rendering and answer data.
const HOME = preload("res://assets/entry/home.png")
const INSTRUCTIONS = preload("res://assets/entry/instructions.png")
const INSTRUCTION_COPY = "你是一位古埃及防腐師。\n王室交給你一項重要任務：\n為法老王製作木乃伊。"
const OUTCOME_COPY = "每個部分選一種做法。\n完成後，看看你製作的木乃伊會變成甚麼模樣！"

static func build(game: Control, page: String) -> void:
 var background := ColorRect.new()
 background.color = Color("123e46")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 game.add_child(background)
 if page == "instructions" and (game.size.x < 720 or game.size.y < 500):
  _compact_instructions(game)
 else:
  _illustrated(game, page)

static func _illustrated(game: Control, page: String) -> void:
 var texture: Texture2D = HOME if page == "home" else INSTRUCTIONS
 var natural := texture.get_size()
 var factor: float = minf(game.size.x / natural.x, game.size.y / natural.y)
 var frame := Control.new()
 frame.name = "EntryArtwork"
 frame.size = natural * factor
 frame.position = (game.size - frame.size) / 2
 game.add_child(frame)
 var art := TextureRect.new()
 art.texture = texture
 art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 frame.add_child(art)
 if page == "home":
  _hotspot(frame, "StartGame", "開始遊戲", Rect2(0.263,0.816,0.473,0.144),
   func(): game.new_attempt(); game.render())
 else:
  _hotspot(frame, "AcceptMission", "接受任務", Rect2(0.326,0.86,0.422,0.121),
   func(): game.page="quiz"; game.render())
  _hotspot(frame, "BackHome", "返回首頁", Rect2(0.018,0.018,0.072,0.084),
   func(): game.page="home"; game.render())

static func _hotspot(frame: Control, id: String, caption: String, region: Rect2, action: Callable) -> void:
 var control := Button.new()
 control.name = id
 control.tooltip_text = caption
 control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 control.position = region.position * frame.size
 control.size = region.size * frame.size
 # Touch targets remain usable on small windows without cropping the artwork.
 if control.size.y < 44:
  control.position.y -= (44-control.size.y)/2
  control.size.y=44
 if control.size.x < 44:
  control.position.x -= (44-control.size.x)/2
  control.size.x=44
 control.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
 for state in ["hover", "pressed", "focus"]:
  var style := StyleBoxFlat.new()
  style.bg_color=Color(1,0.9,0.65,0.13 if state=="hover" else 0.22 if state=="pressed" else 0)
  style.border_color=Color("fff5d5")
  style.set_border_width_all(3 if state=="focus" else 0)
  style.set_corner_radius_all(28)
  control.add_theme_stylebox_override(state,style)
 control.pressed.connect(action)
 frame.add_child(control)

static func _compact_instructions(game: Control) -> void:
 var backdrop := TextureRect.new()
 # Reuse only the character illustration; baked-in page copy must not sit
 # behind the live, reflowing text on narrow screens.
 var character_art := AtlasTexture.new()
 character_art.atlas=INSTRUCTIONS
 character_art.region=Rect2(0,135,440,780)
 backdrop.texture=character_art
 backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop.modulate=Color(0.28,0.32,0.30)
 backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.add_child(backdrop)
 var scroll := ScrollContainer.new()
 scroll.name="EntryScroll"
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 game.add_child(scroll)
 var margins := MarginContainer.new()
 margins.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for edge in ["left","right","top","bottom"]:
  margins.add_theme_constant_override("margin_"+edge,18)
 scroll.add_child(margins)
 var stack := VBoxContainer.new()
 stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 stack.add_theme_constant_override("separation",16)
 margins.add_child(stack)
 var back: Button=game.button("← 返回首頁",func(): game.page="home"; game.render())
 back.name="BackHome"
 stack.add_child(back)
 var title: Label=game.label("遊戲玩法",34,Color("ffe0a0"))
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 stack.add_child(title)
 var panel := PanelContainer.new()
 panel.add_theme_stylebox_override("panel",game.panel_style(Color("fff0ce"),Color("d6ab61"),18))
 stack.add_child(panel)
 var copy: Label=game.label(INSTRUCTION_COPY,23,Color("352619"))
 copy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 panel.add_child(copy)
 stack.add_child(game.label("以下五個部分，由你決定怎樣處理。",21))
 var grid := GridContainer.new()
 grid.columns=2 if game.size.x<480 else 5
 grid.add_theme_constant_override("h_separation",10)
 grid.add_theme_constant_override("v_separation",10)
 stack.add_child(grid)
 var parts=["腦部","內臟","脫水","包裹","安葬"]
 for i in range(5):
  var part := PanelContainer.new()
  part.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  part.add_theme_stylebox_override("panel",game.panel_style(Color("103e49"),Color("d6ab61"),14))
  var text: Label=game.label("%02d  %s" % [i+1,parts[i]],20,Color("ffe4a9"))
  text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  part.add_child(text)
  grid.add_child(part)
 stack.add_child(game.label(OUTCOME_COPY,21))
 var accept: Button=game.button("接受任務",func(): game.page="quiz"; game.render(),true)
 accept.name="AcceptMission"
 stack.add_child(accept)
