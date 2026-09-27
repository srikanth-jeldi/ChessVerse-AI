const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const academy = path.join(__dirname, '..', 'backend', 'src', 'main', 'resources', 'static', 'academy');
const context = vm.createContext({ window: {} });
vm.runInContext(fs.readFileSync(path.join(academy, 'academy-i18n-catalog.js'), 'utf8'), context);

const catalog = context.window.ACADEMY_I18N;
const expected = ['en','te','hi','ta','kn','ml','mr','bn','gu','pa','ur','ar','es','fr','de','it','pt','ru','uk','tr','fa','zh','ja','ko','id','ms','th','vi','pl','nl','sv','el','he','sw'];
assert.deepEqual(Object.keys(catalog), expected);

const englishKeys = Object.keys(catalog.en).sort();
assert.ok(englishKeys.length >= 550, `expected broad UI coverage, got ${englishKeys.length}`);
for (const locale of expected) {
  assert.deepEqual(Object.keys(catalog[locale]).sort(), englishKeys, `${locale} key parity`);
  for (const key of englishKeys) assert.ok(String(catalog[locale][key]).trim(), `${locale}: empty ${key}`);
}

for (const key of ['Billing & Licensing','Notification Preferences','Progress Reports','Academy invitations','Attendance register','Subscription change requests']) {
  assert.ok(englishKeys.includes(key), `missing critical key: ${key}`);
  for (const locale of expected.slice(1)) assert.notEqual(catalog[locale][key], key, `${locale}: untranslated ${key}`);
}

const index = fs.readFileSync(path.join(academy, 'index.html'), 'utf8');
assert.ok(index.indexOf('academy-i18n-catalog.js') < index.indexOf('academy-i18n.js'), 'catalog must load before runtime');
console.log(`Academy i18n: ${expected.length} locales x ${englishKeys.length} strings verified`);
