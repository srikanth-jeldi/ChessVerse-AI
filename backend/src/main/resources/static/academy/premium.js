'use strict';

// Presentation enhancements use the same authorized workspace and measured data.
// No additional APIs, analytics estimates or browser storage are introduced.
let academyChartSequence = 0;
const originalAcademyDashboard = dashboard;
const originalAcademyBatches = batchesPage;
const originalAcademyProfile = profile;
const originalAcademyLeaderboard = leaderboard;

function chartBuckets(obs) {
  const groups = new Map();
  for (const observation of obs) {
    const key = state.days > 30 ? observation.practiced_on.slice(0, 7) : observation.practiced_on;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(observation);
  }
  return [...groups.entries()].sort(([a], [b]) => a.localeCompare(b));
}

function chartPath(points) {
  if (!points.length) return '';
  let path = `M ${points[0][0]} ${points[0][1]}`;
  for (let i = 1; i < points.length; i++) {
    const previous = points[i - 1], current = points[i];
    const middle = (previous[0] + current[0]) / 2;
    path += ` C ${middle} ${previous[1]}, ${middle} ${current[1]}, ${current[0]} ${current[1]}`;
  }
  return path;
}

chart = function premiumProgressChart(obs) {
  if (!obs.length) return empty('Your progress story starts with the first recorded training session.');
  const entries = chartBuckets(obs), chartId = `academy-chart-${++academyChartSequence}`;
  const latestGroup = entries.at(-1)[1], earliestGroup = entries[0][1];
  const latestRating = avg(latestGroup, 'rating'), accuracy = avg(latestGroup, 'accuracy');
  const delta = latestRating - avg(earliestGroup, 'rating');
  const ceiling = Math.max(1000, Math.ceil(Math.max(...entries.map(([, values]) => avg(values, 'rating'))) / 400) * 400);
  const x = i => 48 + (entries.length === 1 ? .5 : i / (entries.length - 1)) * 476;
  const y = value => 207 - value * 166;
  const ratingPoints = entries.map(([, values], i) => [x(i), y(avg(values, 'rating') / ceiling)]);
  const accuracyPoints = entries.map(([, values], i) => [x(i), y(avg(values, 'accuracy') / 100)]);
  const colors = {rating:'#3286f7', accuracy:'#22b68f'};
  const area = chartPath(ratingPoints) + ` L ${x(entries.length - 1)} 207 L ${x(0)} 207 Z`;
  const series = (name, points) => `<g data-chart-series="${name}">
    <path class="chart-line" d="${chartPath(points)}" stroke="${colors[name]}"/>
    ${points.map(([cx, cy], i) => {
      const [period, values] = entries[i];
      const text = `${period}\nAverage rating: ${num(avg(values, 'rating'))}\nAccuracy: ${avg(values, 'accuracy')}%\n${values.length} training observations`;
      return `<circle class="chart-point" tabindex="0" role="img" aria-label="${esc(text)}" data-chart-tip="${esc(text)}" cx="${cx}" cy="${cy}" r="4" fill="white" stroke="${colors[name]}" stroke-width="2.5"/>`;
    }).join('')}
  </g>`;
  return `<div class="premium-chart">
    <div class="chart-summary"><div><strong>${num(latestRating)}</strong>${entries.length > 1 ? `<span class="trend" ${delta < 0 ? 'style="color:#d06b63;background:#fff0ee"' : ''}>${delta >= 0 ? '+' : ''}${delta} pts</span>` : ''}<small>Latest average rating</small></div><div><strong>${accuracy}<span style="font-size:16px;color:#91a0b6">%</span></strong><small>Latest average accuracy</small></div></div>
    <div class="chart-legend"><button type="button" data-toggle-series="rating" aria-pressed="true"><i style="--series-color:${colors.rating}"></i>Average rating</button><button type="button" data-toggle-series="accuracy" aria-pressed="true"><i style="--series-color:${colors.accuracy}"></i>Accuracy</button><span class="chart-hint">Hover to explore</span></div>
    <svg viewBox="0 0 580 244" role="img" aria-label="Student rating and accuracy trend; focus the points to inspect values">
      <defs><linearGradient id="${chartId}-fill" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#3286f7" stop-opacity=".18"/><stop offset="100%" stop-color="#3286f7" stop-opacity=".015"/></linearGradient></defs>
      ${[0,1,2,3,4].map(i => `<line class="gridline" x1="48" x2="524" y1="${41 + i * 41.5}" y2="${41 + i * 41.5}"/><text text-anchor="end" x="36" y="${45 + i * 41.5}">${Math.round(ceiling * (1-i/4))}</text><text x="538" y="${45 + i * 41.5}">${100-i*25}%</text>`).join('')}
      <path data-chart-series="rating" d="${area}" fill="url(#${chartId}-fill)"/>
      ${series('rating', ratingPoints)}${series('accuracy', accuracyPoints)}
      ${entries.map(([key], i) => {
        const interval = Math.max(1, Math.ceil(entries.length / 7));
        if (i % interval && i !== entries.length - 1) return '';
        const label = state.days > 30 ? new Date(key + '-15T12:00:00').toLocaleDateString('en', {month:'short'}) : key.slice(5);
        return `<text text-anchor="middle" x="${x(i)}" y="233">${esc(label)}</text>`;
      }).join('')}
    </svg><div class="chart-note"><span>Rating · left axis / Accuracy · right axis</span><span>Session averages</span></div>
  </div>`;
};

function academyHero() {
  const d = state.data, obs = observations(), attempts = sum(obs, 'retry_attempts');
  const completed = d.assignments.filter(a => a.completed_at).length;
  const completion = d.assignments.length ? Math.round(completed / d.assignments.length * 100) : null;
  const retry = attempts ? Math.round((attempts - sum(obs, 'retry_failures')) / attempts * 100) : null;
  return `<section class="academy-hero" aria-label="Academy training overview"><div class="hero-copy"><img class="hero-emblem" src="app-icon.png" alt="ChessVerseAI official king icon"><div><div class="eyebrow">${d.role === 'COACH' ? 'THE COACHING EDGE' : 'A LITTLE BETTER. EVERY MOVE.'}</div><h2>Great minds start with a move.</h2><p>Turn today's practice into tomorrow's breakthrough.</p></div></div><div class="hero-scores"><div class="hero-score"><label>Assignment completion</label><strong>${completion === null ? '—' : completion + '%'}</strong><div class="hero-progress"><span style="width:${completion || 0}%"></span></div><small>${completed} of ${d.assignments.length} assignments · all time</small></div><div class="hero-score"><label>Position Retry success</label><strong>${retry === null ? '—' : retry + '%'}</strong><div class="hero-progress"><span style="width:${retry || 0}%"></span></div><small>${attempts} attempts · selected period</small></div></div></section>`;
}

function trainingVolume(obs) {
  const entries = chartBuckets(obs).slice(-8);
  if (!entries.length) return empty('Training hours will appear as coaches record sessions.');
  const values = entries.map(([, group]) => sum(group, 'minutes') / 60);
  const maximum = Math.max(1, ...values);
  return `<div class="chart-summary"><div><strong>${(sum(obs, 'minutes') / 60).toFixed(1)}<span style="font-size:15px;color:#9aa5b8"> hrs</span></strong><small>Recorded training · selected period</small></div><div><strong>${num(sum(obs,'tactics'))}</strong><small>Tactics solved</small></div></div><div class="performance-bars" role="img" aria-label="Recorded training hours by period">${entries.map(([period, group], i) => `<div class="performance-column" tabindex="0" data-chart-tip="${esc(period + '\n' + values[i].toFixed(1) + ' training hours\n' + group.length + ' sessions')}"><span class="bar-value">${values[i].toFixed(1)}</span><div class="bar" style="height:${Math.max(2,values[i]/maximum*118)}px"></div></div>`).join('')}</div><div class="bar-labels">${entries.map(([period]) => `<span>${esc(state.days > 30 ? new Date(period+'-15T12:00:00').toLocaleDateString('en',{month:'short'}) : period.slice(5))}</span>`).join('')}</div>`;
}

function practiceHeatmap(studentId = null) {
  const source = state.data.observations.filter(o => !studentId || o.student_id === studentId);
  const counts = new Map();
  source.forEach(o => counts.set(o.practiced_on, (counts.get(o.practiced_on) || 0) + 1));
  const now = new Date(today()+'T12:00:00Z'), start = new Date(now);
  start.setUTCDate(now.getUTCDate() - 97);
  let activeDays = 0, sessions = 0;
  const cells = Array.from({length:98}, (_, i) => {
    const day = new Date(start); day.setUTCDate(start.getUTCDate() + i);
    const key = day.toISOString().slice(0,10), count = counts.get(key) || 0;
    if (count) activeDays++;
    sessions += count;
    const level = count ? count < 3 ? 1 : count < 6 ? 2 : count < 10 ? 3 : 4 : 0;
    return `<button type="button" class="heat-cell" data-level="${level}" data-chart-tip="${esc(date(key) + '\n' + count + ' recorded sessions')}" aria-label="${esc(date(key) + ': ' + count + ' recorded sessions')}"></button>`;
  }).join('');
  return `<div class="chart-summary"><div><strong>${activeDays}</strong><small>Days with recorded practice</small></div><div><strong>${num(sessions)}</strong><small>Training observations</small></div></div><div class="heatmap-scroll"><div class="heatmap" role="group" aria-label="Practice activity across the last 14 weeks">${cells}</div></div><div class="heatmap-meta"><span>Last 14 weeks · daily sessions</span><span class="levels">Less ${['#eef1f7','#d5ece3','#8bd5b9','#41bb90','#179568'].map(c=>`<i style="background:${c}"></i>`).join('')} More</span></div><p class="chart-note">Recorded practice activity; not classroom attendance.</p>`;
}

function batchComparison() {
  const batches = state.data.batches.slice(0,8);
  if (!batches.length) return empty('Create a batch to start comparing training progress.');
  const obs = observations();
  const values = batches.map(batch => {
    const ids = new Set(state.data.students.filter(s => s.batch_id === batch.id).map(s=>s.id));
    const sessions = obs.filter(o=>ids.has(o.student_id));
    return {sessions, value: sessions.length ? avg(sessions,'accuracy') : null};
  });
  return `<div class="chart-note" style="margin-bottom:17px">Average recorded accuracy · selected period · not win rate</div><div class="performance-bars" role="img" aria-label="Batch accuracy comparison">${batches.map((batch,i)=>`<div class="performance-column" tabindex="0" data-chart-tip="${esc(batch.name+'\n'+(values[i].value === null ? 'No observations' : values[i].value+'% average accuracy\n'+values[i].sessions.length+' observations'))}"><span class="bar-value">${values[i].value === null ? '—' : values[i].value+'%'}</span><div class="bar" style="height:${values[i].value === null ? 0 : values[i].value*1.15}px;${values[i].value===null?'opacity:0':''}"></div></div>`).join('')}</div><div class="bar-labels">${batches.map(batch=>`<span>${esc(batch.name)}</span>`).join('')}</div>`;
}

dashboard = function premiumDashboard(who) {
  let html = originalAcademyDashboard(who);
  html = html.replace('<div class="stats">', academyHero() + '<div class="stats">');
  const analytics = `<div class="analytics-row">${card('Training Momentum',trainingVolume(observations()),badge('Measured practice'))}${card('Practice Consistency',practiceHeatmap(),badge('14 weeks'))}</div>`;
  return html.replace('<div class="dashboard-bottom">', analytics + '<div class="dashboard-bottom">');
};

batchesPage = function premiumBatches() {
  return originalAcademyBatches() + `<br><div class="analytics-row">${card('Batch Performance',batchComparison(),badge('Accuracy'))}${card('Training Momentum',trainingVolume(observations()),range())}</div>`;
};

profile = function premiumStudentProfile() {
  const html = originalAcademyProfile();
  if (!state.student || !state.data.students.length) return html;
  return html + `<br><div class="analytics-row">${card('Practice Consistency',practiceHeatmap(state.student),badge('Personal activity'))}${card('Training Momentum',trainingVolume(observations(state.student)),badge('Selected period'))}</div>`;
};

leaderboard = function premiumEngagement() {
  return originalAcademyLeaderboard() + `<br><div class="analytics-row">${card('Practice Consistency',practiceHeatmap(),badge('14 weeks'))}${card('Batch Performance',batchComparison(),badge('Accuracy'))}</div>`;
};

function hideChartTooltip() {
  const tooltip = document.getElementById('chart-tooltip');
  if (tooltip) tooltip.hidden = true;
}

function showChartTooltip(target, event) {
  let tooltip = document.getElementById('chart-tooltip');
  if (!tooltip) {
    tooltip = document.createElement('div');
    tooltip.id = 'chart-tooltip';
    tooltip.setAttribute('role','tooltip');
    document.body.appendChild(tooltip);
  }
  tooltip.textContent = target.dataset.chartTip;
  tooltip.hidden = false;
  const rect = target.getBoundingClientRect();
  const left = event.clientX || rect.left + rect.width / 2;
  const top = event.clientY || rect.top;
  tooltip.style.left = Math.max(8,Math.min(window.innerWidth-tooltip.offsetWidth-12,left+14))+'px';
  tooltip.style.top = Math.max(8,Math.min(window.innerHeight-tooltip.offsetHeight-12,top+15))+'px';
}

document.addEventListener('pointerover', event => {
  const target = event.target.closest?.('[data-chart-tip]');
  if (target) showChartTooltip(target,event);
});
document.addEventListener('focusin', event => {
  const target = event.target.closest?.('[data-chart-tip]');
  if (target) showChartTooltip(target,event);
});
document.addEventListener('pointerout', event => {
  if (event.target.closest?.('[data-chart-tip]')) hideChartTooltip();
});
document.addEventListener('focusout', hideChartTooltip);
document.addEventListener('scroll',hideChartTooltip,true);
document.addEventListener('keydown',event=>{if(event.key==='Escape')hideChartTooltip();});
document.addEventListener('click', event => {
  hideChartTooltip();
  const button = event.target.closest?.('[data-toggle-series]');
  if (!button) return;
  const chart = button.closest('.premium-chart'), series = button.dataset.toggleSeries;
  const enabled = button.getAttribute('aria-pressed') !== 'true';
  button.setAttribute('aria-pressed',String(enabled));
  chart.querySelectorAll(`[data-chart-series="${series}"]`).forEach(element=>{
    element.style.display = enabled ? '' : 'none';
    element.querySelectorAll('[tabindex]').forEach(point=>point.setAttribute('tabindex',enabled?'0':'-1'));
  });
});

if (!window.__ACADEMY_TEST__ && state.data) render();
