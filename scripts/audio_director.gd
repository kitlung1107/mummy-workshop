extends Node
## Persistent audio + presentation clock. No answer/scoring data is inspected.
signal settings_changed
signal suspension_changed(value:bool)
const PREFERENCES_PATH="user://workshop-audio.cfg"
const MUSIC_BUS="MW Music"
const SFX_BUS="MW Effects"
const REVEAL_LENGTH=4.6
const CHOICE_CUES=[
 ["nasal-metal","anoint-oil","tool"],
 ["metal-tray","metal-tray","metal-tray"],
 ["mineral","liquid","liquid"],
 ["fill-linen","cloth","fill-papyrus"],
 ["coffin-placement","bed-placement","coffin-placement"]
]
var enabled=false
var suspended=false
var volume:float=0.40
var desired_music=""
var current_music=""
var reveal_elapsed=0.0
var revealing=false
var reveal_done=false
var attempt=-1
var ducked=false
var streams:Dictionary={}
var music_players:Array[AudioStreamPlayer]=[]
var effect_players:Array[AudioStreamPlayer]=[]
var reveal_player:AudioStreamPlayer
var music_gains=[0.0,0.0]
var music_targets=[0.0,0.0]
var effect_gains=[0.0,0.0]
var effect_targets=[0.0,0.0]
var music_slot=0
var effect_slot=0
var last_effect_ms=-1000
var stats={"music_starts":0,"reveal_starts":0,"reveal_completions":0,"effect_starts":0,"reveal_audio_starts":0,"last_effect":""}

func _ready()->void:
 _load_preferences()
 process_mode=Node.PROCESS_MODE_ALWAYS
 for bus_name in [MUSIC_BUS,SFX_BUS]:
  if AudioServer.get_bus_index(bus_name)<0:
   AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
 for i in range(2):
  var music=AudioStreamPlayer.new();music.name="Music%d"%i;music.bus=MUSIC_BUS;music.max_polyphony=1;add_child(music);music_players.append(music)
  var effect=AudioStreamPlayer.new();effect.name="Effect%d"%i;effect.bus=SFX_BUS;effect.max_polyphony=1;add_child(effect);effect_players.append(effect)
 reveal_player=AudioStreamPlayer.new();reveal_player.name="CoffinTimeline";reveal_player.bus=SFX_BUS;add_child(reveal_player)
 # Cache before the first gesture; no player autoplays.
 for id in ["loop-home","loop-workshop","loop-result","coffin-4600","ui-tap","page-turn","mission","tool","mineral","liquid","cloth","detail-open","detail-close","restart","home-return","nasal-metal","anoint-oil","metal-tray","fill-linen","fill-papyrus","bed-placement","coffin-placement"]:
  var stream=load("res://assets/audio/"+id+".wav") as AudioStreamWAV
  if stream:
   if id.begins_with("loop-"):
    stream=stream.duplicate();stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
   streams[id]=stream
 _levels()

func _load_preferences()->void:
 var prefs:=ConfigFile.new()
 if prefs.load(PREFERENCES_PATH)!=OK:return
 var saved_enabled=prefs.get_value("audio","enabled",false)
 var saved_volume=prefs.get_value("audio","volume",volume)
 if saved_enabled is bool:enabled=saved_enabled
 if (saved_volume is float or saved_volume is int) and is_finite(float(saved_volume)):
  volume=clampf(float(saved_volume),0,1)

func _save_preferences()->void:
 var prefs:=ConfigFile.new()
 prefs.set_value("audio","enabled",enabled)
 prefs.set_value("audio","volume",volume)
 prefs.save(PREFERENCES_PATH)

func _levels()->void:
 AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS),not enabled or volume==0.0)
 AudioServer.set_bus_mute(AudioServer.get_bus_index(SFX_BUS),not enabled or volume==0.0)
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS),linear_to_db(maxf(0.00001,volume*.8*(.7 if ducked else 1.0))))
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS),linear_to_db(maxf(0.00001,volume*.8)))

func set_enabled(value:bool)->void:
 if enabled==value:return
 enabled=value
 _levels()
 _save_preferences()
 if enabled and not suspended:
  if revealing and not reveal_player.playing and reveal_elapsed<REVEAL_LENGTH:
   reveal_player.stream=streams["coffin-4600"];reveal_player.play(reveal_elapsed);stats.reveal_audio_starts+=1
  elif not revealing:_ensure_music()
 settings_changed.emit()

func set_volume(value:float)->void:
 var next:=clampf(value,0,1)
 if is_equal_approx(volume,next):return
 volume=next
 _levels()
 _save_preferences()
 settings_changed.emit()

func set_ducked(value:bool)->void:
 ducked=value;_levels()

func set_scene(scene:String)->void:
 var id="loop-workshop" if scene=="quiz" else ("loop-result" if scene=="result" else "loop-home")
 desired_music=id
 if not revealing:_ensure_music()

func _ensure_music()->void:
 if not enabled or suspended or desired_music.is_empty():return
 if current_music==desired_music and music_players[music_slot].playing:return
 current_music=desired_music
 var outgoing=music_slot;music_slot=1-music_slot
 music_targets[outgoing]=0.0
 var player=music_players[music_slot];player.stop();music_gains[music_slot]=0.0;player.volume_db=-80
 player.stream=streams[current_music];player.stream_paused=false;player.play();music_targets[music_slot]=1.0
 stats.music_starts+=1

func cue(id:String,answer_feedback:bool=false)->void:
 if not enabled or suspended or revealing or not streams.has(id):return
 var now=Time.get_ticks_msec()
 if not answer_feedback and now-last_effect_ms<120:return
 last_effect_ms=now
 effect_targets[effect_slot]=0.0;effect_slot=1-effect_slot
 var player=effect_players[effect_slot];player.stop()
 # Answer recordings already contain their attack. Start at the requested gain
 # so the first audible samples do not depend on the next rendered frame.
 effect_gains[effect_slot]=1.0 if answer_feedback else 0.0
 player.volume_db=0.0 if answer_feedback else -80.0
 player.stream=streams[id];player.stream_paused=false;player.play();effect_targets[effect_slot]=1.0
 stats.effect_starts+=1;stats.last_effect=id

func choice(question:int,value:int)->void:
 if question<0 or question>=CHOICE_CUES.size() or value<0 or value>2:return
 cue(CHOICE_CUES[question][value],true)

func reset_attempt(value:int)->void:
 attempt=value;revealing=false;reveal_done=false;reveal_elapsed=0.0;reveal_player.stop();ducked=false
 for player in effect_players:player.stop()
 last_effect_ms=-1000;_levels()

func begin_reveal(value:int,force:bool=false)->void:
 if revealing and attempt==value and not force:return
 attempt=value;revealing=true;reveal_done=false;reveal_elapsed=0.0;stats.reveal_starts+=1
 music_targets=[0.0,0.0]
 for player in effect_players:player.stop()
 reveal_player.stop()
 if enabled and not suspended:
  reveal_player.stream=streams["coffin-4600"];reveal_player.play();stats.reveal_audio_starts+=1

func finish_reveal(value:int)->void:
 if attempt!=value or not revealing:return
 revealing=false;reveal_done=true;reveal_elapsed=REVEAL_LENGTH;reveal_player.stop();stats.reveal_completions+=1
 set_scene("result")

func suspend_session()->void:
 if suspended:return
 suspended=true
 for player in music_players+effect_players+[reveal_player]:player.stream_paused=true
 suspension_changed.emit(true);settings_changed.emit()

func resume_session()->void:
 if not suspended:return
 suspended=false
 for player in music_players+effect_players+[reveal_player]:player.stream_paused=false
 if enabled:
  if revealing and not reveal_player.playing:
   reveal_player.stream=streams["coffin-4600"];reveal_player.play(reveal_elapsed);stats.reveal_audio_starts+=1
  elif not revealing:_ensure_music()
 suspension_changed.emit(false);settings_changed.emit()

func _notification(what:int)->void:
 # Test scripts have their own lifecycle; do not depend on which OS window has focus.
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and not OS.get_cmdline_args().has("--script") and DisplayServer.get_name()!="headless":suspend_session()

func _process(delta:float)->void:
 if suspended:return
 if revealing:reveal_elapsed=minf(REVEAL_LENGTH,reveal_elapsed+delta)
 for i in range(2):
  music_gains[i]=move_toward(music_gains[i],music_targets[i],delta/(.16 if revealing else .65))
  music_players[i].volume_db=linear_to_db(maxf(.00001,music_gains[i]))
  if music_targets[i]==0.0 and music_gains[i]==0.0:music_players[i].stop()
  effect_gains[i]=move_toward(effect_gains[i],effect_targets[i],delta/(.025 if effect_targets[i]==0.0 else .008))
  effect_players[i].volume_db=linear_to_db(maxf(.00001,effect_gains[i]))
  if effect_targets[i]==0.0 and effect_gains[i]==0.0:effect_players[i].stop()
