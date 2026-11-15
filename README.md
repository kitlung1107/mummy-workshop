# 木乃伊工房 · 獨立 Godot 試玩版

這是供審閱及試玩的第一版。採用 A 卡通方向的青金配色、完整木乃伊及同一套原創向量母版，讓 243 個答案組合保持比例一致。細節美術仍可在審閱後調整。

## 開啟遊戲

- **Godot 專案**：用 Godot 4.6.3 開啟 `godot-project/project.godot`（原始碼目錄內為 `project.godot`），按 F6/F5 執行主場景。專案使用 GDScript 及 Compatibility renderer。
- **Web 試玩包**：可先在解壓後目錄執行 `python3 serve_game.py` 自動開啟本機試玩。亦可在 `web` 目錄執行 `python3 -m http.server 8000`，再於瀏覽器開啟 `http://localhost:8000`。必須經本機 HTTP 開啟，不能直接雙擊 `index.html`；需要 WebGL 2.0 / WebAssembly。沒有部署。
- **Linux**：如使用包內 Linux build，給 `mummy-workshop.x86_64` 執行權限後直接開啟。
- **243 組圖像審閱**：直接用瀏覽器開啟 `review/木乃伊工房-243組圖像審閱.html`。這份獨立檔案不需伺服器，可搜尋五位代碼、按分數篩選及放大。

## 已實作

首頁 → 開始遊戲 → 只說明玩法 → 五題三選一 → 全部提交才揭曉。每次開始打亂選項顯示順序，內部代碼保持固定。學生可用上一步修改；未選答案不能下一步，未填齊不能提交。

結果是一具完整木乃伊，五個箭嘴標籤分別開啟所選做法、對錯、局部示意、後果與正確做法。彈窗同時只開一個，背景按鈕及鍵盤焦點鎖定；點空白、返回按鈕或 Esc 關閉。

紙草始終是紙草，不存在「不包裹」選項。金色面具不是全身盔甲。表面濕痕與腹部污斑分區；頭部缺口留在面具上方，面具不破裂；器官仍在且未填充時保留腹部圓度；移除心臟不會憑空造成腐敗污斑。棺外身體及附著效果一起移動。部分不同答案的外觀可以相同，例如內臟 A / B，差異由標籤和彈窗解釋。

素材由 `tools/generate_assets.py` 的共同 SVG 母版確定產生。不是在玩家提交後即時用 AI 生成。所有結果與 15 張解說圖都已預先匯入 Godot。

## 紀錄與未來接入

現階段沒有登入、Firestore、任何網絡 API、派幣或持久化紀錄。每次完成只在本次執行的記憶體加入一份紀錄：UTC 完成時間、答對題數、分數、五題各自對錯。重複提交被擋下，重玩可建立新紀錄。關閉遊戲會清除這些臨時紀錄，中途答案也不儲存。

未來由網站後端實作：首次完成每答對一題派 20 幣，首次 0 分仍算首次；之後重玩不派幣，但每次完成保存日期、分數及逐題對錯。必須以伺服器驗證答案、原子交易及冪等提交處理重試與多頁並發；此版沒有實作或宣稱驗證這些功能。

## 驗證

`godot --headless --path . --script tests/test_all.gd`

此版自動結果：49,350 項檢查通過、0 失敗；243 組答案；六種尺寸共 1,458 組控制項版面；每組五個彈窗，共 7,290 個狀態。涵蓋素材可讀、分數、關鍵視覺規則、標籤範圍及最少 44px 點擊高度、彈窗鎖定、關閉、重玩與完成紀錄。

Godot Web 匯出已在 Chromium WebGL 2.0 執行，並以實際滑鼠輸入檢查首頁、玩法頁、五題作答、提交、結果、彈窗及不同尺寸。測試紀錄見 `review/test-report.json`。原始碼可重新執行測試。

限制：自動幾何檢查不能取代逐張人工審圖；已人工檢查關鍵組合預覽及抽樣實際畫面，未逐張人工核對 243 張圖。手機及平板為軟件視窗尺寸檢查，未使用真實手機、iPad 或 Safari 觸控測試。沒有做 Firestore／派幣整合測試，因這些功能未接入。

## 史實與視覺提示

本題採用課本典型流程，不代表古埃及每個年代、階層及個案。心臟保留涉及信仰；經鼻取腦不表示內部骨骼完全無損。金面具加棺木是此遊戲法老角色的任務條件。濕痕、污斑、氣味、頭部缺口、啤酒色及泡沫是遊戲化教學提示，不能當成真實保存實驗或必然腐敗表現。

參考資料：
- Smithsonian, Egyptian Mummies: https://www.si.edu/spotlight/ancient-egypt/mummies
- Australian Museum, How were ancient Egyptians mummified?: https://australian.museum/learn/cultures/international-collection/ancient-egyptian/how-were-ancient-egyptians-mummified/
- British Museum, Linen bag of salt for mummification: https://artsandculture.google.com/asset/linen-bag-of-salt-for-mummification/cgFaCN4U-fYSrg
- Godot Web export documentation: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html

## 素材與打包

圖形為本專案原創可編輯 SVG。中文字體是 Noto Sans CJK TC 子集，授權見 `assets/FONT-LICENSE.txt`；Godot 使用 MIT 授權，見 `GODOT-LICENSE.txt`。不包含網站原有程式、帳戶或其他工作區檔案。

匯出預設中的 custom_template 路徑只對開發環境有效。換電腦可在 Godot 安裝 4.6.3 export templates，清空 custom_template 路徑後重新匯出。Web 使用單執行緒，沒有 PWA 或後端連線。
