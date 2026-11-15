from pathlib import Path
import base64,html,json,itertools,io
from PIL import Image,ImageDraw,ImageFont
import cairosvg
ROOT=Path(__file__).resolve().parents[1]
notes={'AAAAA':'全部答對 · 乾爽亞麻與金面具','CAAAA':'頭顱缺口 · 面具仍完整','AABAA':'清水濕痕 · 無器官污斑','AACCA':'啤酒濕痕 · 紙草闊片紋理','ACAAA':'器官保留 · 乾爽局部污斑','ACCBA':'器官保留 · 不填充但腹部不空','CBCBB':'心臟移除 · 棺旁 · 不加腐敗斑','ABAAA':'外觀近似全對 · 心臟狀態不同','CCCCC':'全部選 C · 提示分區保留'}
font='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc'
canvas=Image.new('RGB',(1260,1920),'#082e38');d=ImageDraw.Draw(canvas)
d.text((32,20),'木乃伊工房  /  第一版組合預覽',font=ImageFont.truetype(font,34,index=3),fill='#f7e8c7')
d.text((32,70),'同一具母版 · 各區提示分層 · 圖像為教學示意',font=ImageFont.truetype(font,21,index=3),fill='#afcbc9')
for n,(code,note) in enumerate(notes.items()):
 col,row=n%3,n//3;x=30+col*414;y=120+row*595
 image=Image.open(io.BytesIO(cairosvg.svg2png(url=str(ROOT/'assets/results'/f'{code}.svg'),output_width=390,output_height=494))).convert('RGB')
 canvas.paste(image,(x,y))
 d.text((x+5,y+505),code+'  ·  '+str(code.count('A'))+'/5',font=ImageFont.truetype(font,24,index=3),fill='#edc787')
 # split captions safely within width
 for k,line in enumerate([note[:17],note[17:]]):
  d.text((x+5,y+542+k*24),line,font=ImageFont.truetype(font,18,index=3),fill='#e9dfcb')
canvas.save(ROOT/'review/木乃伊工房-關鍵組合預覽.png')
records=[]
for code in map(''.join,itertools.product('ABC',repeat=5)):
 data=(ROOT/'assets/results'/f'{code}.svg').read_bytes()
 records.append({'code':code,'score':code.count('A'),'src':'data:image/svg+xml;base64,'+base64.b64encode(data).decode()})
page='''<!doctype html><html lang="zh-Hant"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>木乃伊工房 · 243 組圖像審閱</title><style>*{box-sizing:border-box}body{margin:0;padding:24px;background:#082e38;color:#fff0ce;font:17px system-ui}header{max-width:1000px;margin:auto}h1{font-size:30px}p{line-height:1.7;color:#b4cdcb}input,select,button{font:inherit;border:1px solid #69858a;border-radius:9px;padding:12px;background:#174d58;color:#fff0ce}#grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:18px;margin-top:26px}article{background:#103e49;border-radius:18px;padding:12px}article img{width:100%;height:auto}article button{width:100%;cursor:pointer}dialog{background:#082e38;color:#fff0ce;border:1px solid #d3b16b;border-radius:15px;width:min(650px,96vw);max-height:95vh}dialog::backdrop{background:#001820dd}dialog img{width:100%}#count{display:block;margin-top:16px}</style><header><h1>木乃伊工房 · 243 組圖像審閱</h1><p>這是素材檢查表，不是學生答題頁。五位代碼依次為腦部／內臟／脫水／包裹／安葬。A、B、C 對應已確認方案中的固定選項；實際遊戲會打亂選項次序。</p><p>可直接開啟此檔案，無需網絡。污斑、濕痕、氣味線是教學提示。內臟 B 不額外加腐敗效果，因此部分圖像可以相同。點每張卡可放大。</p><label>組合 <input id="query" placeholder="例如 AACCA 或 CC" maxlength="5"></label> <label>答對 <select id="score"><option value="">全部</option><option>0</option><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option></select></label><span id="count"></span></header><main id="grid"></main><dialog id="detail"><button id="close">關閉</button><h2 id="name"></h2><img id="large" alt="完整組合圖"></dialog><script>const records=RECORDS;const grid=document.querySelector('#grid'),q=document.querySelector('#query'),score=document.querySelector('#score'),dialog=document.querySelector('#detail');function render(){const data=records.filter(r=>r.code.includes(q.value.toUpperCase())&&(score.value===''||r.score===Number(score.value)));document.querySelector('#count').textContent=`顯示 ${data.length} / 243 組`;grid.replaceChildren(...data.map(r=>{const a=document.createElement('article'),img=document.createElement('img'),b=document.createElement('button');img.src=r.src;img.loading='lazy';img.alt=r.code+' 組合';b.textContent=r.code+' · '+r.score+'/5 · 放大';b.onclick=()=>{document.querySelector('#large').src=r.src;document.querySelector('#name').textContent=r.code;dialog.showModal()};a.append(img,b);return a}));}q.oninput=render;score.onchange=render;document.querySelector('#close').onclick=()=>dialog.close();dialog.onclick=e=>{if(e.target===dialog)dialog.close()};render();</script></html>'''.replace('RECORDS',json.dumps(records))
(ROOT/'review/木乃伊工房-243組圖像審閱.html').write_text(page)
print('Review sheet and self-contained gallery ready.')
