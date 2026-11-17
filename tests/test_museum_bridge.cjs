const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),{webcrypto}=require('node:crypto');
function setup(saved=new Map(),hooks={}){
 const listeners={},sent=[],parent={postMessage:(data,origin)=>sent.push({data,origin})},host='https://kitlung1107.github.io';let reloaded=false,storageFail=false,tick;
 const c={console,crypto:webcrypto,URL,URLSearchParams,Map,Date,JSON,setInterval:fn=>{tick=fn;},addEventListener:(type,fn)=>listeners[type]=fn,localStorage:{get length(){return saved.size;},key:i=>{const k=[...saved.keys()][i]??null;if(hooks.key)hooks.key(k);return k;},removeItem:k=>{if(storageFail)throw Error('quota');saved.delete(k);},getItem:k=>{const value=saved.get(k);if(hooks.get)hooks.get(k,value);return value;},setItem:(k,v)=>{if(storageFail)throw Error('quota');if(hooks.set)hooks.set(k,v);saved.set(k,v);}},location:{search:'?hqChannel=abc',replace:()=>{},reload:()=>{reloaded=true;}},parent,document:{documentElement:{dataset:{}},head:{append:()=>{}},body:{append:()=>{}},createElement:()=>({style:{},setAttribute:()=>{}})}};
 c.window=c;c.HISTORY_GAME_CONFIG={gameId:'mummy-workshop',version:'test',host:host+'/history-quest/',rulesProtocol:'mummy-game/1'};vm.createContext(c);vm.runInContext(fs.readFileSync('web/history-game-bridge.js','utf8'),c);
 const receive=(data,origin=host,source=parent)=>listeners.message({data:{protocol:'history-game/1',channel:'abc',...data},origin,source});
 return{c,receive,sent,saved,tick:()=>tick(),failStorage:(fail=true)=>storageFail=fail,reloaded:()=>reloaded};
}
let s=setup();assert.equal(s.c.HistoryMummy.complete([0,0,0,0,0]),false);
s.receive({type:'identity',identity:{scope:'u:s',rulesProtocol:'mummy-game/1'}},'https://evil.example');assert.equal(s.c.HistoryMummy.ready(),false);
s.receive({type:'identity',identity:{scope:'u:s',rulesProtocol:'mummy-game/1'}});assert.equal(s.c.HistoryMummy.ready(),true);
assert.equal(s.c.HistoryMummy.complete([0,0,0,0]),false);assert.equal(s.c.HistoryMummy.complete([0,0,0,0,3]),false);
assert.equal(s.c.HistoryMummy.complete([0,1,0,2,0]),true);const event=s.sent.at(-1).data.event;assert.equal(event.type,'complete');assert.deepEqual(Array.from(event.answers),[0,1,0,2,0]);assert.equal(s.saved.size,1);
const restored=setup(s.saved);restored.receive({type:'identity',identity:{scope:'u:s',rulesProtocol:'mummy-game/1'}});restored.receive({type:'accepted',eventId:event.eventId},'https://evil.example');assert.equal(s.saved.size,1);
restored.receive({type:'accepted',eventId:event.eventId});assert.equal(s.saved.size,0);
restored.receive({type:'identity',identity:{scope:'other:student',rulesProtocol:'mummy-game/1'}});assert.equal(restored.reloaded(),true);assert.equal(restored.c.HistoryMummy.ready(),false);
s=setup();s.receive({type:'identity',identity:{scope:'u:s',rulesProtocol:'mummy-game/1'}});s.failStorage();assert.equal(s.c.HistoryMummy.complete([0,0,0,0,0]),false);assert.equal(s.sent.length,0);
console.log('Museum bridge: login gate, origin checks, five answers, durable pending/reload, acknowledgement, account switch and storage failure passed.');

const shared=new Map(),a=setup(shared),b=setup(shared);
const identify=tab=>tab.receive({type:'identity',identity:{scope:'u:s',rulesProtocol:'mummy-game/1'}});
identify(a);identify(b);
assert.equal(a.c.HistoryMummy.complete([0,0,0,0,0]),true);
assert.equal(b.c.HistoryMummy.complete([1,1,1,1,1]),true);
const ae=a.sent.at(-1).data.event,be=b.sent.at(-1).data.event;
assert.equal(shared.size,2,'independent tabs must not overwrite completions');
const afterClosure=setup(shared);identify(afterClosure);afterClosure.tick();
assert.deepEqual(afterClosure.sent.filter(x=>x.data.type==='event').map(x=>x.data.event.eventId).sort(),[ae.eventId,be.eventId].sort());
a.receive({type:'accepted',eventId:ae.eventId});
assert.equal(shared.size,1,'acknowledgement must preserve other tab completion');
assert.equal(JSON.parse([...shared.values()][0]).eventId,be.eventId);
// A stale tab completing again must not resurrect an accepted event.
b.c.HistoryMummy.complete([2,2,2,2,2]);assert.equal(shared.size,2);
assert.equal([...shared.values()].some(v=>JSON.parse(v).eventId===ae.eventId),false);
const legacy=new Map([['hq-mummy-pending-v1:test:u:s',JSON.stringify([ae,be])]]);
const migrated=setup(legacy);identify(migrated);
assert.equal(legacy.has('hq-mummy-pending-v1:test:u:s'),true);assert.equal(legacy.size,3);
migrated.receive({type:'accepted',eventId:ae.eventId});assert.equal(legacy.size,2);
const denied=new Map([['hq-mummy-pending-v1:test:u:s',JSON.stringify([ae])]]);
const blocked=setup(denied);blocked.failStorage();identify(blocked);
assert.equal(blocked.c.HistoryMummy.ready(),false);assert.equal(denied.size,1);
console.log('Concurrent tabs, isolated acknowledgement, legacy migration and migration failure passed.');

// Static export contract: both referenced scripts must be copied by local helper.
const preset=fs.readFileSync('export_presets.cfg','utf8'),helper=fs.readFileSync('tools/export_web.ps1','utf8');
for(const file of ['history-game-config.js','history-game-bridge.js']){
 assert.ok(preset.includes(file));assert.ok(helper.includes('web\\'+file));
 assert.ok(helper.indexOf(file)<helper.indexOf('if(-not $QA)'));
}
console.log('Local export bridge-copy contract passed (PowerShell/Godot execution not run).');

// A failed initial restore must not become ready on the next heartbeat.
identify(blocked);assert.equal(blocked.c.HistoryMummy.ready(),false);
blocked.failStorage(false);identify(blocked);assert.equal(blocked.c.HistoryMummy.ready(),true);
blocked.tick();assert.equal(blocked.sent.at(-1).data.event.eventId,ae.eventId);

// Old tab appends after the migrating tab read its snapshot. Preserve the
// updated legacy journal, not only the copied snapshot.
const oldKey='hq-mummy-pending-v1:test:u:s',eventPrefix=oldKey+':event:';
const racing=new Map([[oldKey,JSON.stringify([ae])]]);let appended=false;
const migrationRace=setup(racing,{get(k){
 if(k===oldKey&&!appended){appended=true;racing.set(oldKey,JSON.stringify([ae,be]));}
}});
identify(migrationRace);
assert.deepEqual(JSON.parse(racing.get(oldKey)).map(e=>e.eventId),[ae.eventId,be.eventId]);
const recovered=setup(racing);identify(recovered);recovered.tick();
assert.deepEqual(recovered.sent.filter(x=>x.data.type==='event').map(x=>x.data.event.eventId).sort(),[ae.eventId,be.eventId].sort());

// Partial migration failure retains the full legacy journal; next identity
// retries restoration instead of opening the gate with an incomplete restore.
const partial=new Map([[oldKey,JSON.stringify([ae,be])]]);let writes=0,allow=false;
const partialTab=setup(partial,{set(){if(++writes===2&&!allow)throw Error('quota');}});
identify(partialTab);assert.equal(partialTab.c.HistoryMummy.ready(),false);
assert.equal(partial.get(oldKey),JSON.stringify([ae,be]));
allow=true;identify(partialTab);partialTab.tick();
assert.equal(partialTab.c.HistoryMummy.ready(),true);
assert.deepEqual(partialTab.sent.filter(x=>x.data.type==='event').map(x=>x.data.event.eventId).sort(),[ae.eventId,be.eventId].sort());

// Ack deletion failure leaves the persisted event replayable, not lost.
const ackStorage=new Map([[eventPrefix+ae.eventId,JSON.stringify(ae)]]);
const ackTab=setup(ackStorage);identify(ackTab);ackTab.failStorage();
ackTab.receive({type:'accepted',eventId:ae.eventId});assert.equal(ackStorage.size,1);
const ackReload=setup(ackStorage);identify(ackReload);ackReload.tick();
assert.equal(ackReload.sent.at(-1).data.event.eventId,ae.eventId);

// Another tab may remove an accepted key between enumeration and getItem.
const disappearing=new Map([[eventPrefix+ae.eventId,JSON.stringify(ae)]]);
const disappearTab=setup(disappearing,{key(k){if(k===eventPrefix+ae.eventId)disappearing.delete(k);}});
identify(disappearTab);assert.equal(disappearTab.c.HistoryMummy.ready(),true);
console.log('Legacy append race, restore retries, partial migration failure and ack failure passed.');

// Two migrating tabs plus a new-format completion never overwrite each other's keys.
const simultaneous=new Map([[oldKey,JSON.stringify([ae])]]);let nested=false;
const second=setup(simultaneous);
const first=setup(simultaneous,{set(){
 if(!nested){nested=true;identify(second);assert.equal(second.c.HistoryMummy.complete([2,0,1,2,0]),true);}
}});
identify(first);
const secondEvent=second.sent.at(-1).data.event;
assert.ok(simultaneous.has(eventPrefix+ae.eventId));assert.ok(simultaneous.has(eventPrefix+secondEvent.eventId));
assert.equal(simultaneous.get(oldKey),JSON.stringify([ae]));
console.log('Concurrent migrations and completion interleaving passed.');
