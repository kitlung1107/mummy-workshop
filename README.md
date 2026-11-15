# 木乃伊工房

中一歷史教育遊戲，使用 Godot 4.7.2、GDScript 及 Compatibility renderer。五題各有三個選項，完成後呈現同一具完整木乃伊的 243 種選擇組合，並提供 15 款對應解說。

## 開啟遊戲

以 Godot 4.7.2 開啟本目錄的 `project.godot`，匯入素材後按 F5。

Windows 可執行 `Launch-Game.cmd`。啟動器會搜尋 `GODOT4` 環境變數指定的執行檔、相鄰 `runtime` 目錄、桌面及 PATH。找不到引擎時可直接使用 Godot 編輯器。`Launch-243-Review.cmd` 可直達結果頁，再按「243 組合試看」切換選項。

此版本以桌面試玩為驗證範圍，未重新優化手機或 iPad，沒有提供新的 Web 匯出包。

## 遊玩與結果

首頁 → 玩法 → 五題三選一 → 提交 → 結果。答題頁隨機排列選項，內部 A／B／C ID 保持固定；提交前可返回修改，未選答案時不能進入下一步。

左側木乃伊組合亞麻布或紙草、面具、棺木位置及局部效果。保留腦部或內臟會顯示紫色氣味提示；清水與啤酒分別呈現不同濕痕；面具及包裹遮住身體時仍保留可見提示。移除心臟不會憑空增加腐敗效果，其宗教意義由解說呈現。

點五個部位標籤或右側步驟，開啟所選方法的解說，同時只顯示一個視窗。按「返回木乃伊」、右上角關閉、視窗外空白或 Esc 可關閉；Tab／Enter 保留鍵盤操作。滑鼠不再顯示重複提示，返回按鈕使用貼合圖像的膠囊形點擊範圍，鍵盤焦點細線留在按鈕內。

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
godot --path . --audio-driver Dummy --script res://tests/test_all.gd
godot --path . --audio-driver Dummy --script res://tests/test_v3.gd
godot --path . --audio-driver Dummy --script res://tests/test_final_render.gd
```

測試涵蓋全部 243 組、1,215 次實際滑鼠開啟解說、選項映射、計分與重複提交、遮擋效果、十五款返回按鈕邊界、懸停、鍵盤導覽及桌面縮放；另以像素比較驗證首頁修補範圍外沒有變動。截圖和 JSON 報告寫入 `review/`，該目錄與執行日誌不提交到 Git。

## 授權

中文字型為 Noto Sans CJK TC 子集，系統中文字型補足缺字；授權見 `assets/FONT-LICENSE.txt`。Godot 授權見 `GODOT-LICENSE.txt`。保存與腐敗效果為簡化教學示意。
