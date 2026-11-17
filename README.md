# 木乃伊工房

中一歷史教育遊戲，使用 Godot 4.7.2、GDScript 及 Compatibility renderer。五題各有三個選項，完成後呈現同一具完整木乃伊的 243 種選擇組合，並提供 15 款對應解說。

## 開啟遊戲

以 Godot 4.7.2 開啟本目錄的 `project.godot`，匯入素材後按 F5。

Windows 可執行 `Launch-Game.cmd`。啟動器會搜尋 `GODOT4` 環境變數指定的執行檔、相鄰 `runtime` 目錄、桌面及 PATH。找不到引擎時可直接使用 Godot 編輯器。`Launch-243-Review.cmd` 可直達結果頁，再按「243 組合試看」切換選項。

手機版採用已選定的「11/17 選項完整重畫」版本：手機及 iPad 直向提示轉橫，iPad 橫向保留桌面風格。可用 `tools/export_web.ps1` 匯出 Web 版本，再以 `node tools/preview_server.mjs build/web 8765` 開啟本機預覽。素材範圍、測試及操作見 [版本紀錄](docs/approved-phone-preview-20261117.md)；目前驗證為尺寸模擬，尚非手機或 iPad 真機測試。

## 遊玩與結果

首頁 → 玩法 → 五題三選一 → 提交 → 結果。答題頁隨機排列選項，內部 A／B／C ID 保持固定；提交前可返回修改，未選答案時不能進入下一步。

左側木乃伊組合亞麻布或紙草、面具、棺木位置及局部效果。保留腦部或內臟會顯示紫色氣味提示；清水與啤酒分別呈現不同濕痕；面具及包裹遮住身體時仍保留可見提示。移除心臟不會憑空增加腐敗效果，其宗教意義由解說呈現。

點五個部位標籤或右側步驟，開啟所選方法的置中解說，同時只顯示一個視窗。按右上角交叉、視窗外空白或 Esc 可關閉；Tab／Enter 保留鍵盤操作。已移除重複的「返回木乃伊」控制，其插圖外觀以同圖空白羊皮紙覆蓋，保留原有邊框及解說內容。開啟解說時隱藏背景提示，關閉後恢復。

進入玩法頁後，首 0.5 秒內無法接受任務，避免首頁雙擊穿透。結果頁縮放只調整排版，保留開棺動畫進度及一次性揭曉事件。解說紋理僅在本次結果流程暫存，最多五張，返回首頁或開始新一局時清理。

依 Lung 指定，遊戲文字統一使用「法魯王」，包括玩法及安葬圖解中的文字。首頁胸前布料由 imagegen 局部編輯，遊戲只顯示修補範圍，保留其餘原圖像素。十五款圖解與合成木乃伊使用已審閱的卡通插畫素材。

## 程式與素材

- `scripts/content.gd`：題庫、答案、計分及效果規則。
- `scripts/entry_pages.gd`、`question_pages.gd`：首頁、玩法及答題介面。
- `scripts/result_pages.gd`：結果、243 組合選擇器及十五款解說映射。
- `scripts/mummy_renderer.gd`、`body_effects.gdshader`：完整木乃伊、材質、遮擋及效果。
- `scripts/art_button.gd`：圖像按鈕點擊範圍與鍵盤焦點。
- `assets/composite/`、`assets/explanations/`：目前結果系統使用的插畫。

成績只保存在本次遊戲記憶體，沒有登入、Firestore、成績後端或網絡依賴。每答對一題得 20 分；組合試看不新增學生成績。

## 驗證

在有圖形顯示的桌面執行以下命令；`godot` 代表 Godot 4.7.2 執行檔：

```text
godot --headless --editor --import --path .
godot --headless --path . --script res://tests/test_session.gd
godot --path . --audio-driver Dummy --script res://tests/test_ui_lifecycle.gd
godot --path . --audio-driver Dummy --script res://tests/test_all.gd
godot --path . --audio-driver Dummy --script res://tests/test_v3.gd
godot --path . --audio-driver Dummy --script res://tests/test_final_render.gd
```

測試涵蓋全部 243 組、1,215 次實際滑鼠開啟解說、選項映射、計分與重複提交、遮擋效果、十五款關閉交叉、懸停、鍵盤導覽及桌面縮放；另以像素比較驗證首頁修補範圍外沒有變動。`test_ui_lifecycle.gd` 驗證 110 ms 雙擊與 500 ms 防連按、開棺中連續縮放、同幀重選及過期焦點、十五款解說在六種視窗尺寸的置中與關閉、五張 LRU 暫存及流程清理。截圖和 JSON 報告寫入 `review/`，該目錄與執行日誌不提交到 Git。

## 授權

中文字型為 Noto Sans CJK TC 子集，系統中文字型補足缺字；授權見 `assets/FONT-LICENSE.txt`。Godot 授權見 `GODOT-LICENSE.txt`。保存與腐敗效果為簡化教學示意。
