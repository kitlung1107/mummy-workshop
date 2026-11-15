extends RefCounted

const LABELS = ["腦部", "內臟", "脫水", "包裹", "安葬"]
const QUESTIONS = [
 "你會怎樣處理腦部？",
 "你會怎樣處理胸腹內的器官？",
 "你會用甚麼方法脫水？",
 "你會怎樣填充及包裹身體？",
 "最後，你會怎樣安葬這位法老？"
]
const OPTIONS = [
 ["經鼻腔取出腦部", "保留腦部並塗香油", "打開頭顱取出腦部"],
 ["取出肝、肺、胃、腸，心臟留在體內", "連心臟也取出", "所有內臟留在體內"],
 ["用天然鹼處理約 40 日", "浸清水約 40 日", "浸啤酒約 40 日"],
 ["填充香料、木屑，塗樹脂和油，再包亞麻布", "不填充，直接包亞麻布", "填充並塗油後用紙草包裹"],
 ["配金色面具並放入棺木", "戴面具但放在棺旁", "入棺但不戴面具"]
]
const WHY = [
 ["經鼻腔移除腦部，可移走容易腐敗的組織，並較能保持外部頭顱形狀。這並不表示過程完全不影響內部骨骼。", "香油不能代替移除易腐敗組織。腦部仍在，保存風險較高；頭側的氣味線是本遊戲用來顯示內部狀態的提示。", "雖然取出了腦部，打開頭顱會影響頭顱的外部完整度。主圖以後上方的淺凹輪廓表示，金面具本身保持完整。"],
 ["本題採用的典型流程會取出肝、肺、胃及腸，另作處理；心臟留在胸腔，與古埃及人對心臟及來世的信仰有關。", "本題要求保留心臟。移除心臟主要不符這項來世信仰要求，並不因此令腹部腐敗，所以主圖不會憑空多出污斑。", "胸腹內容易腐敗的器官仍留在體內，保存風險較高。腹部的局部污斑及氣味線把這個隱藏狀態顯示出來。"],
 ["天然鹼是具有乾燥作用的鹽類材料，可以幫助移除水分。本題採用約 40 日的脫水步驟；不是浸在普通鹽水中。", "浸清水不能完成所需的乾燥處理。外層的濕痕與水滴表示水分未妥善移除；即使包上亞麻布或紙草，也會保留提示。", "浸啤酒不能代替天然鹼乾燥。琥珀色濕痕與少量泡沫是為了分辨選項而設的遊戲化提示，不代表真實遺體必然有這種外觀。"],
 ["填充物幫助維持身體形狀，樹脂、油及亞麻包裹是本題採用的處理方式。包裹完成也不能補救前面未妥善處理的腦部、內臟或水分。", "缺少填充，身體的部分輪廓會較凹陷。若器官仍在，遊戲仍保留腹部的圓度，不會把保留器官誤畫成空腹。", "紙草是植物纖維片材，並非本題要求的亞麻布。主圖保留紙草的闊片紋理；前面造成的濕痕、污斑或氣味仍會呈現。"],
 ["你完成了本遊戲為這位法老設定的金色面具與入棺安排。面具、棺木都與葬儀及死者身分有關；不同年代和身分的做法並不完全相同。", "面具已戴好，但身體仍在棺旁的承托板上，未完成本遊戲要求的入棺安排。身體和所有附著效果會一起移到棺旁。", "身體已入棺，但欠缺本遊戲為法老角色設定的金色面具。這是本題的任務條件，不能推論所有古埃及人都必須戴金面具。"]
]
const CAVEAT = "畫面中的濕痕、污斑、氣味線及缺口是教學示意，並非真實遺體的必然變化。本題採用典型流程，不代表所有年代或階層。"
const INSTRUCTIONS = "每題選一項，再按「下一步」。\n\n提交前可用「上一步」修改答案。\n\n完成五題後，才會揭曉你的木乃伊和成績。\n\n在結果畫面點五個箭嘴標籤，逐項查看解說；點彈窗外空白位置返回。"

static func valid(answers: Array) -> bool:
 if answers.size() != 5: return false
 for a in answers:
  if not a is int or a < 0 or a > 2: return false
 return true

static func code(answers: Array) -> String:
 if not valid(answers): return ""
 var out = ""
 for a in answers: out += "ABC"[a]
 return out

static func correct(answers: Array) -> Array:
 var out: Array = []
 for a in answers: out.append(a == 0)
 return out

static func score(answers: Array) -> int:
 return answers.count(0)

static func record(answers: Array, timestamp: String) -> Dictionary:
 return {"completed_at": timestamp, "correct_count": score(answers), "score": score(answers) * 20, "correct_by_question": correct(answers)}

static func visual_rules(answers: Array) -> Dictionary:
 if not valid(answers): return {}
 return {"code":code(answers), "mask":answers[4]!=2, "in_coffin":answers[4]!=1,
 "material":"papyrus" if answers[3]==2 else "linen", "hollow":answers[3]==1,
 "belly_full":answers[1]==2, "head_odor":answers[0]==1, "head_notch":answers[0]==2,
 "organ_stain":answers[1]==2, "wet":answers[2]!=0, "beer":answers[2]==2}
