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
  return workspaceStamp() + heading('Batches & Classes', 'Manage your chess batches, class schedules and learning outcomes.', admin() ? btn('Create new batch', 'batch-form', 'plus') : '') +
    `<div class="stats">${stat('Total batches', d.batches.length, 'Across your organization', 'users')}${stat('Active students', d.students.filter(s => s.active).length, 'Enabled student accounts', 'coach')}${stat('Coaches assigned', new Set(d.batches.map(b => b.coach_id).filter(Boolean)).size, 'Allocated to batches', 'users')}${stat('Recorded sessions', observations().length, 'Selected period', 'calendar')}${stat('Shared games', d.games.length, 'Available for review', 'game')}</div>
    <div class="batch-overview">${card(`All Batches (${list.length})`, table(['Batch', 'Coach', 'Students', 'Schedule', 'Level', ''], list.map(b => [
      `<strong>${esc(b.name)}</strong>`, `<span class="person">${avatar(coachName(b.coach_id))}${esc(coachName(b.coach_id))}</span>`, d.students.filter(s => s.batch_id === b.id).length,
      `<span class="schedule-text">${esc(b.schedule)}</span>`, badge(b.level), admin() ? btn('Manage', 'batch-form', '', 'soft', b.id) : ''
    ])))}${card('Class Schedule', classes())}</div><div class="analytics-row">${card('Batch Performance', batchComparison(), badge('Recorded accuracy'))}${card('Practice Consistency', practiceHeatmap(), badge('14 weeks'))}</div>`;
};

assignmentsPage = function approvedTrainingPlans() {
  const all = state.data.assignments, status = state.assignmentStatus || 'all';
  const groups = {all, pending: all.filter(a => !a.completed_at), overdue: all.filter(a => !a.completed_at && a.due_date < today()), completed: all.filter(a => a.completed_at)};
  const list = (groups[status] || all).filter(a => (a.title + ' ' + studentName(a.student_id)).toLowerCase().includes(state.search.toLowerCase()));
  return workspaceStamp() + heading('Assignments & Training Plans', 'Purposeful practice. Clear goals. Measurable progress.', trainer() ? btn('Assign training', 'assignment-form', 'plus') : '') +
    `<div class="training-filters" role="group" aria-label="Assignment status">${[['all','All training'],['pending','In progress'],['overdue','Overdue'],['completed','Completed']].map(([key, label]) => `<button type="button" data-workflow="filter" data-status="${key}" aria-pressed="${status === key}">${label}<span>${groups[key].length}</span></button>`).join('')}</div>` + assignmentList(list) +
    (state.data.role === 'STUDENT' ? btn('Share saved game', 'share-game-form', 'game', 'secondary') : '');
};

openForm = async function approvedForm(action, id) {
  await approvedOpenForm(action, id);
  const dialog = $('#modal');
  dialog.classList.toggle('form-drawer', ['batch-form', 'assignment-form'].includes(action));
};

document.addEventListener('click', async event => {
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
    }
  } catch (error) { toast(error.message); }
  finally { target.disabled = false; }
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
