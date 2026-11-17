/* Public game assets; authentication and all writes belong to the museum host. */
(() => {
  'use strict';
  const config=window.HISTORY_GAME_CONFIG,host=new URL(config.host),channel=new URLSearchParams(location.search).get('hqChannel');
  const embedded=window.parent!==window;
  let identity=null,owner=null,lastHost=0,restored=false,gate;
  const pending=new Map();
  const ready=()=>!!identity&&restored&&Date.now()-lastHost<15000&&identity.rulesProtocol==='mummy-game/1';
  function post(data){if(embedded)parent.postMessage({protocol:'history-game/1',channel,gameId:config.gameId,version:config.version,...data},host.origin);}
  function storageKey(){return 'hq-mummy-pending-v1:'+config.version+':'+identity.scope;}
  function eventKey(id){return storageKey()+':event:'+id;}
  function restore(){
    // Copy the legacy queue but NEVER remove/rewrite it: another old tab may
    // append between our read and delete. Replays are safe because the host
    // deduplicates by eventId. Retaining this small legacy journal is deliberate;
    // removing it needs an explicit all-old-tabs-closed cleanup strategy.
    const legacy=localStorage.getItem(storageKey());
    if(legacy){
      for(const e of JSON.parse(legacy))localStorage.setItem(eventKey(e.eventId),JSON.stringify(e));
    }
    const prefix=eventKey('');
    for(let i=0;i<localStorage.length;i++){
      const key=localStorage.key(i);
      if(key&&key.startsWith(prefix)){
        const value=localStorage.getItem(key);
        if(value){const e=JSON.parse(value);pending.set(e.eventId,e);}
      }
    }
  }
  window.HistoryMummy={ready,complete(answers){
    if(!ready()||!Array.isArray(answers)||answers.length!==5||!answers.every(n=>Number.isInteger(n)&&n>=0&&n<=2))return false;
    const id=crypto.randomUUID(),e={protocol:'mummy-game/1',type:'complete',eventId:id,sessionId:crypto.randomUUID(),sequence:1,answers:[...answers],playedAt:new Date().toISOString()};
    pending.set(id,e);
    try{localStorage.setItem(eventKey(id),JSON.stringify(e));}catch{pending.delete(id);if(gate){gate.textContent='未能保存紀錄，請允許瀏覽器儲存後再按完成。';gate.hidden=false;}return false;}
    post({type:'event',event:e});return true;
  }};
  addEventListener('message',event=>{
    const d=event.data;
    if(event.source!==parent||event.origin!==host.origin||!d||d.protocol!=='history-game/1'||d.channel!==channel)return;
    if(d.type==='identity'){
      if(!d.identity||typeof d.identity.scope!=='string')return;
      if(owner&&owner!==d.identity.scope){identity=null;location.reload();return;}
      identity=d.identity;owner=identity.scope;lastHost=Date.now();
      if(!restored){try{restore();restored=true;}catch{identity=null;}}
    }
    if(d.type==='locked'){identity=null;lastHost=0;}
    if(d.type==='accepted'&&identity){pending.delete(d.eventId);try{localStorage.removeItem(eventKey(d.eventId));}catch{/* Host already durably owns the event; repeated delivery is idempotent. */}}
    if(d.type==='viewport')document.documentElement.dataset.expanded=String(!!d.expanded);
  });
  function tick(){
    post({type:'hello'});
    if(ready())for(const e of pending.values())post({type:'event',event:e});
    if(gate){gate.hidden=ready();if(!ready())gate.textContent='請經歷史探索館登入，確認身份後開始遊戲。';}
  }
  addEventListener('DOMContentLoaded',()=>{
    gate=document.createElement('div');gate.id='museum-login-gate';gate.setAttribute('role','status');
    gate.style.cssText='position:fixed;inset:0;z-index:9999;background:#103e49;color:#fff0ce;display:grid;place-items:center;text-align:center;padding:2rem;font:20px sans-serif';
    const style=document.createElement('style');style.textContent='#museum-login-gate[hidden]{display:none!important}';document.head.append(style);document.body.append(gate);tick();
  });
  const entry=new URL(host);entry.searchParams.set('game',config.gameId);
  if(!embedded)location.replace(entry.href);
  setInterval(tick,1000);
})();
