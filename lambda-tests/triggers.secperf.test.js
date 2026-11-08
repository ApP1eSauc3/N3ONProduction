// Security + performance tests for the Cognito and S3 trigger Lambdas.
// Run with NODE_PATH=./stubs (no real AWS SDK client is ever constructed).
const test = require('node:test');
const assert = require('node:assert');
const { performance } = require('node:perf_hooks');

const FN = '../amplify/backend/function';
process.env.MODULES = 'verification-link';
const cmIndex = require(`${FN}/n3on3dbadbe4CustomMessage/src/index.js`);
const verification = require(`${FN}/n3on3dbadbe4CustomMessage/src/verification-link.js`);
process.env.MODULES = 'add-to-group';
const pcIndex = require(`${FN}/n3on3dbadbe4PostConfirmation/src/index.js`);
const addToGroup = require(`${FN}/n3on3dbadbe4PostConfirmation/src/add-to-group.js`);
const s3 = require(`${FN}/S3Triggerba3b2651/src/index.js`);

async function seconds(n, fn) {
  const t0 = performance.now();
  for (let i = 0; i < n; i += 1) await fn(i);
  return (performance.now() - t0) / 1000;
}
function captureLogs(fn) {
  const lines = []; const orig = { log: console.log, warn: console.warn, error: console.error };
  console.log = console.warn = console.error = (...a) => lines.push(a.join(' '));
  return Promise.resolve().then(fn).finally(() => Object.assign(console, orig)).then(() => lines);
}
const msgEvent = (triggerSource = 'CustomMessage_SignUp') => ({
  triggerSource, userName: 'sub-123', userPoolId: 'pool',
  request: { codeParameter: '{####}', userAttributes: { email: 'a@example.com', name: '<script>x</script>' } },
  response: { emailSubject: null, emailMessage: null, smsMessage: null },
});
const confirmEvent = (triggerSource = 'PostConfirmation_ConfirmSignUp') => ({
  triggerSource, userPoolId: 'pool', userName: 'sub-123', request: { userAttributes: { 'custom:role': 'AdminUser' } },
});
function stubCognito() { const sent = []; addToGroup._setClient({ send: async (c) => { sent.push(c); } }); return sent; }

// ── Module loaders (CustomMessage + PostConfirmation index.js) ───────────────

for (const [name, mod] of [['n3on3dbadbe4CustomMessage', cmIndex], ['n3on3dbadbe4PostConfirmation', pcIndex]]) {
  const parseSec = () => {
    for (const bad of ['../evil', '/etc/passwd', 'a/b', 'mod.js', 'x;y', '..']) {
      assert.throws(() => mod._parseModules(bad), /invalid trigger module name/, bad);
    }
    assert.deepStrictEqual(mod._parseModules(' verification-link , add-to-group ,'), ['verification-link', 'add-to-group']);
    assert.deepStrictEqual(mod._parseModules(undefined), [], 'unset MODULES loads nothing instead of crashing');
  };
  const parsePerf = async () => {
    const raw = Array.from({ length: 50 }, (_, i) => `module-${i}`).join(',');
    const t = await seconds(20_000, () => mod._parseModules(raw));
    assert.ok(t < 2, `${t}s`);
  };
  if (name === 'n3on3dbadbe4CustomMessage') {
    test('n3on3dbadbe4CustomMessage/index.js:parseModules security — only plain names from this folder', parseSec);
    test('n3on3dbadbe4CustomMessage/index.js:parseModules performance — 20k parses of 50 names', parsePerf);
  } else {
    test('n3on3dbadbe4PostConfirmation/index.js:parseModules security — only plain names from this folder', parseSec);
    test('n3on3dbadbe4PostConfirmation/index.js:parseModules performance — 20k parses of 50 names', parsePerf);
  }
}

test('n3on3dbadbe4CustomMessage/index.js:handler security — returns the event with only the code placeholder', async () => {
  const out = await cmIndex.handler(msgEvent(), {});
  assert.ok(out.response.emailMessage.includes('{####}'));
  assert.ok(!out.response.emailMessage.includes('sub-123'), 'no internal user id');
  assert.ok(!out.response.emailMessage.includes('<script>'), 'user attributes are never reflected into the email');
});

test('n3on3dbadbe4CustomMessage/index.js:handler performance — 50k messages', async () => {
  const t = await seconds(50_000, () => cmIndex.handler(msgEvent(), {}));
  assert.ok(t < 3, `${t}s`);
});

test('n3on3dbadbe4PostConfirmation/index.js:handler security — confirms into UserGroup only', async () => {
  const sent = stubCognito(); process.env.GROUP = 'AdminUser';
  await pcIndex.handler(confirmEvent(), {});
  assert.strictEqual(sent.length, 1);
  assert.strictEqual(sent[0].input.GroupName, 'UserGroup', 'neither env nor custom:role grants a privileged group');
});

test('n3on3dbadbe4PostConfirmation/index.js:handler performance — 20k confirmations, one call each', async () => {
  const sent = stubCognito(); process.env.GROUP = 'UserGroup';
  const t = await seconds(20_000, () => pcIndex.handler(confirmEvent(), {}));
  assert.ok(t < 3, `${t}s`);
  assert.strictEqual(sent.length, 20_000);
});

// ── verification-link.js ─────────────────────────────────────────────────────

test('n3on3dbadbe4CustomMessage/verification-link.js:handler security — no link, no id, no reflected attributes', async () => {
  for (const source of ['CustomMessage_SignUp', 'CustomMessage_ResendCode']) {
    const out = await verification.handler(msgEvent(source));
    const all = `${out.response.emailSubject} ${out.response.emailMessage} ${out.response.smsMessage}`;
    assert.ok(!/https?:\/\//.test(all), 'no clickable link (phishing-shaped emails)');
    assert.ok(!all.includes('sub-123') && !all.includes('a@example.com') && !all.includes('<script>'));
  }
  const reset = await verification.handler(msgEvent('CustomMessage_ForgotPassword'));
  assert.strictEqual(reset.response.emailMessage, null, 'other flows keep Cognito defaults');
});

test('n3on3dbadbe4CustomMessage/verification-link.js:handler performance — 100k messages', async () => {
  const t = await seconds(100_000, () => verification.handler(msgEvent()));
  assert.ok(t < 3, `${t}s`);
});

// ── add-to-group.js ──────────────────────────────────────────────────────────

test('n3on3dbadbe4PostConfirmation/add-to-group.js:resolveGroup security — privileged groups refused', async () => {
  const lines = await captureLogs(() => {
    for (const g of ['AdminUser', 'VenueOwnerUser', 'DJUser', 'usergroup', 'UserGroup ', '']) {
      assert.strictEqual(addToGroup._resolveGroup(g), 'UserGroup', JSON.stringify(g));
    }
  });
  assert.ok(lines.every((l) => !l.includes('sub-')), 'warnings carry no user ids');
  assert.strictEqual(addToGroup._resolveGroup(undefined), 'UserGroup');
});

test('n3on3dbadbe4PostConfirmation/add-to-group.js:resolveGroup performance — 500k lookups', async () => {
  const t = await seconds(500_000, () => addToGroup._resolveGroup('UserGroup'));
  assert.ok(t < 2, `${t}s`);
});

test('n3on3dbadbe4PostConfirmation/add-to-group.js:cognito security — client uses the Lambda role, no baked-in credentials', () => {
  addToGroup._setClient(undefined);
  const c = addToGroup._cognito();
  assert.deepStrictEqual(c.config, {}, 'no access keys or endpoint override in code');
});

test('n3on3dbadbe4PostConfirmation/add-to-group.js:cognito performance — one client reused across invocations', async () => {
  addToGroup._setClient(undefined);
  const first = addToGroup._cognito();
  const t = await seconds(200_000, () => assert.strictEqual(addToGroup._cognito(), first));
  assert.ok(t < 2, `${t}s`);
});

test('n3on3dbadbe4PostConfirmation/add-to-group.js:handler security — ignores custom:role and non-signup triggers', async () => {
  const sent = stubCognito(); delete process.env.GROUP;
  await addToGroup.handler(confirmEvent());
  assert.strictEqual(sent[0].input.GroupName, 'UserGroup');
  await addToGroup.handler(confirmEvent('PostConfirmation_ConfirmForgotPassword'));
  assert.strictEqual(sent.length, 1, 'a password reset never changes groups');
});

test('n3on3dbadbe4PostConfirmation/add-to-group.js:handler performance — 50k confirmations', async () => {
  const sent = stubCognito(); process.env.GROUP = 'UserGroup';
  const t = await seconds(50_000, () => addToGroup.handler(confirmEvent()));
  assert.ok(t < 3, `${t}s`);
  assert.strictEqual(sent.length, 50_000);
});

// ── S3 trigger ───────────────────────────────────────────────────────────────

const s3Record = (key) => ({ eventName: 'ObjectCreated:Put', s3: { bucket: { name: 'n3on-media' }, object: { key } } });

test('S3Triggerba3b2651/index.js:handler security — logs no object keys, tolerates malformed events', async () => {
  const lines = await captureLogs(async () => {
    const out = await s3.handler({ Records: [s3Record('public/avatars/sub-123-secret.jpg')] });
    assert.deepStrictEqual(out, { processed: 1 });
    for (const bad of [undefined, null, {}, { Records: 'x' }, { Records: [null] }]) await s3.handler(bad);
  });
  const all = lines.join('\n');
  assert.ok(!all.includes('sub-123') && !all.includes('avatars') && !all.includes('n3on-media'),
    'user ids in keys never reach CloudWatch');
});

test('S3Triggerba3b2651/index.js:handler performance — a 1,000-record batch, 200 times', async () => {
  const batch = { Records: Array.from({ length: 1_000 }, (_, i) => s3Record(`public/k${i}.jpg`)) };
  let t;
  await captureLogs(async () => { t = await seconds(200, () => s3.handler(batch)); });
  assert.ok(t < 3, `${t}s`);
});
