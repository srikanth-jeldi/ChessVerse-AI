'use strict';

// Platform-wide product analytics are visible only to an authenticated
// EpitomeHub super administrator. Academy tenant dashboards stay unchanged.
const originalProductPlatform = platform;
const originalProductLoadPlatform = loadPlatform;

function productMoney(minor, currency) {
  try {
    return new Intl.NumberFormat(window.AcademyI18n?.locale || 'en-IN', {
      style: 'currency',
      currency: currency || 'INR',
      maximumFractionDigits: 2
    }).format(Number(minor || 0) / 100);
  } catch {
    return `${esc(currency || '')} ${(Number(minor || 0) / 100).toFixed(2)}`;
  }
}

function productEventLabel(name) {
  return String(name || '').split('_').map(word =>
    word ? word[0].toUpperCase() + word.slice(1) : ''
  ).join(' ');
}

function productAnalyticsPanel(report) {
  if (!report) return card(
    'Product Analytics',
    empty('Product metrics are loading. Academy data remains available.'),
    badge('Super admin only')
  );
  const events = Array.isArray(report.events) ? report.events : [];
  const purchases = Array.isArray(report.purchases) ? report.purchases : [];
  const returningRate = report.activeInWindow
    ? Math.round(Number(report.returningPlayers || 0) / Number(report.activeInWindow) * 100)
    : 0;
  const revenueRows = purchases.map(item => [
    esc(item.price_currency || '—'),
    num(item.purchases),
    productMoney(item.revenue_minor, item.price_currency)
  ]);
  const eventRows = events.map(item => [
    esc(productEventLabel(item.event_name)),
    num(item.events),
    num(item.players)
  ]);
  return `<section class="product-analytics" aria-label="Platform product analytics">
    ${heading('Retention & Monetisation', `Privacy-safe platform signals · Last ${Number(report.days || 30)} days`, `<select class="select" id="product-days" aria-label="Product analytics period">${[7,30,90].map(days => `<option value="${days}" ${Number(report.days)===days?'selected':''}>Last ${days} days</option>`).join('')}</select>`)}
    <div class="stats product-stats">
      ${stat('Active today', num(report.activeToday), 'Unique authenticated players', 'users')}
      ${stat('Active 7 days', num(report.active7Days), 'Privacy-safe sessions', 'chart')}
      ${stat('Returning players', num(report.returningPlayers), `${returningRate}% of active window`, 'home')}
      ${stat('Verified rewarded ads', num(report.rewardedAdsVerified), `${num(report.rewardedCoinsIssued)} coins issued`, 'spark')}
      ${stat('Ad completion', `${Number(report.rewardedAdCompletionPercent || 0).toFixed(1)}%`, `${num(report.rewardedAdStarts)} starts`, 'check')}
    </div>
    <div class="grid-2">
      ${card('Product Events', table(['Event','Events','Players'], eventRows), badge('No personal data'))}
      ${card('Verified Purchase Revenue', revenueRows.length ? table(['Currency','Purchases','Revenue'], revenueRows) : empty('No fulfilled purchases in this period.'), badge('Server verified'))}
    </div>
  </section>`;
}

platform = function productPlatform() {
  const base = originalProductPlatform();
  if (!state.platform) return base;
  return productAnalyticsPanel(state.productAnalytics) + base;
};

async function fetchProductAnalytics(days = 30) {
  const response = await fetch(`/api/v1/analytics/platform?days=${encodeURIComponent(days)}`, {
    headers: {Authorization: `Bearer ${state.token}`}
  });
  const text = await response.text();
  let value = null;
  try { value = text ? JSON.parse(text) : null; } catch { /* handled below */ }
  if (!response.ok) throw new Error(value?.message || 'Product analytics could not be loaded.');
  return value;
}

loadPlatform = async function loadPlatformWithProductAnalytics() {
  await originalProductLoadPlatform();
  if (state.demo) {
    state.productAnalytics = {
      days: 30, activeToday: 18, active7Days: 94, activeInWindow: 214,
      returningPlayers: 71, rewardedAdsVerified: 46, rewardedCoinsIssued: 2300,
      rewardedAdStarts: 58, rewardedAdCompletionPercent: 79.3,
      events: [{event_name:'session_started',events:286,players:214}], purchases: []
    };
  } else {
    try {
      state.productAnalytics = await fetchProductAnalytics(30);
    } catch (error) {
      state.productAnalytics = null;
      toast(error.message);
    }
  }
  if (state.data) render(); else renderNoOrg();
};

document.addEventListener('change', async event => {
  if (event.target.id !== 'product-days') return;
  const days = Number(event.target.value);
  event.target.disabled = true;
  try {
    state.productAnalytics = state.demo
      ? {...state.productAnalytics, days}
      : await fetchProductAnalytics(days);
    render();
  } catch (error) {
    toast(error.message);
    event.target.disabled = false;
  }
});
