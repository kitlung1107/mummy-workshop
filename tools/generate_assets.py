from pathlib import Path
import itertools,json,html
ROOT=Path(__file__).resolve().parents[1]
INK='#153c43'; GOLD='#e5b75d'
def svg(inner,w=600,h=760):
 return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'+inner+'</svg>'
def path(d,fill,stroke=INK,sw=3,extra=''):
 return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'
def ellipse(cx,cy,rx,ry,fill,stroke='none',sw=3):
 return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def rect(x,y,w,h,fill,r=0,stroke='none',sw=2):
 return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def smell(x,y,color='#b0c98a'):
 return ''.join(path(f'M {x+i*13} {y} q -12 -14 0 -26 t 0 -25','none',color,4) for i in range(3))
def coffin():
 s=path('M 216 72 Q 300 34 384 72 L 423 144 L 399 636 Q 390 704 300 716 Q 210 704 201 636 L 177 144 Z','#b87a32',INK,5)
 s+=path('M 224 88 Q 300 53 376 88 L 405 149 L 380 635 Q 373 683 300 696 Q 227 683 220 635 L 195 149 Z','#f2c363',INK,3)
 s+=path('M 231 109 Q 300 77 369 109 L 383 155 L 363 625 Q 358 663 300 676 Q 242 663 237 625 L 217 155 Z','#73513f',INK,3)
 s+=path('M 244 120 Q 300 97 356 120 L 365 160 L 345 620 Q 338 647 300 656 Q 262 647 255 620 L 235 160 Z','#b38b62','none')
 for x in (209,383):
  for y in (240,430,590):
   s+=rect(x-8,y,16,8,'#27818b',0,INK,1)+path(f'M {x} {y+27} v 36 m -9 -24 h 18','none',INK,3)+ellipse(x,y+22,6,8,'none',INK,2)
 return s

def mummy(code):
 brain,org,water,wrap,burial=[ord(c)-65 for c in code]
 pap=wrap==2; hollow=wrap==1
 mat='#d6b77b' if pap else '#f1dfba'; shade='#b79353' if pap else '#c9af87'
 body='M 261 216 Q 229 231 232 277 L 242 360 Q 248 402 258 449 L 269 582 Q 268 615 279 634 Q 300 651 321 634 Q 332 615 331 582 L 342 449 Q 352 402 358 360 L 368 277 Q 371 231 339 216 Z'
 if hollow:
  body='M 263 216 Q 237 231 241 278 L 258 338 Q 267 367 256 410 L 264 452 L 279 581 Q 271 615 280 634 Q 300 650 320 634 Q 329 615 321 581 L 336 452 L 344 410 Q 333 367 342 338 L 359 278 Q 363 231 337 216 Z'
  if org==2: body=body.replace('Q 267 367 256 410','Q 245 367 256 410').replace('Q 333 367 342 338','Q 355 367 342 338')
 head='M 253 157 Q 250 101 300 97 Q 350 101 347 157 L 335 193 Q 300 219 265 193 Z'
 if brain==2:head='M 253 157 Q 250 114 272 105 L 281 121 L 295 98 Q 350 101 347 157 L 335 193 Q 300 219 265 193 Z'
 defs=f'<defs><clipPath id="body"><path d="{body}"/></clipPath><clipPath id="head"><path d="{head}"/></clipPath><linearGradient id="cloth"><stop stop-color="{shade}"/><stop offset=".35" stop-color="{mat}"/><stop offset=".68" stop-color="{mat}"/><stop offset="1" stop-color="{shade}"/></linearGradient><linearGradient id="gold"><stop stop-color="#c18a35"/><stop offset=".45" stop-color="#ffe397"/><stop offset="1" stop-color="#d09e40"/></linearGradient></defs>'
 s=defs+path('M 282 186 L 279 229 L 321 229 L 318 186 Z',mat)
 s+=path(body,'url(#cloth)',INK,4)
 # All bandages are clipped to the same body master; papyrus uses broad sheets and vertical fibres.
 s+='<g clip-path="url(#body)">'
 if pap:
  for y in range(211,650,61):
   s+=path(f'M 225 {y} L 372 {y+18} L 367 {y+69} L 230 {y+52} Z','none','#8e713e',2)
  for x in range(240,365,7):s+=path(f'M {x} 214 q -8 160 0 240 t 0 200','none','#ac8c51',.8)
 else:
  for n,y in enumerate(range(220,657,23)):
   s+=path(f'M 221 {y} Q 300 {y+(-14 if n%2 else 20)} 375 {y+10}','none','#9d8465',2)
   s+=path(f'M 223 {y+5} Q 300 {y+(-9 if n%2 else 25)} 375 {y+15}','none','#fff2d5',2)
 # disjoint surface zones avoid muddy stain blending
 if water:
  col='#719b9d' if water==1 else '#bc8844'
  s+=path('M 234 276 Q 261 264 266 301 L 258 347 Q 239 362 239 329 Z',col,'none')
  s+=path('M 334 443 Q 351 428 348 475 L 324 575 Q 300 592 308 558 Z',col,'none')
  s+=path('M 273 583 Q 288 570 291 601 L 285 627 L 269 616 Z',col,'none')
 if org==2:
  col='#8d9270' if water==0 else '#737c58'
  s+=path('M 281 330 Q 301 320 315 338 Q 335 336 326 359 Q 333 381 312 386 Q 283 396 273 375 Q 262 351 281 330 Z',col,'none')
  s+=ellipse(290,348,6,4,'#a6a17d')+ellipse(313,373,4,3,'#6a7153')
 s+='</g>'
 # hands, gently crossed, no exposed anatomy
 s+=path('M 241 256 Q 230 277 245 304 L 304 337 Q 320 343 325 331 Q 327 321 315 313 L 270 283 L 263 251 Z',mat,INK,3)
 s+=path('M 358 256 Q 370 280 354 301 L 296 329 Q 280 335 276 322 Q 274 313 285 307 L 331 283 L 336 253 Z',mat,INK,3)
 for x,y in [(249,275),(255,287),(340,279),(334,288)]:s+=path(f'M {x-7} {y} l 16 7','none',shade,2)
 s+=path(head,'url(#cloth)',INK,4)
 s+='<g clip-path="url(#head)">'
 for y in range(110,210,15):s+=path(f'M 246 {y} q 55 16 108 3','none',shade,2)
 s+='</g>'
 # preserve a visible rear cranial edge above mask, never break the mask
 if burial!=2:
  s+=path('M 273 132 Q 300 115 327 132 L 346 190 L 332 217 L 318 198 L 282 198 L 267 217 L 254 190 Z','#236473',INK,3)
  for y in range(143,207,12):s+=path(f'M 260 {y} l 20 -4 M 320 {y-4} l 20 4','none',GOLD,6)
  s+=path('M 277 139 Q 300 130 323 139 L 320 180 Q 300 204 280 180 Z','url(#gold)',INK,2.5)
  s+=path('M 280 152 q 8 -6 14 0 M 307 152 q 7 -6 13 0 M 300 153 l -3 16 h 6 M 291 179 q 9 5 18 0','none',INK,2.5)
  s+=path('M 295 191 L 305 191 L 308 219 L 293 219 Z','#236473',INK,2)
  for y in range(197,219,5):s+=path(f'M 295 {y} l 10 3','none',GOLD,1)
  s+=ellipse(300,132,6,9,GOLD,INK,2)
 else:
  s+=path('M 268 158 q 10 7 19 0 M 313 158 q 10 7 19 0 M 291 185 q 9 4 18 0','none',INK,3)
 if brain==1:s+=smell(354,148,'#aec58b' if water==0 else '#d3dd94')
 if org==2:s+=smell(355,390)
 if water:
  col='#a1dae0' if water==1 else '#edbf72'
  for x,y in [(245,385),(344,500)]:s+=path(f'M {x} {y} q -15 21 0 24 q 15 -3 0 -24 Z',col,INK,2)
  if water==2:
   for x,y,r in [(324,568,5),(335,557,3),(319,554,3)]:s+=ellipse(x,y,r,r,'#f9e2b6',INK,1)
 return s

def result(code):
 outside=code[4]=='B'; dx=-61 if outside else 0
 s='<defs><radialGradient id="room"><stop stop-color="#1c6268"/><stop offset="1" stop-color="#082f39"/></radialGradient></defs>'
 s+=rect(0,0,600,760,'url(#room)',28)
 # architectural border
 for x in (22,578):s+=path(f'M {x} 30 V 730','none','#367078',2)
 for y in (30,730):s+=path(f'M 22 {y} H 578','none','#367078',2)
 s+=ellipse(300,674,170,35,'#092c32')
 if outside:
  s+='<g transform="translate(218 125) scale(.64 .78)">'+coffin()+'</g>'
  s+=rect(139,190,200,470,'#735744',22,INK,4)+rect(150,202,178,442,'#b49569',18,INK,2)
 else:s+=coffin()
 s+=f'<g transform="translate({dx} 0)">'+mummy(code)+'</g>'
 # arrows lie outside anatomy; labels are Godot controls placed on these endpoints
 for x1,y1,x2,y2 in [(130,130,263+dx,135),(470,287,337+dx,355),(130,402,244+dx,392),(470,552,328+dx,578),(130,663,205 if not outside else 410,638)]:
  s+=path(f'M {x1} {y1} L {x2} {y2}','none','#e9cc8f',2)
  s+=ellipse(x2,y2,4,4,'#f5dfb0',INK,1)
 return svg(s)

def detail(q,o):
 s=rect(0,0,440,190,'#e5eee8',18)
 if q==0:
  s+=ellipse(192,92,58,67,'#f0dcbc',INK,4)
  s+=path('M 236 91 l 23 11 l -20 10','none',INK,3)
  if o==1:
   s+=path('M 164 72 q -10 -32 16 -34 q 18 -14 31 2 q 30 -4 27 24 q 4 20 -17 22 L 175 85 Z','#b78388',INK,3)
   s+=smell(285,119,'#7c995e')
  elif o==0:s+=path('M 155 70 Q 193 35 224 74 M 225 74 L 246 99 L 322 99 m -9 -8 l 9 8 l -9 8','none','#2f8589',4)
  else:s+=path('M 153 50 L 172 65 L 189 28 L 208 39','none','#bc744b',7)
 elif q==1:
  s+=path('M 134 29 Q 220 9 306 29 L 288 169 L 152 169 Z','#c9dfd8',INK,3)
  if o!=1:s+=path('M 218 65 C 194 39 183 71 218 91 C 253 68 239 41 218 65 Z','#bf7370',INK,2)
  else:s+=ellipse(218,70,21,20,'none','#7b8c85',2)
  if o==2:
   for x,y in [(180,107),(241,107),(204,131),(244,145)]:s+=ellipse(x,y,19,12,'#af9b77',INK,2)
  else:
   for x in (48,77,340,369):s+=rect(x,110,22,43,'#c69d5d',5,INK,2)+ellipse(x+11,110,11,7,'#efce8f',INK,2)
 elif q==2:
  s+=rect(70,62,300,83,'#c3a477',18,INK,4)
  s+=path('M 100 91 Q 223 54 336 91 L 325 125 L 114 125 Z','#e8d4b3',INK,2)
  if o==0:
   for x in range(91,357,13):s+=path(f'M {x} 119 l 5 -9 l 5 9 Z','#f8f2df','#b2ad9b',1)
  else:
   s+=path('M 80 102 Q 110 91 140 103 T 200 103 T 260 103 T 360 103 L 360 137 L 80 137 Z','#7faeb1' if o==1 else '#c5a05a','none')
 elif q==3:
  s+=path('M 120 51 Q 220 20 320 51 L 293 158 L 147 158 Z','#d8b87a' if o==2 else '#efdebe',INK,4)
  if o==1:s+=path('M 153 61 Q 215 105 292 62 M 171 107 Q 220 139 275 107','none','#a88e6b',7)
  for y in range(65,155,30 if o==2 else 16):s+=path(f'M 139 {y} L 305 {y+12}','none','#ae8e5b',2)
  if o==2:
   for x in range(155,292,9):s+=path(f'M {x} 58 v 95','none','#ae8e5b',1)
 else:
  s+=f'<g transform="translate({-4 if o!=1 else 155} 0) scale(.32 .25)">'+coffin()+'</g>'
  s+=f'<g transform="translate({-4 if o!=1 else -40} 0) scale(.32 .25)">'+mummy('AAAA'+chr(65+o))+'</g>'
 return svg(s,440,190)

for code in map(''.join,itertools.product('ABC',repeat=5)):(ROOT/'assets/results'/f'{code}.svg').write_text(result(code))
for q in range(5):
 for o in range(3):(ROOT/'assets/details'/f'{q}_{o}.svg').write_text(detail(q,o))
s=rect(0,0,900,600,'#0b343e')
s+=ellipse(690,130,65,65,'#e8c476')
s+=path('M 0 430 L 196 223 L 384 430 Z','#b78651','none')+path('M 196 223 L 384 430 L 273 430 Z','#8b603e','none')
s+=path('M 453 430 L 646 278 L 820 430 Z','#92754d','none')
s+=path('M 0 426 Q 245 384 465 453 T 900 427 V 600 H 0 Z','#c7a26e','none')
s+=path('M 0 500 Q 285 431 490 501 T 900 491 V 600 H 0 Z','#e2bd82','none')
s+=path('M 330 478 V 153 H 568 V 478 Z','#ccaa70',INK,5)+rect(366,199,165,279,'#092c35',0,INK,4)
for x in (342,550):
 for y in (197,253,309,365):s+=ellipse(x,y,5,7,'none',INK,2)+path(f'M {x} {y+7} v 20 m -6 -12 h 12','none',INK,2)
s+=path('M 347 169 H 549','none','#f7d99d',7)
(ROOT/'assets/entrance.svg').write_text(svg(s,900,600))
print('Generated 243 result compositions, 15 detail diagrams, 1 spoiler-free entrance.')
