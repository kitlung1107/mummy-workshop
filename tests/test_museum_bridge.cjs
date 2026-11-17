const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),{webcrypto}=require('node:crypto');
function setup(saved=new Map()){
 const listeners={},sent=[],parent={postMessage:(data,origin)=>sent.push({data,origin})},host='https://kitlung1107.github.io';let reloaded=false,storageFail=false;
 const c={console,crypto:webcrypto,URL,URLSearchParams,Map,Date,JSON,setInterval:()=>{},addEventListener:(type,fn)=>listeners[type]=fn,localStorage:{getItem:k=>saved.get(k),setItem:(k,v)=>{if(storageFail)throw Error('quota');saved.set(k,v);}},location:{search:'?hqChannel=abc',replace:()=>{},reload:()=>{reloaded=true;}},parent,document:{documentElement:{dataset:{}},head:{append:()=>{}},body:{append:()=>{}},createElement:()=>({style:{},setAttribute:()=>{}})}};
 c.window=c;c.HISTORY_GAME_CONFIG={gameId:'mummy-workshop',version:'test',host:host+'/history-quest/',rulesProtocol:'mummy-game/1'};vm.createContext(c);vm.runInContext(fs.readFileSync('web/history-game-bridge.js','utf8'),c);
 const receive=(data,origin=host,source=parent)=>listeners.message({data:{protocol:'history-game/1',channel:'abc',...data},origin,source});
 return{c,receive,sent,saved,failStorage:()=>storageFail=true,reloaded:()=>reloaded};
}
let s=setup();assert.equal(s.c.HistoryMummy.complete([0,0,0,0,0]),false);
s.receive({type:'identity',identity:{scope:'u:s',rulesProtocol:'mummy-game/1'}},'https://evil.example');assert.equal(s.c.HistoryMummy.ready(),false);
s.receive({type:'identity',identity:{scope:'u:s',rulesProtocol:'mummy-game/1'}});assert.equal(s.c.HistoryMummy.ready(),true);
assert.equal(s.c.HistoryMummy.complete([0,0,0,0]),false);assert.equal(s.c.HistoryMummy.complete([0,0,0,0,3]),false);
assert.equal(s.c.HistoryMummy.complete([0,1,0,2,0]),true);const event=s.sent.at(-1).data.event;assert.equal(event.type,'complete');assert.deepEqual(Array.from(event.answers),[0,1,0,2,0]);assert.equal(JSON.parse([...s.saved.values()][0]).length,1);
const restored=setup(s.saved);restored.receive({type:'identity',identity:{scope:'u:s',rulesProtocol:'mummy-game/1'}});restored.receive({type:'accepted',eventId:event.eventId},'https://evil.example');assert.equal(JSON.parse([...s.saved.values()][0]).length,1);
restored.receive({type:'accepted',eventId:event.eventId});assert.equal(JSON.parse([...s.saved.values()][0]).length,0);
restored.receive({type:'identity',identity:{scope:'other:student',rulesProtocol:'mummy-game/1'}});assert.equal(restored.reloaded(),true);assert.equal(restored.c.HistoryMummy.ready(),false);
s=setup();s.receive({type:'identity',identity:{scope:'u:s',rulesProtocol:'mummy-game/1'}});s.failStorage();assert.equal(s.c.HistoryMummy.complete([0,0,0,0,0]),false);assert.equal(s.sent.length,0);
console.log('Museum bridge: login gate, origin checks, five answers, durable pending/reload, acknowledgement, account switch and storage failure passed.');
