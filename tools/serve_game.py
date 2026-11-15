"""Local-only launcher: python3 serve_game.py; no deployment or account required."""
from pathlib import Path
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from functools import partial
import webbrowser
ROOT=Path(__file__).resolve().parent
# In the distribution this script sits next to web/. In the source tree use build/web/.
web=ROOT/'web'
if not web.is_dir():web=ROOT.parent/'build/web'
server=ThreadingHTTPServer(('127.0.0.1',8000),partial(SimpleHTTPRequestHandler,directory=str(web)))
url='http://127.0.0.1:8000/'
print('木乃伊工房：'+url+'  (Ctrl+C 停止)')
webbrowser.open(url)
try:server.serve_forever()
except KeyboardInterrupt:pass
finally:server.server_close()
