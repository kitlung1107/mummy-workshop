# 音訊行為與驗證

遊戲以靜音開始。頂部「開啟聲音／靜音」控制全部聲音；「音量」面板分開控制音樂／音效，預設 40%／45%，另有 0.8 倍內部增益。設定僅保留於本次執行，滑桿歸零完全靜音該類；授權致謝在同一面板。所有學習內容仍可視覺閱讀。

## 播放與選項

`GameAudio` autoload 跨場景持續存在，`game_shell.tscn` 提供音量介面。首頁／介紹共用 Oud 音樂；五題共用 Darbuka 工房音樂；4.6 秒開棺後轉 Ney 結果音樂。音樂交叉淡化 0.65 秒，進入開棺前 0.16 秒淡出。選擇、前後翻頁、視窗重排及圖解不重播背景音樂。開棺共用持久時鐘，重建 UI 保留進度；離開視窗暫停，返回需點「繼續遊戲」。

| 內容選項 ID | 音檔 |
|---|---|
| 腦部 A 鼻腔／B 香油／C 開顱 | nasal-metal／anoint-oil／tool（原聲） |
| 三個內臟選項 | metal-tray（已確認 v5，0.42 秒） |
| 天然鹼／清水／啤酒 | mineral／liquid／liquid，原聲 |
| 填充再包亞麻布／直接包亞麻布／填充再包紙草 | fill-linen／cloth（原聲）／fill-papyrus |
| 面具入棺／面具在棺旁／無面具入棺 | coffin-placement／bed-placement／coffin-placement |

複合包裹聲在 0–0.9 秒填充，1.02 秒起包裹；入棺 2.5 秒、棺旁放床 1.05 秒。選項音效依內容 ID 對應，不受隨機排列影響，不以音調洩漏正誤；所有 243 組合共用揭曉聲音。提交聲已包含在開棺軌，不疊第二個封記。翻頁保留原始翻書聲。

短音效全域 120 ms 防連點，兩個單聲部聲道交替，舊聲淡出 25 ms、新聲淡入 8 ms；換選項／翻頁可打斷長聲效，不阻擋互動或排隊補播。圖解開啟將音樂降至 70%，關閉恢復。沒有新增學生重播／跳過開棺按鈕，未改計分、紀錄或 Firestore。

目前 22 個完成 WAV，合計 6,108,274 bytes（約 5.83 MiB），以 PCM16 匯入。未收錄原始素材下載檔、試聽頁、舊托盤、未使用的獨立 submit／tray／burial 版本。完整來源與 Ney 必須保留的 CC BY 4.0 署名見根目錄 `AUDIO-LICENSES.md`。

## 檢查

在完成 Godot 匯入後執行：

```text
godot --audio-driver Dummy --path . --script res://tests/test_audio_integration.gd
godot --headless --path . --script res://tests/test_session.gd
godot --path . --audio-driver Dummy --script res://tests/test_visual_questions.gd
godot --path . --audio-driver Dummy --script res://tests/test_ritual.gd
godot --path . --audio-driver Dummy --script res://tests/test_head_side_crack.gd
```

音訊測試檢查 v5／翻書 SHA-256、三首音樂循環、全部 15 個選項、七個新增聲效在關閉音樂時的實際混音 PCM、靜音歸零、跨頁持續播放、開棺同步、圖解、重玩與四種視窗尺寸；結果在 `review/audio-integration.json`。測試資料與日誌不提交。

## Web 相容界線

現有 Web preset 為單執行緒、Compatibility renderer；本輪以 Windows Godot 驗證，沒有發佈新的 Web build，也不宣稱實體 iPad／手機或 Safari 已通過。瀏覽器需點擊才解鎖音訊；必須再驗證首次開聲、背景分頁暫停恢復、音量、WAV 循環及 4.6 秒過場延遲。

Godot Web 的預設 Sample 播放不支援 AudioEffects；本遊戲 runtime 使用完成 WAV 與播放器／bus 音量，未用 AudioEffectCapture，後者僅在 native 測試腳本內。Native PCM 測試不能原樣當作 Web 混音驗收。改成 Stream 可使用更多引擎音訊功能但可能增加延遲，須測試後才決定。[官方 Web 音訊說明](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#audio-playback)
