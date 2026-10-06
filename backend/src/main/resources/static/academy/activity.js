'use strict';

function appMetricLabel(kind) { return ({GAME_SAVED:'Saved games',ONLINE_GAME:'Online games',PUZZLE_COMPLETED:'Normal puzzles',PUZZLE_SPRINT:'Puzzle sprints',POSITION_RETRY:'Position Retry'})[kind] || kind; }
function appReportSections(report) {
  const daily=report.appDaily||[],results=report.assignmentResults||[];
  return '<h2>App practice</h2><p>Opted-in personal practice · app-reported counts · UTC dates. Separate from coach observations; totals are not added together.</p>' +
    (daily.length?table(['Date','Activity','Events','Solved','Attempts'],daily.map(d=>[esc(d.day),esc(appMetricLabel(d.kind)),num(d.events),num(d.solved),num(d.attempted)])):empty('No shared app practice in this report period.'))+
    '<h2>Academy assignment results</h2><p>Student/app-reported submissions for this academy.</p>' +
    (results.length?table(['Assignment','Attempts','Result','Student notes'],results.map(r=>[esc(r.title),num(r.attempts),r.solved?'Completed':'Needs practice',esc(r.notes)])):empty('No assignment submissions in this report period.'));
}

function appPracticeChart(daily,checkedAt) {
  if(!daily.length)return empty('No shared app practice in the last 30 days.');
  const end=new Date(checkedAt);end.setUTCHours(0,0,0,0);
  const buckets=Array.from({length:30},(_,i)=>{const d=new Date(end);d.setUTCDate(d.getUTCDate()-29+i);return {day:d.toISOString().slice(0,10),games:0,puzzles:0,retries:0};});
  const byDay=new Map(buckets.map(b=>[b.day,b]));
  for(const d of daily){const b=byDay.get(d.day);if(!b)continue;if(['GAME_SAVED','ONLINE_GAME'].includes(d.kind))b.games+=Number(d.events);if(['PUZZLE_COMPLETED','PUZZLE_SPRINT'].includes(d.kind))b.puzzles+=Number(d.solved);if(d.kind==='POSITION_RETRY')b.retries+=Number(d.attempted);}
  const maximum=Math.max(1,...buckets.flatMap(b=>[b.games,b.puzzles,b.retries]));
  const series=[['games','#3987ff','Games'],['puzzles','#22bc91','Puzzles solved'],['retries','#9254ff','Retry attempts']];
  return '<h3>App practice trend · last 30 days</h3><div class="legend">'+series.map(([,color,label])=>`<span><i class="dot" style="background:${color}"></i>${label}</span>`).join('')+'</div>'+`<svg class="chart" viewBox="0 0 640 205" role="img" aria-label="Daily app practice counts for the last thirty days">`+
    [0,1,2,3].map(i=>`<line class="grid" x1="35" x2="610" y1="${20+i*50}" y2="${20+i*50}"/><text x="0" y="${24+i*50}">${Math.round(maximum*(1-i/3))}</text>`).join('')+
    buckets.map((b,i)=>series.map(([key,color],j)=>`<rect x="${38+i*19+j*5}" y="${170-b[key]/maximum*150}" width="4" height="${b[key]/maximum*150}" fill="${color}"><title>${b.day}: ${b[key]} ${key}</title></rect>`).join('')+(i%7===0?`<text x="${38+i*19}" y="194">${b.day.slice(5)}</text>`:'')).join('')+'</svg><p class="small muted">UTC dates · zeros mean no received/shared events, not proof of inactivity. Normal puzzle completions exclude sprint and assignment sessions.</p>';
}

function mistakePositionBoard(fen){
 const ranks=String(fen||'').split(' ')[0].split('/'),pieces={K:'♔',Q:'♕',R:'♖',B:'♗',N:'♘',P:'♙',k:'♚',q:'♛',r:'♜',b:'♝',n:'♞',p:'♟'};
 if(ranks.length!==8)return '';
 let cells='';for(let r=0;r<8;r++){let file=0;for(const c of ranks[r]){const count=/[1-8]/.test(c)?Number(c):1;for(let n=0;n<count;n++){if(file>=8)return '';cells+=`<span style="display:flex;align-items:center;justify-content:center;background:${(r+file)%2?'#b5c9df':'#f1f5fa'};color:#101827">${pieces[c]||''}</span>`;file++;}}if(file!==8)return '';}
 return `<div role="img" aria-label="Shared mistake position, White at bottom" style="display:grid;grid-template-columns:repeat(8,22px);grid-auto-rows:22px;font-size:21px;width:176px">${cells}</div>`;
}
function mistakeBankPanel(records){
 if(!records.length)return '<h3>Mistake Bank</h3><p>No shared mistake positions yet. Joined students can enable Mistake Bank sharing in My Academy, then open Mistake Bank in the updated app.</p>';
 const now=Date.now(),due=records.filter(r=>Date.parse(r.position.nextReview)<=now).length;
 return `<h3>Mistake Bank · spaced review</h3><p>${records.length} shared positions · ${due} due for review. Latest snapshot, up to 300 visible positions; app-reported analysis and practice, separate from coach observations.</p>`+table(['Student','Position','Analysis','Practice','Next review'],records.map(r=>{const p=r.position;return [esc(studentName(r.student_id)),mistakePositionBoard(p.fen)+`<details><summary>FEN</summary><code style="overflow-wrap:anywhere">${esc(p.fen)}</code></details>`,`${esc(p.classification)} · ${num(p.centipawnLoss)} cp loss<br>Played: ${esc(p.playedMove)}<br>Best: ${esc(p.bestMove)}`,`${num(p.successes)} successful / ${num(p.attempts)} attempts<br>Review stage ${num(p.stage)} / 5`,esc(new Date(p.nextReview).toLocaleString())];}));
}
// Independent refresh: never replaces an open form or moves keyboard focus.
(() => {
  const previousDashboard = dashboard, previousProfile = profile, previousPage=page;
  let cached = null, cacheKey = '', busy = false;
  const key = () => state.token + ':' + state.org + ':' + state.page + ':' + (state.student||'');
  function panel() {
    if (state.demo) return '';
    return '<section class="card" id="app-activity"><h2>App activity</h2><p>Checking shared activity…</p></section>';
  }
  dashboard = who => previousDashboard(who) + panel();
  profile = () => previousProfile() + panel();
  page = who => previousPage(who) + (['analytics','reports','assignments'].includes(state.page)?panel():'');
  function paint(error) {
    const host = document.getElementById('app-activity');
    if (!host) return;
    const data = cacheKey === key() ? cached : null;
    const own = state.data.students.find(s => s.account_id === state.me.accountId);
    const enabled = data?.sharing.some(s => s.student_id === own?.id && s.enabled);
    const events = (data?.events || []).filter(e => state.page !== 'profile' || e.student_id === state.student);
    const weaknesses = (data?.weaknesses || []).filter(e => state.page !== 'profile' || e.student_id === state.student);
    const daily=(data?.daily||[]).filter(e=>state.page!=='profile'||e.student_id===state.student);
    const results=(data?.assignmentResults||[]).filter(e=>state.page!=='profile'||e.student_id===state.student);
    host.innerHTML = '<h2>App activity</h2><p class="small muted">Updates every 15 seconds while this tab is visible. Only activity after student opt-in is shown. Game events indicate saved games, not completed analysis.</p>' +
      (state.data.role === 'STUDENT' ? `<p>Share new saved and online game activity, analyzed weaknesses, puzzle-sprint results and Position Retry attempts with this academy’s administrators, assigned coaches and linked parents. Practice scores are app-reported.</p><button type="button" class="button" data-activity-sharing="${!enabled}" ${!data ? 'disabled' : ''}>${enabled ? 'Stop activity sharing' : 'Enable activity sharing'}</button>` : '') +
      (error ? `<p role="status">${esc(error)} Activity could not be refreshed.</p>` : '') +
      (data ? `<p class="small muted">Last checked ${esc(new Date(data.checkedAt).toLocaleTimeString())} · Latest 100 events · Practice results are app-reported</p>` + appPracticeChart(daily,data.checkedAt) + (events.length ? table(['Student','Activity','When'], events.map(e => [esc(studentName(e.student_id)),e.kind === 'GAME_SAVED' ? 'Game saved in app' : e.kind === 'ONLINE_GAME' ? 'Online game finished' : e.kind==='PUZZLE_COMPLETED'?'Normal puzzle completed': e.kind === 'POSITION_RETRY' ? `Position Retry: ${e.solved ? 'Correct' : 'Needs practice'}` : `Puzzle sprint: ${num(e.solved)}/${num(e.attempted)} solved · ${num(e.seconds)} seconds`,esc(new Date(e.occurred_at).toLocaleString())])) : empty('No shared app activity yet. Students can enable sharing from My Academy in the student app or web.')) : '<p>Checking shared activity…</p>');
    if (weaknesses.length) host.innerHTML += '<h3>Analyzed weaknesses · last 30 days</h3><p class="small muted">Server-recorded analysis after sharing was enabled. Up to 100 student/category groups; separate from coach observations.</p>' + table(['Student','Category','Mistakes','Blunders'],weaknesses.map(w=>[esc(studentName(w.student_id)),esc(w.category),num(w.mistakes),num(w.blunders)]));
    host.innerHTML+=mistakeBankPanel((data?.mistakeBank||[]).filter(r=>state.page!=='profile'||r.student_id===state.student));
    if(results.length)host.innerHTML+='<h3>Recent academy assignment results</h3><p class="small muted">Student/app-reported · latest 100 submissions</p>'+table(['Student','Assignment','Attempts','Result','Notes'],results.map(r=>[esc(studentName(r.student_id)),esc(r.title),num(r.attempts),r.solved?'Completed':'Needs practice',esc(r.notes)]));
  }
  async function refresh() {
    if (busy || document.hidden || state.demo || !state.token || !state.org || !state.data || !document.getElementById('app-activity')) return;
    const requestedKey = key(); busy = true;
    try {
      const org=state.org,student=state.page==='profile'?state.student:null;
      const result = await api(`/${org}/app-activity`);
      if(student)result.mistakeBank=await api(`/${org}/students/${student}/mistake-bank`);
      if (requestedKey !== key()) return;
      cached = result; cacheKey = requestedKey; paint();
    } catch (error) { if (requestedKey === key()) { cached = null; paint(error.message); } }
    finally { busy = false; }
  }
  document.addEventListener('click', async event => {
    const exportButton=event.target.closest('[data-action="report-app-csv"]');
    if(exportButton){const r=reportData(exportButton.dataset.id);download('student-app-practice.csv',[['Student','Date','Source','Activity','Events','Solved','Attempts','Notes'],...(r.appDaily||[]).map(d=>[r.student,d.day,'App practice',appMetricLabel(d.kind),d.events,d.solved,d.attempted,'']),...(r.assignmentResults||[]).map(a=>[r.student,a.created_at,'Academy assignment',a.title,1,a.solved?1:0,a.attempts,a.notes])]);return;}
    const button = event.target.closest('[data-activity-sharing]');
    if (!button) return;
    button.disabled = true;
    try { await api(`/${state.org}/app-activity/sharing`, 'PUT', {enabled:button.dataset.activitySharing === 'true'}); await refresh(); }
    catch (error) { toast(error.message); }
    finally { if(button.isConnected) button.disabled=false; }
  });
  const originalRender = render;
  render = function () { originalRender(); if (state.data && !state.demo) { paint(); refresh(); } };
  if (!window.__ACADEMY_TEST__) { setInterval(refresh,15000); document.addEventListener('visibilitychange',refresh); }
})();
