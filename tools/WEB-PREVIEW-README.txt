木乃伊工房 · 私人 Web 預覽包

這是完整 Godot 遊戲，包含原插圖、音效及 243 個組合，沒有伺服器資料庫。

本機開啟（已安裝 Node.js 22 或以上）：
  node serve.mjs . 8765
再開啟 http://127.0.0.1:8765/preview.html
直接全視窗遊玩：http://127.0.0.1:8765/index.html

請勿直接雙擊 index.html 使用 file://：WebAssembly 與資源需要 HTTP。
serve.mjs 只監聽 127.0.0.1；手機及另一台電腦不能直接開這個網址。
本包沒有公開部署或修改防火牆。可將整個資料夾交給私人 HTTPS 主機管理員。

私人主機要求：
- 保留 index.html、index.js、index.wasm、index.pck 及其餘 index.* 檔名與相對路徑。
- .wasm 使用 application/wasm；.pck 使用 application/octet-stream。
- 建議在主機啟用 gzip/Brotli。單執行緒版不需要 SharedArrayBuffer 或跨來源隔離。
- 建議 HTTPS；不要把使用者憑證或私人設定寫入這個靜態包。
- AUDIO-LICENSES.md、FONT-LICENSES.md、OFL.txt 隨包保留。

遊玩：按「開啟聲音」啟用音訊；可分別調整音樂與音效。首次開頁不自動播放。
手機選項頁可上下滑動，下一步／上一步固定在下方。完成後點部位標籤開啟解說。
解說可用右上角交叉、外側空白位置或 Esc 關閉。背景分頁會暫停，返回後按「繼續遊戲」。

測試範圍與限制請見隨附 COMPATIBILITY-REPORT.txt。
Chrome/Edge 的尺寸及觸控模擬不能代表 iPhone/iPad 真機 Safari。
WebGL 2.0、WebAssembly、瀏覽器音訊政策、裝置記憶體和 GPU 仍需要真機驗收。
