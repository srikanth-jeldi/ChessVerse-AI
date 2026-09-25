// Run with: node --test tools/academy_portal_test.cjs
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const root=path.join(__dirname,'../backend/src/main/resources/static/academy');
function harness() {
  const context=vm.createContext({window:{__ACADEMY_TEST__:true},location:{search:'?demo',pathname:'/academy'},URLSearchParams,Date,structuredClone,crypto:require('node:crypto').webcrypto,document:{addEventListener(){},querySelector(){return null;}},setTimeout(){}});
  vm.runInContext(fs.readFileSync(path.join(root,'demo.js'),'utf8'),context);
  vm.runInContext(fs.readFileSync(path.join(root,'portal.js'),'utf8'),context);
  vm.runInContext(fs.readFileSync(path.join(root,'premium.js'),'utf8'),context);
  vm.runInContext(fs.readFileSync(path.join(root,'workflow.js'),'utf8'),context);
  vm.runInContext(fs.readFileSync(path.join(root,'signin.js'),'utf8'),context);
  vm.runInContext(fs.readFileSync(path.join(root,'onboarding.js'),'utf8'),context);
  const run=code=>vm.runInContext(code,context);
  run("state.source=window.createAcademyDemo(); state.me={name:'Rohit',superAdmin:true,organizations:[state.source.organization]}; demoScope();");
  return run;
}
test('CSV supports escaped quotes, commas, CRLF and Unicode BOM',()=>{
  const run=harness();
  const csv='\uFEFFname,email\r\n"Mehta, Arjun",arjun@example.com\r\n"A ""quoted"" name",other@example.com';
  const rows=JSON.parse(run(`JSON.stringify(parseCsv(${JSON.stringify(csv)}))`));
  assert.deepEqual(rows,[{name:'Mehta, Arjun',email:'arjun@example.com'},{name:'A "quoted" name',email:'other@example.com'}]);
});
test('Malformed CSV and duplicate columns are rejected',()=>{
  const run=harness();
  for(const input of ['name,email,email\nA,a@e.com,a@e.com','name,email\n"broken,a@e.com','name,email\nA,a@e.com,extra','name,email\n"A"oops,a@e.com'])
    assert.throws(()=>run(`parseCsv(${JSON.stringify(input)})`));
});
test('Import validates duplicate students, foreign batch names and seat capacity',()=>{
  const run=harness();
  for(const row of [{name:'Duplicate',email:'arjun.mehta@example.com'},{name:'Learner',email:'new@example.com',batch:'Other academy batch'}])
    assert.throws(()=>run(`importPayload([${JSON.stringify(row)}])`));
  run('state.data.organization.seats=11');
  assert.throws(()=>run(`importPayload([{name:'New',email:'new@example.com'}])`));
});
test('Coach and parent demo views narrow all student resources',()=>{
  const run=harness();
  for(const role of ['COACH','PARENT','STUDENT']){
    run(`state.demoRole='${role}'; demoScope();`);
    assert.equal(run('state.data.students.length'),role==='COACH'?4:1);
    assert.equal(run('state.data.observations.every(o=>state.data.students.some(s=>s.id===o.student_id))'),true);
    assert.equal(run('state.data.assignments.every(o=>state.data.students.some(s=>s.id===o.student_id))'),true);
    assert.equal(run('nav().includes("Billing & Licensing")'),false);
  }
});
test('All phase-one screens render and user text is escaped',()=>{
  const run=harness();
  for(const page of ['dashboard','students','coaches','batches','profile','assignments','reports','leaderboard','branding','billing','roles','support','platform','analytics','weakness']){
    const html=run(`state.page='${page}'; page('Rohit')`);
    assert.match(html,/<h1>/,page);
    assert.equal(html.includes('undefined'),false,page);
  }
  run(`state.data.students[0].name='<img src=x onerror=alert(1)>'`);
  assert.equal(run('studentsPage().includes("<img src=x")'),false);
  assert.equal(run('studentsPage().includes("&lt;img src=x")'),true);
});
test('Demo writes never modify live data and report snapshots remain stable',()=>{
  const run=harness();
  run(`demoWrite('report-form',{studentId:'s0',period:'WEEKLY'}); demoScope()`);
  const before=run('state.data.reports[0].summary');
  run(`state.source.observations.at(-1).rating=3999; demoScope()`);
  assert.equal(run('state.data.reports[0].summary'),before);
});
test('Buttons inside forms do not submit unexpectedly',()=>{
  const run=harness();
  assert.match(run(`btn('Cancel','close')`),/type="button"/);
  assert.equal((run(`dashboard('Rohit')`).match(/id="date-range"/g)||[]).length,1);
});

test('Chart drilldown preserves coach scope and exposes recorded evidence',()=>{
  const run=harness();
  run("state.demoRole='COACH'; demoScope(); state.page='dashboard';");
  assert.match(run('chart(observations())'), /role="button" data-workflow="sessions"/);
  assert.match(run("sessionDetails('', '')"), /coach-recorded sessions/);
  assert.equal(run("sessionDetails('', '').includes('Sai Charan')"), false);
  assert.match(run("sessionDetails('', '')"), /Arjun Mehta/);
});

test('Training filters select completed and overdue assignments without changing data',()=>{
  const run=harness();
  run("state.assignmentStatus='completed'");
  assert.equal(run("assignmentsPage().includes('Mark complete')"),false);
  run("state.assignmentStatus='overdue'");
  assert.match(run('assignmentsPage()'), /Mark complete/);
  assert.equal(run('state.data.assignments.length'),24);
});

test('Student profile actions retain the selected student and parent is read only',()=>{
  const run=harness();
  run("state.student='s3'; state.page='profile'");
  assert.match(run('profile()'), /data-action="assignment-form" data-id="s3"/);
  run("state.demoRole='PARENT'; demoScope(); state.student='s0'");
  assert.equal(run("profile().includes('data-action=\"assignment-form\"')"),false);
});
