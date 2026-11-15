from pathlib import Path
import zipfile,re,hashlib,json
root=Path(__file__).resolve().parents[1]
out=root.parent/'mummy-deliverables';out.mkdir(exist_ok=True)
zip_path=out/'木乃伊工房-Godot獨立試玩版.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
 for rel in ['README.md','GODOT-LICENSE.txt','GODOT-COPYRIGHT.txt']:
  z.write(root/rel,rel)
 z.write(root/'tools/serve_game.py','serve_game.py')
 z.writestr('開始試玩-Windows.bat','@echo off\r\ncd /d "%~dp0"\r\npython serve_game.py\r\npause\r\n')
 z.writestr('開始試玩-macOS.command','#!/bin/sh\ncd "$(dirname "$0")"\npython3 serve_game.py\n')
 for p in (root/'build/web').iterdir():z.write(p,'web/'+p.name)
 z.write(root/'build/linux/mummy-workshop.x86_64','linux/mummy-workshop.x86_64')
 for p in root.rglob('*'):
  if not p.is_file():continue
  rel=p.relative_to(root)
  if rel.parts[0] in ['.godot','build','review']:continue
  if p.suffix=='.import' or '__pycache__' in rel.parts:continue
  if p.name=='export_presets.cfg':
   text=re.sub(r'custom_template/(debug|release)="[^"]*"',r'custom_template/\1=""',p.read_text())
   z.writestr('godot-project/'+str(rel),text)
  else:z.write(p,'godot-project/'+str(rel))
 for name in ['test-report.json','browser-report.json','木乃伊工房-243組圖像審閱.html','木乃伊工房-關鍵組合預覽.png']:
  z.write(root/'review'/name,'review/'+name)
with zipfile.ZipFile(zip_path) as z:
 assert z.testzip() is None
 assert not any('/.godot/' in x or 'desktop.png' in x or 'phone.png' in x or 'tablet.png' in x for x in z.namelist())
 print('ZIP entries',len(z.namelist()))
print('ZIP bytes',zip_path.stat().st_size)
print('SHA256',hashlib.sha256(zip_path.read_bytes()).hexdigest())
