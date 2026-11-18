'use strict';

// All views use the server-authorized workspace. Demo records remain isolated.
const approvedDashboard = originalAcademyDashboard;
const approvedProfile = originalAcademyProfile;
const approvedOpenForm = openForm;
const approvedChart = chart;
const approvedReload = reload;

attention = function coachingAttention() {
  return table(['Student', 'Focus area', 'Retries'], state.data.students.filter(s => latest(s.id))
    .sort((a, b) => latest(a.id).accuracy - latest(b.id).accuracy).slice(0, 5).map(s => {
      const o = latest(s.id), focus = [...weakFields].sort((a, b) => o[b[0]] - o[a[0]])[0];
      return [`<button type="button" class="person" data-action="profile" data-id="${esc(s.id)}">${avatar(s.name)}<span>${esc(s.name)}<small class="attention-rating">${num(o.rating)} rating</small></span></button>`, `<span class="attention-focus">${esc(focus[1])}</span>`, badge(o.retry_failures, o.retry_failures > 4 ? 'red' : 'orange')];
    }));
};

reload = async function refreshApprovedWorkspace() {
  await approvedReload();
  state.lastRefreshed = new Date().toLocaleTimeString();
  render();
};

function workspaceStamp() {
  return `<div class="workspace-stamp"><span>${icon('shield')} ${state.demo ? 'Demo workspace · synthetic data' : 'Coach-recorded sessions · student-shared games'}${state.lastRefreshed ? ' · Updated ' + esc(state.lastRefreshed) : ''}</span><button type="button" class="link" data-workflow="refresh">${icon('clock')} Refresh workspace</button></div>`;
}

dashboard = function approvedAcademyDashboard(who) {
  if (state.data.role !== 'COACH') return workspaceStamp() + approvedDashboard(who);
  const d = state.data, obs = observations();
  const completed = d.assignments.filter(a => a.completed_at).length;
  return workspaceStamp() + heading(`Welcome back, ${who}!`, `Your coaching overview at ${d.organization.name}.`, range()) +
    `<div class="stats coach-stats">${stat('Assigned students', d.students.length, 'Your learning community', 'users')}${stat('Practicing students', new Set(obs.map(o => o.student_id)).size, 'Selected period', 'coach')}${stat('Shared games', d.games.length, 'Available for review', 'game')}${stat('Position Retry failures', sum(obs, 'retry_failures'), 'Recorded attempts needing practice', 'target')}${stat('Completion', d.assignments.length ? Math.round(completed / d.assignments.length * 100) + '%' : '—', `${completed} of ${d.assignments.length} assignments`, 'check')}</div>
    <div class="coach-overview">${card('Students Needing Attention', attention(), link('All students', 'students'))}${card('Student Progress Trends', chart(obs), badge('Recorded sessions'))}${card('Next Coaching Actions', coachingActions(), '', 'insights-card')}</div>
    <div class="dashboard-lower">${card('Class Schedules', classes(), link('All batches', 'batches'))}${card('Recent Student Activity', activities(), link('View analytics', 'analytics'))}${card('Quick Actions', quick())}</div>
    <div class="analytics-row">${card('Recent Shared Games', gamesList(d.games))}${card('Weakness Analysis', weakness(obs))}</div>`;
};

function coachingActions() {
  const students = state.data.students.filter(s => s.active && observations(s.id).length)
    .sort((a, b) => sum(observations(b.id), 'retry_failures') - sum(observations(a.id), 'retry_failures')).slice(0, 3);
  if (!students.length) return empty('Record a session to identify the next training focus.');
  return students.map(s => {
    const obs = observations(s.id), focus = [...weakFields].sort((a, b) => sum(obs, b[0]) - sum(obs, a[0]))[0];
    return `<div class="coaching-action"><span class="avatar">${icon('target')}</span><div><strong>${esc(s.name)}</strong><p>${esc(focus[1])} · ${sum(obs, focus[0])} recorded mistakes</p><button class="link" data-action="profile" data-id="${esc(s.id)}">Review progress ${icon('arrow')}</button><button class="link" data-action="assignment-form" data-id="${esc(s.id)}">Assign practice</button></div></div>`;
  }).join('') + '<p class="chart-caption">Rules-based priorities · coach review recommended</p>';
}

chart = function actionableChart(obs) {
  const html = approvedChart(obs);
  // The period and student identify existing observations, never inferred game data.
  const student = state.page === 'profile' ? state.student : '';
  const periods = chartBuckets(obs).map(([period]) => period);
  let point = 0;
  return html.replace(/class="chart-point" tabindex="0" role="img"/g, () => {
    const period = periods[point++ % periods.length];
    return `class="chart-point" tabindex="0" role="button" data-workflow="sessions" data-period="${esc(period)}" data-student="${esc(student)}"`;
  }).replace('Hover to explore', 'Select a point to explore');
};

function sessionDetails(period, studentId) {
  const obs = observations(studentId || null).filter(o => o.practiced_on.startsWith(period));
  return `<button type="button" class="close" aria-label="Close" data-action="close">×</button><h2>Training evidence</h2><p class="intro">${esc(period)} · ${obs.length} coach-recorded sessions. These are the observations behind the chart.</p>` +
    table(['Student', 'Date', 'Rating', 'Accuracy', 'Retry failures', 'Next step'], obs.map(o => [
      esc(studentName(o.student_id)), date(o.practiced_on), num(o.rating), `${o.accuracy}%`, num(o.retry_failures),
      `<button type="button" class="link" data-workflow="student" data-student="${esc(o.student_id)}">View student ${icon('arrow')}</button>`
    ]));
}

profile = function approvedStudentProfile() {
  let html = approvedProfile();
  if (!state.data.students.length) return html;
  const student = state.student;
  const nav = `<nav class="profile-sections" aria-label="Student sections"><a href="${esc(location.pathname + location.search)}#student-overview">Overview</a><a href="${esc(location.pathname + location.search)}#student-games">Games</a><a href="${esc(location.pathname + location.search)}#student-training">Assignments</a>${trainer() ? `<button type="button" data-action="report-form" data-id="${esc(student)}">Generate report</button>` : ''}</nav>`;
  html = html.replace('<div class="grid-2">', nav + '<div class="grid-2" id="student-overview">');
  html = html.replace('<h2>Assigned Training</h2>', '<h2 id="student-training">Assigned Training</h2>');
  html = html.replace('<h2>Recent Games</h2>', '<h2 id="student-games">Recent Games</h2>');
  const cta = trainer() ? `<div class="profile-next"><div><span class="eyebrow">NEXT STEP</span><h2>Turn this review into focused practice.</h2><p>Assign puzzles, positions, openings or a master game to ${esc(studentName(student))}.</p></div>${btn('Assign training', 'assignment-form', 'arrow', '', student)}</div>` : '';
  return workspaceStamp() + html + cta;
};

batchesPage = function approvedBatches() {
  const d = state.data, list = d.batches.filter(b => (b.name + ' ' + b.schedule).toLowerCase().includes(state.search.toLowerCase()));
  return workspaceStamp() + heading('Batches & Classes', 'Manage your chess batches, class schedules and learning outcomes.', trainer() ? btn('Create new batch', 'batch-form', 'plus') : '') +
    `<div class="stats">${stat('Total batches', d.batches.length, 'Across your organization', 'users')}${stat('Active students', d.students.filter(s => s.active).length, 'Enabled student accounts', 'coach')}${stat('Coaches assigned', new Set(d.batches.map(b => b.coach_id).filter(Boolean)).size, 'Allocated to batches', 'users')}${stat('Recorded sessions', observations().length, 'Selected period', 'calendar')}${stat('Shared games', d.games.length, 'Available for review', 'game')}</div>
    <div class="batch-overview">${card(`All Batches (${list.length})`, table(['Batch', 'Coach', 'Students', 'Schedule', 'Level', ''], list.map(b => [
      `<strong>${esc(b.name)}</strong>`, `<span class="person">${avatar(coachName(b.coach_id))}${esc(coachName(b.coach_id))}</span>`, d.students.filter(s => s.batch_id === b.id).length,
      `<span class="schedule-text">${esc(b.schedule)}</span>`, badge(b.level), (admin() || b.coach_id === d.memberId) ? btn('Manage', 'batch-form', '', 'soft', b.id) : ''
    ])))}${card('Class Schedule', classes())}</div><div class="analytics-row">${card('Batch Performance', batchComparison(), badge('Recorded accuracy'))}${card('Practice Consistency', practiceHeatmap(), badge('14 weeks'))}</div>`;
};

assignmentsPage = function approvedTrainingPlans() {
  const all = state.data.assignments, status = state.assignmentStatus || 'all';
  const groups = {all, pending: all.filter(a => !a.completed_at), overdue: all.filter(a => !a.completed_at && a.due_date < today()), completed: all.filter(a => a.completed_at)};
  const list = (groups[status] || all).filter(a => (a.title + ' ' + studentName(a.student_id)).toLowerCase().includes(state.search.toLowerCase()));
  return workspaceStamp() + heading('Homework', 'Assign chess practice, track each student, and review completions.', trainer() ? btn('Assign homework', 'assignment-form', 'plus') : '') +
    `<div class="training-filters" role="group" aria-label="Assignment status">${[['all','All training'],['pending','In progress'],['overdue','Overdue'],['completed','Completed']].map(([key, label]) => `<button type="button" data-workflow="filter" data-status="${key}" aria-pressed="${status === key}">${label}<span>${groups[key].length}</span></button>`).join('')}</div>` + assignmentList(list) +
    (state.data.role === 'STUDENT' ? btn('Share saved game', 'share-game-form', 'game', 'secondary') : '');
};

const homeworkPieces = { wK:'♔',wQ:'♕',wR:'♖',wB:'♗',wN:'♘',wP:'♙',bK:'♚',bQ:'♛',bR:'♜',bB:'♝',bN:'♞',bP:'♟' };
function homeworkFen(board, turn='w') {
  const ranks=[];
  for(let rank=7;rank>=0;rank--){let row='',empty=0;for(let file=0;file<8;file++){const token=board[rank*8+file],p=token?token[1][token[0]==='w'?'toUpperCase':'toLowerCase']():'';if(p){if(empty){row+=empty;empty=0;}row+=p;}else empty++;}if(empty)row+=empty;ranks.push(row);}
  return `${ranks.join('/')} ${turn} - - 0 1`;
}
function homeworkPositionPreview(fen) {
  if(!fen)return '';
  const symbols={p:'♟',r:'♜',n:'♞',b:'♝',q:'♛',k:'♚',P:'♙',R:'♖',N:'♘',B:'♗',Q:'♕',K:'♔'};
  const ranks=String(fen).split(/\s+/)[0].split('/');if(ranks.length!==8)return '';
  const cells=ranks.flatMap(rank=>{const row=[];for(const char of rank){if(/[1-8]/.test(char))for(let i=0;i<Number(char);i++)row.push('');else row.push(symbols[char]||'');}return row;});
  if(cells.length!==64)return '';
  return `<div class="homework-preview" role="img" aria-label="Assigned chess position">${cells.map((piece,index)=>`<span class="position-square ${(index%8+Math.floor(index/8))%2?'dark':'light'}">${piece}</span>`).join('')}</div><p class="small muted">${String(fen).split(/\s+/)[1]==='b'?'Black':'White'} to move</p>`;
}
assignmentList = function homeworkAssignmentList(list) {
  return list.length ? list.map(a => `<section class="card assignment"><div class="details">${badge(a.kind.replaceAll('_',' '))}<h3>${esc(a.title)}</h3><span class="small muted">${esc(studentName(a.student_id))} · Due ${date(a.due_date)}</span><p>${esc(a.instructions)}</p>${a.position_fen?homeworkPositionPreview(a.position_fen):''}</div>${a.completed_at?badge('Completed','green'):a.due_date<today()?badge('Overdue','red'):badge('In progress','orange')}${!a.completed_at&&(trainer()||state.data.role==='STUDENT')?btn('Mark complete','complete','check','soft',a.id):''}</section>`).join('') : empty('No homework yet. Your coach will add it here.');
};
function homeworkFocus(studentIds) {
  const obs=observations().filter(o=>studentIds.includes(o.student_id));
  if(!obs.length)return {kind:'PUZZLES',title:'Tactical foundations',instructions:'Complete a short set of tactics. For every missed puzzle, identify the opponent threat and retry the position before moving on.',reason:'No recent coach-recorded focus data; this is a general practice suggestion.'};
  const focus=[...weakFields].sort((a,b)=>sum(obs,b[0])-sum(obs,a[0]))[0];
  const prompts={blunders:['Tactical awareness','Solve 5 tactical puzzles. Before each move, check every opponent check, capture and threat. Retry each missed position.'],opening_errors:['Opening principles','Review your first 10 moves in a recent game. Practise developing pieces, contesting the centre and castling safely.'],middle_errors:['Middlegame planning','Practise 5 middlegame positions. Name the opponent’s threat, choose a plan, then compare candidate moves.'],endgame_errors:['Endgame technique','Practise 5 basic endgames. Focus on king activity, passed pawns and converting an advantage safely.']};
  return {kind:'PUZZLES',title:prompts[focus[0]][0],instructions:prompts[focus[0]][1],reason:`Based on ${sum(obs,focus[0])} coach-recorded ${focus[1].toLowerCase()} observations. Please review before assigning.`};
}
function positionEditorMarkup(){
  const palette=Object.entries(homeworkPieces).map(([code,symbol])=>`<button type="button" class="position-piece" data-piece="${code}" aria-label="Place ${code[0]==='w'?'white':'black'} ${code[1]}">${symbol}</button>`).join('');
  const squares=Array.from({length:64},(_,i)=>`<button type="button" class="position-square ${(i%8+Math.floor(i/8))%2?'dark':'light'}" data-square="${'abcdefgh'[i%8]}${8-Math.floor(i/8)}" aria-label="${'abcdefgh'[i%8]}${8-Math.floor(i/8)}"></button>`).join('');
  const squareOptions=['<option value="">Select square</option>',...Array.from({length:64},(_,i)=>`<option value="${'abcdefgh'[i%8]}${1+Math.floor(i/8)}">${'abcdefgh'[i%8]}${1+Math.floor(i/8)}</option>`)].join('');
  return `<div class="homework-editor"><div class="position-palette" role="group" aria-label="Choose a chess piece">${palette}<button type="button" class="position-piece erase" data-piece="erase" aria-label="Erase square">⌫</button></div><div class="homework-board" role="group" aria-label="Homework chessboard">${squares}</div><div class="form-grid"><label>Side to move<select name="boardTurn"><option value="w">White to move</option><option value="b">Black to move</option></select></label><label>Best move · from<select name="moveFrom">${squareOptions}</select></label><label>Best move · to<select name="moveTo">${squareOptions}</select></label><label>Promotion<select name="movePromotion"><option value="">None</option><option value="q">Queen</option><option value="r">Rook</option><option value="b">Bishop</option><option value="n">Knight</option></select></label></div><p class="small muted position-help" aria-live="polite">Choose a piece, then a square. Set the correct side to move and solution move.</p></div>`;
}

openForm = async function approvedForm(action, id) {
  await approvedOpenForm(action, id);
  const dialog = $('#modal');
  dialog.classList.toggle('form-drawer', ['batch-form', 'assignment-form'].includes(action));
  if (action === 'assignment-form') {
    const form = dialog.querySelector('form');
    const controls = form.elements;
    const template = form.querySelector('[name="homeworkTemplate"]');
    if(template){
      const option=document.createElement('option');option.value='';option.textContent='Choose a starting point';option.selected=true;template.prepend(option);
      const plan=document.createElement('div');plan.className='homework-auto';plan.innerHTML='<strong>Automatic suggestion from recorded progress</strong><p>Choose a student or batch first. The suggestion is a draft for coach review.</p><button type="button" class="button secondary" data-workflow="suggest-homework">Draft homework</button><span class="homework-suggestion" aria-live="polite"></span>';
      template.closest('label')?.after(plan);
    }
    const positionSection=form.querySelector('.assignment-position');
    if(positionSection){
      const fields=positionSection.querySelectorAll('input');
      const fen=fields[0],solution=fields[1];
      const editor=document.createElement('div');editor.innerHTML=positionEditorMarkup();positionSection.append(editor);
      fen.readOnly=true;fen.setAttribute('aria-label','Position FEN generated from the chessboard');
      let board=Array(64).fill(''), selected='wQ';
      const help=positionSection.querySelector('.position-help');
      const redraw=()=>{positionSection.querySelectorAll('[data-square]').forEach(square=>{const index=(Number(square.dataset.square[1])-1)*8+'abcdefgh'.indexOf(square.dataset.square[0]);square.textContent=homeworkPieces[board[index]]||'';square.classList.toggle('occupied',!!board[index]);});fen.value=homeworkFen(board,form.elements.boardTurn.value);};
      positionSection.addEventListener('click',event=>{
        const piece=event.target.closest('[data-piece]');if(piece){selected=piece.dataset.piece;positionSection.querySelectorAll('[data-piece]').forEach(button=>button.classList.toggle('selected',button===piece));return;}
        const square=event.target.closest('[data-square]');if(!square)return;
        const index=(Number(square.dataset.square[1])-1)*8+'abcdefgh'.indexOf(square.dataset.square[0]);board[index]=selected==='erase'?'':selected;redraw();
      });
      const syncMove=()=>{solution.value=form.elements.moveFrom.value&&form.elements.moveTo.value?form.elements.moveFrom.value+form.elements.moveTo.value+form.elements.movePromotion.value:'';};
      ['moveFrom','moveTo','movePromotion'].forEach(name=>form.elements[name].addEventListener('change',syncMove));
      form.elements.boardTurn.addEventListener('change',redraw);
      fen.addEventListener('input',()=>{if(fen.value!==homeworkFen(board,form.elements.boardTurn.value))help.textContent='Board editor controls the position; edits to FEN are replaced by the board.';});
      redraw();
    }
    const sync = () => {
      for (const [name, active] of [['studentId', controls.targetType.value === 'student'], ['batchId', controls.targetType.value === 'batch']]) {
        controls[name].closest('label').hidden = !active;
        controls[name].disabled = !active;
        controls[name].required = active;
        controls[name].options[0].text = active ? 'Select ' + (name === 'studentId' ? 'a student' : 'a batch') : 'Unassigned';
      }
      for (const [selector, active] of [['.assignment-extra', controls.kind.value === 'PUZZLES'], ['.assignment-position', controls.kind.value === 'POSITIONS']]) {
        const section = form.querySelector(selector);
        section.hidden = !active;
        section.querySelectorAll('input,select').forEach(input => input.disabled = !active);
      }
      const position = controls.kind.value === 'POSITIONS';
      controls.positionFen.required = position && !!controls.bestMove.value.trim();
      controls.bestMove.required = position && !!controls.positionFen.value.trim();
      form.querySelector('.error').textContent = '';
    };
    form.addEventListener('change', sync);
    form.addEventListener('input', sync);
    form.addEventListener('invalid', event => {
      const section = event.target.closest('details');
      if (section) section.open = true;
    }, true);
    sync();
  }
};

document.addEventListener('click', async event => {
  const swatch = event.target.closest?.('[data-brand-color]');
  if (swatch) {
    const form = swatch.closest('form');
    form.elements.color.value = swatch.dataset.brandColor;
    form.elements.color.dispatchEvent(new Event('input', { bubbles:true }));
    return;
  }
  const target = event.target.closest?.('[data-workflow]');
  if (!target || !state.data) return;
  try {
    switch (target.dataset.workflow) {
      case 'refresh':
        target.disabled = true;
        await reload();
        toast(state.demo ? 'Demo workspace refreshed. Data is synthetic.' : 'Workspace updated at ' + new Date().toLocaleTimeString());
        break;
      case 'sessions': {
        const dialog = $('#modal');
        dialog.classList.remove('form-drawer');
        dialog.innerHTML = sessionDetails(target.dataset.period, target.dataset.student);
        dialog.showModal();
        break;
      }
      case 'student':
        if (!state.data.students.some(s => s.id === target.dataset.student)) return;
        $('#modal').close();
        state.student = target.dataset.student;
        state.page = 'profile';
        render();
        window.scrollTo(0, 0);
        break;
      case 'filter':
        state.assignmentStatus = target.dataset.status;
        render();
        break;
      case 'suggest-homework': {
        const form=target.closest('form');if(!form)break;
        const ids=form.elements.targetType.value==='student'?[form.elements.studentId.value].filter(Boolean):state.data.students.filter(s=>s.active&&s.batch_id===form.elements.batchId.value).map(s=>s.id);
        if(!ids.length){toast('Choose a student or a batch with students first.');break;}
        const draft=homeworkFocus(ids);form.elements.title.value=draft.title;form.elements.kind.value=draft.kind;form.elements.instructions.value=draft.instructions;
        const due=new Date();due.setDate(due.getDate()+7);form.elements.dueDate.value=due.toISOString().slice(0,10);
        form.elements.kind.dispatchEvent(new Event('change',{bubbles:true}));
        form.querySelector('.homework-suggestion').textContent=draft.reason+' Review and edit before assigning.';
        break;
      }
    }
  } catch (error) { toast(error.message); }
  finally { target.disabled = false; }
});

document.addEventListener('input', event => {
  if (event.target.id !== 'brand-color') return;
  const input = event.target;
  input.setCustomValidity(/^#[0-9a-f]{6}$/i.test(input.value) ? '' : 'Enter a colour as # followed by 6 letters or numbers (0–9, A–F), e.g. #1765F7.');
  input.closest('form').querySelectorAll('[data-brand-color]').forEach(button => {
    button.setAttribute('aria-pressed', String(button.dataset.brandColor === input.value.toLowerCase()));
  });
});

document.addEventListener('keydown', event => {
  if ((event.key === 'Enter' || event.key === ' ') && event.target.matches?.('.chart-point[data-workflow]')) {
    event.preventDefault();
    event.target.dispatchEvent(new MouseEvent('click', {bubbles:true}));
  }
});

document.addEventListener('close', event => {
  if (event.target.id === 'modal') event.target.classList.remove('form-drawer');
}, true);

if (!window.__ACADEMY_TEST__ && state.data) render();
