# Selected phone preview: 11/17 選項完整重畫

Lung selected the preview immediately before “全五題重畫・統一金框” for integration. This revision restores that exact question-page source and preview header, verified against the earlier SHA-256 manifest.

The phone layout retains the earlier Egyptian papyrus, gold borders and green buttons. The mission page uses its complete redrawn illustration. The first question uses three complete redrawn cards; questions 2–5 retain the original option illustrations within the earlier redrawn blank card. The later twelve paintings, unified background and heading/button assets are deliberately absent from this revision.

The selected revision also includes the smaller phone toolbar, visible question steps, yellow selection without circle markers, portrait rotation prompts on phones/iPads, browser CSS-pixel sizing, packaged Traditional Chinese fallback font, centered results, five interactive yellow callout lines with the higher brain anchor, and the centered single-close explanation panel. Desktop/iPad landscape layouts retain the original artwork.

## Reproduce and test

Use Godot 4.7.2, import the project, then run:

```text
godot --headless --editor --import --path .
godot --path . --audio-driver Dummy --script res://tests/test_option_redraw_review.gd
godot --path . --audio-driver Dummy --script res://tests/test_brain_callout_all.gd
godot --headless --path . --script res://tests/test_session.gd
powershell -File tools/export_web.ps1 -Godot <Godot-console-executable>
node tools/preview_server.mjs build/web 8765
```

Open http://127.0.0.1:8765/preview.html. The header reads “11/17 選項完整重畫”. Web build output is ignored by Git and must be exported locally. No PCK/WASM binaries or rejected artwork are committed. This is loopback-only hosting, not a public or private cross-device deployment.

The review test covers 844×390, 1024×768, 1366×900 and 1920×1080, all fifteen option selections and explanations, frame edges, rotation, result callouts and navigation. The brain test covers all 243 answer combinations at three sizes. These are Windows/viewport simulations, not phone/iPad hardware validation.

Final verification on the integration copy: 1,269 option/layout checks, 5,104 brain-callout checks, 263 session/scoring checks, and 1,349 UI lifecycle checks all passed (7,985 total). The existing lifecycle test now expects portrait interaction blocking and the intentionally hidden compact close hint; production sources remain identical to the selected preview. Web export completed successfully. Browser re-verification after reconnect was interrupted by user input, so this integration does not claim a new browser playthrough or hardware test.

Selected source SHA-256: `c2bdc598e156c358ac27856af5f76729360fc1761ea5992d1edb67f69646cab0` (`scripts/question_pages.gd`). Preview HTML SHA-256: `8795021e5fe22e557f6951e739169e770d4e944b854cd1696ef605a66c6d3865`. Text checkout line-ending normalization can change byte hashes without changing this source version. Image dimensions, hashes and generation provenance are recorded in `tools/option-redraw-assets.json`, `tools/option-redraw-provenance.json` and `tools/mission-redraw-provenance.json`.
