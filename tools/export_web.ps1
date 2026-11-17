param([Parameter(Mandatory=$true)][string]$Godot, [switch]$QA)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$projectFile=Join-Path $projectRoot 'project.godot'
$presetFile=Join-Path $projectRoot 'export_presets.cfg'
$projectBytes=[IO.File]::ReadAllBytes($projectFile)
$presetBytes=[IO.File]::ReadAllBytes($presetFile)
$utf8=[Text.UTF8Encoding]::new($false)
$destination=Join-Path $projectRoot $(if($QA){'build\web-qa'}else{'build\web'})
New-Item -ItemType Directory -Force -Path $destination | Out-Null
try {
 if($QA){
  [IO.File]::WriteAllText($projectFile,$utf8.GetString($projectBytes).Replace('run/main_scene="res://game_shell.tscn"','run/main_scene="res://tests/web_probe.tscn"'),$utf8)
  [IO.File]::WriteAllText($presetFile,$utf8.GetString($presetBytes).Replace('review/*,tests/*,tools/*,build/*','review/*,tools/*,build/*'),$utf8)
 }
 & $Godot --headless --path $projectRoot --export-release Web (Join-Path $destination 'index.html')
 if($LASTEXITCODE -ne 0){throw "Godot Web export failed ($LASTEXITCODE)"}
 if(-not $QA){
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'preview.html') -Destination $destination
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'preview_server.mjs') -Destination (Join-Path $destination 'serve.mjs')
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'WEB-PREVIEW-README.txt') -Destination (Join-Path $destination 'README.txt')
  Copy-Item -LiteralPath (Join-Path $projectRoot 'AUDIO-LICENSES.md'),(Join-Path $projectRoot 'FONT-LICENSES.md'),(Join-Path $projectRoot 'assets\fonts\OFL.txt') -Destination $destination
 }
} finally {
 if($QA){[IO.File]::WriteAllBytes($projectFile,$projectBytes);[IO.File]::WriteAllBytes($presetFile,$presetBytes)}
}
