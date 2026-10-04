const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
function setup(){
  const host={innerHTML:''},listeners={};let pending=[],calls=0;
  const c=vm.createContext({window:{__ACADEMY_TEST__:true},document:{hidden:false,getElementById:()=>host,addEventListener:(n,f)=>listeners[n]=f},Date,
    state:{demo:false,token:'token',org:'a',page:'dashboard',me:{accountId:'u'},data:{role:'STUDENT',students:[{id:'s',account_id:'u'}]}},
    page:()=>'',dashboard:()=>'',profile:()=>'',render:()=>{},api:()=>{calls++;return new Promise(resolve=>pending.push(resolve));},
    esc:s=>String(s).replaceAll('<','&lt;'),num:String,studentName:()=>'<unsafe>',table:(headers,rows)=>JSON.stringify(rows),empty:s=>s,toast:()=>{}});
  vm.runInContext(fs.readFileSync('backend/src/main/resources/static/academy/activity.js','utf8'),c);
  return {c,host,pending,calls:()=>calls,run:s=>vm.runInContext(s,c)};
}
test('late responses cannot leak previous tenant activity',async()=>{
  const h=setup();h.run('render()');h.run("state.org='b'");
  h.pending.shift()({sharing:[],events:[{kind:'GAME_SAVED',student_id:'s',occurred_at:new Date().toISOString()}],checkedAt:new Date().toISOString()});
  await new Promise(setImmediate);
  assert.doesNotMatch(h.host.innerHTML,/Game saved in app/);
});
test('feed escapes names and clears stale results after failed refresh',async()=>{
  const h=setup();h.run('render()');
  h.pending.shift()({sharing:[{student_id:'s',enabled:true}],events:[{kind:'POSITION_RETRY',student_id:'s',solved:0,occurred_at:new Date().toISOString()}],checkedAt:new Date().toISOString()});
  await new Promise(setImmediate);
  assert.match(h.host.innerHTML,/Needs practice/);assert.match(h.host.innerHTML,/&lt;unsafe>/);
  assert.match(h.host.innerHTML,/Stop activity sharing/);
  h.run("api=async()=>{throw new Error('Unavailable')};render()");await new Promise(setImmediate);
  assert.doesNotMatch(h.host.innerHTML,/Needs practice/);assert.match(h.host.innerHTML,/could not be refreshed/);
});
test('demo and hidden tabs make no activity calls',()=>{
  const h=setup();h.run('document.hidden=true;render()');assert.equal(h.calls(),0);
  h.run('document.hidden=false;state.demo=true;render()');assert.equal(h.calls(),0);
});
