extends SceneTree
const Data = preload("res://scripts/content.gd")
var failures: Array = []
var checks = 0
var game: Control
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:failures.append(message)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(game.page=="home","starts at home")
 check(not game.submit(),"reject incomplete submission")
 check(game.completion_records.is_empty(),"no partial record")
 game.new_attempt()
 check(game.page=="instructions","instructions before quiz")
 for forbidden in ["天然鹼","亞麻","腦部","心臟","面具","紙草"]:
  check(not Data.INSTRUCTIONS.contains(forbidden),"instructions leak: "+forbidden)
 game.page="quiz"
 game.choose(2);game.next_question();game.choose(1)
 game.question=0;game.choose(0)
 check(game.answers==[0,1,-1,-1,-1],"back-edit preserves other answers")
 check(game.completion_records.is_empty(),"choosing never records")
 game.new_attempt()
 check(game.answers==[-1,-1,-1,-1,-1],"restart clears unfinished attempt")
 var codes: Array=[]
 for n in range(243):
  var a: Array=[]
  var v=n
  for i in range(5):a.push_front(v%3);v=int(v/3)
  var c=Data.code(a)
  codes.append(c)
  var expected=0
  for x in a:
   if x==0:expected+=1
  check(Data.score(a)==expected,c+" score")
  var texture=load("res://assets/results/"+c+".svg")
  check(texture!=null and texture.get_width()==600 and texture.get_height()==760,c+" art")
  var rules=Data.visual_rules(a)
  check(rules.mask==(a[4]!=2) and rules.in_coffin==(a[4]!=1),c+" burial")
  check(rules.organ_stain==(a[1]==2),c+" stain must not follow heart removal")
  check(rules.material==("papyrus" if a[3]==2 else "linen"),c+" wrap")
  check(rules.wet==(a[2]!=0) and rules.beer==(a[2]==2),c+" moisture")
  check(rules.head_notch==(a[0]==2) and rules.head_odor==(a[0]==1),c+" head")
  for i in range(5):
   check(not Data.WHY[i][a[i]].is_empty(),c+" explanation")
   check(ResourceLoader.exists("res://assets/details/%d_%d.svg"%[i,a[i]]),c+" detail asset")
 check(codes.size()==243 and codes[0]=="AAAAA" and codes[-1]=="CCCCC","all 243 combinations")
 # Actual scene layout and every modal for every combination in six logical viewport sizes.
 var sizes=[Vector2i(390,844),Vector2i(844,390),Vector2i(768,1024),Vector2i(1024,768),Vector2i(1366,768),Vector2i(1440,900)]
 for viewport_size in sizes:
  root.size=viewport_size
  await process_frame
  for c in codes:
   var a: Array=[]
   for character in c:a.append("ABC".find(character))
   game.answers=a
   game.page="result"
   game.render()
   await process_frame
   check(game.canvas.get_child_count()==6,c+" one image five labels")
   for i in range(5):
    var hotspot=game.canvas.get_node("Hotspot%d"%i)
    check(hotspot.size.y*game.canvas.scale.y>=43.9,c+" touch height")
    check(hotspot.position.x+hotspot.size.x<=600.1,c+" label within canvas")
    game.open_detail(i)
    check(game.dialog_question==i,c+" correct modal")
    game.open_detail((i+1)%5)
    check(game.dialog_question==i,c+" cannot replace open modal")
    check(hotspot.focus_mode==Control.FOCUS_NONE,c+" background keyboard locked")
    game.close_detail()
    check(game.dialog_question==-1,c+" modal closes")
  print("LAYOUT PASS ",viewport_size," : 243 outcomes, 1215 dialogs")
 game.new_attempt()
 game.answers=[0,1,2,0,1]
 var before=game.completion_records.size()
 check(game.submit(),"complete submission succeeds")
 check(not game.submit(),"duplicate blocked")
 check(game.completion_records.size()==before+1,"one record per completion")
 var record=game.completion_records.back()
 check(record.keys().size()==4 and record.correct_count==2 and record.score==40,"completion schema")
 check(not record.has("coins") and not record.has("duration"),"no rewards or duration")
 game.new_attempt()
 game.answers=[0,0,0,0,0]
 check(game.submit(),"replay submits")
 check(game.completion_records.size()==before+2,"replay creates separate record in memory")
 var report={"checks":checks,"failures":failures,"combinations":243,"layout_states":1458,"modal_states":7290,"viewport_sizes":sizes.map(func(s):return str(s)),"scope":"Godot headless logic and control geometry, not physical device testing"}
 var file=FileAccess.open("res://review/test-report.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "));file.close()
 print(JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)
