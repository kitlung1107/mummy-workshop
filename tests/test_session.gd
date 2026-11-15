extends SceneTree
## Retained session/scoring regressions from the original test_all.gd.
const Data=preload("res://scripts/content.gd")
var checks=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,note:String)->void:
 checks+=1
 if not ok:failures.append(note)
func run()->void:
 DirAccess.make_dir_recursive_absolute("res://review/integration")
 var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 check(game.page=="home","starts at home")
 check(not game.submit(),"reject incomplete submission")
 check(game.completion_records.is_empty(),"no partial record")
 game.new_attempt();check(game.page=="instructions","instructions before quiz")
 for forbidden in ["天然鹼","亞麻","腦部","心臟","面具","紙草"]:
  check(not Data.INSTRUCTIONS.contains(forbidden),"instructions do not reveal answers")
 game.page="quiz";game.choose(2);game.next_question();game.choose(1)
 game.question=0;game.choose(0)
 check(game.answers==[0,1,-1,-1,-1],"back-edit preserves other answers")
 check(game.completion_records.is_empty(),"choosing never records")
 game.new_attempt();check(game.answers==[-1,-1,-1,-1,-1],"restart clears unfinished attempt")
 for n in range(243):
  var answers:Array=[];var value=n
  for i in range(5):answers.push_front(value%3);value=int(value/3)
  var expected=0
  for answer in answers:
   if answer==0:expected+=1
  check(Data.score(answers)==expected,Data.code(answers)+" score")
 game.new_attempt();game.answers=[0,1,2,0,1]
 var before=game.completion_records.size()
 check(game.submit(),"complete submission succeeds")
 check(not game.submit(),"duplicate blocked")
 check(game.completion_records.size()==before+1,"one record per completion")
 var record=game.completion_records.back()
 check(record.keys().size()==4 and record.correct_count==2 and record.score==40,"completion schema")
 check(not record.has("coins") and not record.has("duration"),"no rewards or duration")
 game.new_attempt();game.answers=[0,0,0,0,0]
 check(game.submit(),"replay submits")
 check(game.completion_records.size()==before+2,"separate replay record in memory")
 var report={"checks":checks,"failures":failures,"score_combinations":243}
 var output=FileAccess.open("res://review/integration/session-report.json",FileAccess.WRITE)
 output.store_string(JSON.stringify(report,"  "));output.close()
 print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
