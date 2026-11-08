// Security + performance tests for every function in the AppSync-backed
// Lambdas (joinEvent, purchaseTicket, rankPromotion) and their shared
// http.js / appsync.js helpers (each byte-identical copy is tested on its own).
process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT = 'https://abc.appsync-api.us-east-1.amazonaws.com/graphql';
process.env.AWS_REGION = 'us-east-1';
process.env.AWS_ACCESS_KEY_ID = 'AKIDEXAMPLE'; process.env.AWS_SECRET_ACCESS_KEY = 'secret';
const test = require('node:test'); const assert = require('node:assert');
const { performance } = require('node:perf_hooks');
const fakeAppSync = require('./fake-appsync');

const FN = '../amplify/backend/function';
const join = { appsync: require(`${FN}/joinEvent/src/appsync.js`), http: require(`${FN}/joinEvent/src/http.js`), lambda: require(`${FN}/joinEvent/src/index.js`) };
const ticket = { appsync: require(`${FN}/purchaseTicket/src/appsync.js`), http: require(`${FN}/purchaseTicket/src/http.js`), lambda: require(`${FN}/purchaseTicket/src/index.js`) };
const rank = { appsync: require(`${FN}/rankPromotion/src/appsync.js`), lambda: require(`${FN}/rankPromotion/src/index.js`) };
const T = ticket.lambda._internals; const R = rank.lambda._internals;

async function seconds(n, fn) {
  const t0 = performance.now();
  for (let i = 0; i < n; i += 1) await fn(i);
  return (performance.now() - t0) / 1000;
}
async function quiet(fn) {
  const orig = { log: console.log, warn: console.warn, error: console.error }; const lines = [];
  console.log = console.warn = console.error = (...a) => lines.push(a.join(' '));
  try { return { result: await fn(), lines }; } finally { Object.assign(console, orig); }
}
const PROVIDER = (sub) => `cognito-idp.us-east-1.amazonaws.com/p,cognito-idp.us-east-1.amazonaws.com/p:CognitoSignIn:${sub}`;
const req = (sub, body, method = 'POST') => ({ httpMethod: method, body: typeof body === 'string' ? body : JSON.stringify(body),
  requestContext: { identity: { cognitoAuthenticationProvider: sub ? PROVIDER(sub) : undefined } } });
const body = (r) => JSON.parse(r.body);
const install = (mod, handlers, db = {}) => { const f = fakeAppSync(db, { handlers }); mod.appsync._setDeps({ fetch: f.fetch, signer: null }); return f; };
const condFail = { errors: [{ message: 'cond', errorType: 'DynamoDB:ConditionalCheckFailedException' }] };

// ── http.js (joinEvent + purchaseTicket copies) ──────────────────────────────

const httpBodies = {
  callerSubSec(h) {
    assert.strictEqual(h.callerSub(req('abc-123', {})), 'abc-123');
    assert.strictEqual(h.callerSub({ requestContext: { identity: { cognitoAuthenticationProvider: 'x:CognitoSignIn:a:b' } } }), null,
      'a malformed provider string yields no identity');
    for (const bad of [undefined, {}, { requestContext: {} }, { requestContext: { identity: { cognitoAuthenticationProvider: 42 } } },
      { requestContext: { identity: { cognitoAuthenticationProvider: 'cognito-idp/p' } } }]) {
      assert.strictEqual(h.callerSub(bad), null);
    }
    assert.strictEqual(h.callerSub({ body: JSON.stringify({ userID: 'victim' }), requestContext: { identity: {} } }), null,
      'never reads identity from the body');
  },
  async callerSubPerf(h) {
    const e = req('abc-123', {}); const t = await seconds(200_000, () => h.callerSub(e));
    assert.ok(t < 2, `${t}s`);
  },
  parseBodySec(h) {
    assert.strictEqual(h.parseBody({ body: '[1,2]' }), null, 'arrays refused');
    assert.strictEqual(h.parseBody({ body: '"x"' }), null);
    assert.strictEqual(h.parseBody({ body: '{bad' }), null);
    assert.strictEqual(h.parseBody({ body: 'x'.repeat(h.MAX_BODY_BYTES + 1) }), null, 'oversized raw body');
    const big = Buffer.from(JSON.stringify({ a: 'y'.repeat(h.MAX_BODY_BYTES) })).toString('base64');
    assert.strictEqual(h.parseBody({ body: big, isBase64Encoded: true }), null, 'oversized decoded body');
    assert.deepStrictEqual(h.parseBody({ body: Buffer.from('{"eventID":"e"}').toString('base64'), isBase64Encoded: true }), { eventID: 'e' });
    assert.strictEqual(h.parseBody({ body: { eventID: 'e' } }), null, 'non-string bodies refused');
    const proto = h.parseBody({ body: '{"__proto__":{"admin":true}}' });
    assert.strictEqual(({}).admin, undefined, 'no prototype pollution'); assert.ok(proto);
  },
  async parseBodyPerf(h) {
    const ok = { body: JSON.stringify({ eventID: 'e1', quantity: 2 }) };
    const t = await seconds(100_000, () => h.parseBody(ok));
    assert.ok(t < 2, `${t}s`);
    // A valid 5 MB JSON body (API Gateway allows 10 MB) must be refused
    // without being parsed: count JSON.parse calls, not just wall time.
    const huge = { body: JSON.stringify({ eventID: 'e1', pad: 'x'.repeat(5 * 1024 * 1024) }) };
    const realParse = JSON.parse; let parses = 0;
    JSON.parse = (...a) => { parses += 1; return realParse(...a); };
    let t2;
    try { t2 = await seconds(20, () => assert.strictEqual(h.parseBody(huge), null)); } finally { JSON.parse = realParse; }
    assert.strictEqual(parses, 0, 'oversized bodies never reach JSON.parse');
    assert.ok(t2 < 1, `${t2}s`);
  },
  isValidIDSec(h) {
    assert.ok(h.isValidID('5f2c3a1e-8b4d-4e1a-9c7f-1a2b3c4d5e6f'));
    for (const bad of ['', 'a_b', '../x', 'a b', 'a/b', { $ne: 1 }, ['a'], 7, null, 'x'.repeat(65), 'é']) {
      assert.strictEqual(h.isValidID(bad), false, JSON.stringify(bad));
    }
  },
  async isValidIDPerf(h) {
    const t = await seconds(500_000, () => h.isValidID('5f2c3a1e-8b4d-4e1a-9c7f-1a2b3c4d5e6f'));
    assert.ok(t < 2, `${t}s`);
  },
  respondSec(h) {
    const r = h.respond(400, { note: '</script><script>alert(1)</script>' });
    assert.deepStrictEqual(Object.keys(r.headers), ['Content-Type'], 'no wildcard CORS or extra headers');
    assert.strictEqual(r.headers['Content-Type'], 'application/json');
    assert.deepStrictEqual(JSON.parse(r.body), { note: '</script><script>alert(1)</script>' }, 'served as JSON data, never HTML');
  },
  async respondPerf(h) {
    const p = { success: true, ticketID: 't', remainingStock: 3 };
    const t = await seconds(200_000, () => h.respond(200, p));
    assert.ok(t < 2, `${t}s`);
  },
  okSec(h) {
    const r = body(h.ok({ success: false, errorCode: 'X', ticketID: 't' }));
    assert.strictEqual(r.success, true, 'payload cannot overwrite the envelope');
    assert.strictEqual(h.ok({}).statusCode, 200);
  },
  async okPerf(h) {
    const t = await seconds(200_000, () => h.ok({ ticketID: 't' }));
    assert.ok(t < 2, `${t}s`);
  },
  failSec(h) {
    const r = h.fail(409, 'SOLD_OUT', { success: true, errorCode: 'NONE', remainingStock: 0 });
    assert.strictEqual(r.statusCode, 409);
    assert.deepStrictEqual(body(r), { remainingStock: 0, success: false, errorCode: 'SOLD_OUT' },
      'extra fields can never flip a failure into a success');
  },
  async failPerf(h) {
    const t = await seconds(200_000, () => h.fail(400, 'INVALID_REQUEST'));
    assert.ok(t < 2, `${t}s`);
  },
};

test('joinEvent/http.js:callerSub security — identity only from the signed request context', () => httpBodies.callerSubSec(join.http));
test('joinEvent/http.js:callerSub performance — 200k extractions', () => httpBodies.callerSubPerf(join.http));
test('purchaseTicket/http.js:callerSub security — identity only from the signed request context', () => httpBodies.callerSubSec(ticket.http));
test('purchaseTicket/http.js:callerSub performance — 200k extractions', () => httpBodies.callerSubPerf(ticket.http));
test('joinEvent/http.js:parseBody security — size cap, objects only, no pollution', () => httpBodies.parseBodySec(join.http));
test('joinEvent/http.js:parseBody performance — small bodies fast, 10 MB refused early', () => httpBodies.parseBodyPerf(join.http));
test('purchaseTicket/http.js:parseBody security — size cap, objects only, no pollution', () => httpBodies.parseBodySec(ticket.http));
test('purchaseTicket/http.js:parseBody performance — small bodies fast, 10 MB refused early', () => httpBodies.parseBodyPerf(ticket.http));
test('joinEvent/http.js:isValidID security — UUID-shaped strings only', () => httpBodies.isValidIDSec(join.http));
test('joinEvent/http.js:isValidID performance — 500k checks', () => httpBodies.isValidIDPerf(join.http));
test('purchaseTicket/http.js:isValidID security — UUID-shaped strings only', () => httpBodies.isValidIDSec(ticket.http));
test('purchaseTicket/http.js:isValidID performance — 500k checks', () => httpBodies.isValidIDPerf(ticket.http));
test('joinEvent/http.js:respond security — JSON only, no extra headers', () => httpBodies.respondSec(join.http));
test('joinEvent/http.js:respond performance — 200k envelopes', () => httpBodies.respondPerf(join.http));
test('purchaseTicket/http.js:respond security — JSON only, no extra headers', () => httpBodies.respondSec(ticket.http));
test('purchaseTicket/http.js:respond performance — 200k envelopes', () => httpBodies.respondPerf(ticket.http));
test('joinEvent/http.js:ok security — envelope cannot be overwritten', () => httpBodies.okSec(join.http));
test('joinEvent/http.js:ok performance — 200k responses', () => httpBodies.okPerf(join.http));
test('purchaseTicket/http.js:ok security — envelope cannot be overwritten', () => httpBodies.okSec(ticket.http));
test('purchaseTicket/http.js:ok performance — 200k responses', () => httpBodies.okPerf(ticket.http));
test('joinEvent/http.js:fail security — a failure stays a failure', () => httpBodies.failSec(join.http));
test('joinEvent/http.js:fail performance — 200k responses', () => httpBodies.failPerf(join.http));
test('purchaseTicket/http.js:fail security — a failure stays a failure', () => httpBodies.failSec(ticket.http));
test('purchaseTicket/http.js:fail performance — 200k responses', () => httpBodies.failPerf(ticket.http));

// ── appsync.js (three copies) ────────────────────────────────────────────────

const appsyncBodies = {
  async signerSec(m) {
    m.appsync._setDeps({ signer: null });
    const fake = install(m, { getEvent: () => ({ data: { getEvent: null } }) });
    await m.appsync.graphql('query Q($id: ID!) { getEvent(id: $id) { id } }', { id: 'e' });
    const auth = fake.calls[0].headers.authorization;
    assert.match(auth, /^AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE\/\d{8}\/us-east-1\/appsync\/aws4_request/, 'SigV4, scoped to appsync');
    assert.ok(!auth.includes('secret'), 'the secret key never travels');
  },
  async signerPerf(m) {
    m.appsync._setDeps({ signer: null });
    const first = m.appsync._signer();
    const t = await seconds(200_000, () => assert.strictEqual(m.appsync._signer(), first));
    assert.ok(t < 2, `one credential chain per container: ${t}s`);
  },
  async graphqlSec(m) {
    const fake = install(m, { getEvent: () => ({ errors: [{ message: 'denied', errorType: 'Unauthorized' }] }) });
    await assert.rejects(m.appsync.graphql('query { getEvent(id: "e") { id } }'),
      (e) => e instanceof m.appsync.GraphQLError && e.errorTypes[0] === 'Unauthorized', 'errors are never treated as data');
    const saved = process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT;
    delete process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT;
    const before = fake.calls.length;
    try { await assert.rejects(m.appsync.graphql('query { getEvent(id: "e") { id } }'), /not set/); }
    finally { process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT = saved; }
    assert.strictEqual(fake.calls.length, before, 'no request without a configured endpoint');
    m.appsync._setDeps({ fetch: async () => ({ ok: false, status: 503, json: async () => ({}) }) });
    await assert.rejects(m.appsync.graphql('query { getEvent(id: "e") { id } }'), /HTTP 503/, 'HTTP failures fail closed');
  },
  async graphqlPerf(m) {
    install(m, { getEvent: ({ id }) => ({ data: { getEvent: { id } } }) });
    const t = await seconds(500, (i) => m.appsync.graphql('query Q($id: ID!) { getEvent(id: $id) { id } }', { id: `e${i}` }));
    assert.ok(t < 3, `500 signed calls: ${t}s`);
  },
  async graphqlAllSec(m) {
    install(m, { listX: () => ({ data: { listX: { items: [{ id: 1 }], nextToken: 'same' } } }) });
    await assert.rejects(m.appsync.graphqlAll('query Q($nextToken: String) { listX(nextToken: $nextToken) { items { id } nextToken } }', {}, (d) => d.listX),
      /did not terminate/, 'a repeated token stops instead of looping until timeout');
  },
  async graphqlAllPerf(m) {
    let page = 0;
    install(m, { listX: ({ nextToken }) => {
      page = nextToken ? Number(nextToken) : 0;
      return { data: { listX: { items: Array.from({ length: 100 }, (_, i) => ({ id: page * 100 + i })), nextToken: page < 49 ? String(page + 1) : null } } };
    } });
    const doc = 'query Q($nextToken: String) { listX(nextToken: $nextToken) { items { id } nextToken } }';
    let items;
    const t = await seconds(1, async () => { items = await m.appsync.graphqlAll(doc, {}, (d) => d.listX); });
    assert.strictEqual(items.length, 5_000); assert.ok(t < 3, `50 pages: ${t}s`);
    let n = 0;
    install(m, { listX: () => ({ data: { listX: { items: [], nextToken: `t${n++}` } } }) });
    await assert.rejects(m.appsync.graphqlAll(doc, {}, (d) => d.listX), /did not terminate/);
    assert.strictEqual(n, m.appsync.MAX_PAGES, 'endless distinct tokens are capped');
  },
};

test('joinEvent/appsync.js:signer security — SigV4 scoped to appsync, secret never sent', () => appsyncBodies.signerSec(join));
test('joinEvent/appsync.js:signer performance — cached per container', () => appsyncBodies.signerPerf(join));
test('purchaseTicket/appsync.js:signer security — SigV4 scoped to appsync, secret never sent', () => appsyncBodies.signerSec(ticket));
test('purchaseTicket/appsync.js:signer performance — cached per container', () => appsyncBodies.signerPerf(ticket));
test('rankPromotion/appsync.js:signer security — SigV4 scoped to appsync, secret never sent', () => appsyncBodies.signerSec(rank));
test('rankPromotion/appsync.js:signer performance — cached per container', () => appsyncBodies.signerPerf(rank));
test('joinEvent/appsync.js:graphql security — errors, missing endpoint and HTTP failures fail closed', () => appsyncBodies.graphqlSec(join));
test('joinEvent/appsync.js:graphql performance — 500 signed calls', () => appsyncBodies.graphqlPerf(join));
test('purchaseTicket/appsync.js:graphql security — errors, missing endpoint and HTTP failures fail closed', () => appsyncBodies.graphqlSec(ticket));
test('purchaseTicket/appsync.js:graphql performance — 500 signed calls', () => appsyncBodies.graphqlPerf(ticket));
test('rankPromotion/appsync.js:graphql security — errors, missing endpoint and HTTP failures fail closed', () => appsyncBodies.graphqlSec(rank));
test('rankPromotion/appsync.js:graphql performance — 500 signed calls', () => appsyncBodies.graphqlPerf(rank));
test('joinEvent/appsync.js:graphqlAll security — repeated token cannot loop forever', () => appsyncBodies.graphqlAllSec(join));
test('joinEvent/appsync.js:graphqlAll performance — 50 pages, capped at MAX_PAGES', () => appsyncBodies.graphqlAllPerf(join));
test('purchaseTicket/appsync.js:graphqlAll security — repeated token cannot loop forever', () => appsyncBodies.graphqlAllSec(ticket));
test('purchaseTicket/appsync.js:graphqlAll performance — 50 pages, capped at MAX_PAGES', () => appsyncBodies.graphqlAllPerf(ticket));
test('rankPromotion/appsync.js:graphqlAll security — repeated token cannot loop forever', () => appsyncBodies.graphqlAllSec(rank));
test('rankPromotion/appsync.js:graphqlAll performance — 50 pages, capped at MAX_PAGES', () => appsyncBodies.graphqlAllPerf(rank));

// ── joinEvent/index.js ───────────────────────────────────────────────────────

const J = join.lambda;
const invite = (eventID) => JSON.stringify({ type: 'event_invite', eventID, eventName: 'N', venueName: 'V', eventDate: '2027-01-01T00:00:00Z' });
function joinWorld(o = {}) {
  const db = {
    events: { ev1: { id: 'ev1', hostDJID: 'host', status: 'pending', _deleted: null }, live: { id: 'live', hostDJID: 'host', status: 'live' }, ...(o.events || {}) },
    users: { host: { id: 'host', isDJ: true, djRank: 5 }, dj2: { id: 'dj2', isDJ: true, djRank: 3 }, fan: { id: 'fan', isDJ: false }, ...(o.users || {}) },
    links: o.links || [], messages: o.messages || [],
    rooms: { r1: { id: 'r1', name: J._dmRoomName('host', 'dj2') }, rX: { id: 'rX', name: 'dm-host-zzz' } },
  };
  const fake = install(join, {
    getEvent: ({ id }) => ({ data: { getEvent: db.events[id] || null } }),
    getUser: ({ id }) => ({ data: { getUser: db.users[id] || null } }),
    getEventDJLink: ({ id }) => ({ data: { getEventDJLink: db.links.find((l) => l.id === id) || null } }),
    eventDJLinksByDjIDAndCreatedAt: ({ djID, eventID }) => ({ data: { eventDJLinksByDjIDAndCreatedAt: {
      items: db.links.filter((l) => l.djID === djID && (o.ignoreEventFilter || l.eventID === eventID)), nextToken: null } } }),
    messagesBySenderIDAndTimestamp: ({ senderID, eventID }) => ({ data: { messagesBySenderIDAndTimestamp: {
      items: db.messages.filter((m) => (o.ignoreSenderKey || m.senderID === senderID) && m.content.includes(eventID)), nextToken: null } } }),
    getChatRoom: ({ id }) => ({ data: { getChatRoom: db.rooms[id] || null } }),
    createEventDJLink: ({ input }) => {
      if (db.links.some((l) => l.id === input.id)) return condFail;
      const link = { ...input, _deleted: null, _version: 1 }; db.links.push(link);
      return { data: { createEventDJLink: link } };
    },
  }, db);
  return { db, fake };
}

test('joinEvent/index.js:coinsForRank security — bounded weights for any input', () => {
  for (const r of [NaN, undefined, null, -1, 0, 1, 1.9]) assert.strictEqual(J._coinsForRank(r), 0, String(r));
  assert.strictEqual(J._coinsForRank(3.9), 7, 'fractions floor, never round up');
  for (const r of [5, 6, 99, Infinity]) assert.strictEqual(J._coinsForRank(r), 25, 'never more than rank 5 weight');
});
test('joinEvent/index.js:coinsForRank performance — 1M lookups', async () => {
  const t = await seconds(1_000_000, (i) => J._coinsForRank(i % 6));
  assert.ok(t < 2, `${t}s`);
});

test('joinEvent/index.js:byCodePoint security — orders by code point like Swift, not UTF-16 units', () => {
  assert.ok(J._byCodePoint('\u{1F600}', '￿') > 0, 'astral chars sort after BMP (JS default sort gets this wrong)');
  assert.strictEqual(J._byCodePoint('abc', 'abc'), 0);
  assert.ok(J._byCodePoint('ab', 'abc') < 0);
});
test('joinEvent/index.js:byCodePoint performance — 100k comparisons of UUIDs', async () => {
  const a = '5f2c3a1e-8b4d-4e1a-9c7f-1a2b3c4d5e6f'; const b = '5f2c3a1e-8b4d-4e1a-9c7f-1a2b3c4d5e70';
  const t = await seconds(100_000, () => J._byCodePoint(a, b));
  assert.ok(t < 2, `${t}s`);
});

test('joinEvent/index.js:dmRoomName security — symmetric, so no one can claim a different room', () => {
  assert.strictEqual(J._dmRoomName('host', 'dj2'), J._dmRoomName('dj2', 'host'));
  assert.notStrictEqual(J._dmRoomName('host', 'dj2'), J._dmRoomName('host', 'dj3'));
});
test('joinEvent/index.js:dmRoomName performance — 100k names', async () => {
  const t = await seconds(100_000, () => J._dmRoomName('5f2c3a1e-8b4d-4e1a', '0c2d3a1e-8b4d-4e1a'));
  assert.ok(t < 2, `${t}s`);
});

test('joinEvent/index.js:linkID security — collision-prone ids are refused before a link id is derived', async () => {
  assert.strictEqual(J._linkID('a_b', 'c'), J._linkID('a', 'b_c'), 'raw concatenation can collide…');
  joinWorld();
  const r = await J.handler(req('c', { eventID: 'a_b' }));
  assert.strictEqual(r.statusCode, 400, '…so event ids with "_" never reach it');
});
test('joinEvent/index.js:linkID performance — 1M ids', async () => {
  const t = await seconds(1_000_000, () => J._linkID('ev1', 'dj2'));
  assert.ok(t < 2, `${t}s`);
});

test('joinEvent/index.js:resolveLink security — tombstones yield a deterministic successor, capped', async () => {
  joinWorld({ links: [{ id: 'ev1_dj2', eventID: 'ev1', djID: 'dj2', _deleted: true, _lastChangedAt: 111 }] });
  assert.deepStrictEqual(await J._resolveLink('ev1', 'dj2'), { id: 'ev1_dj2_111', live: null });
  const chain = Array.from({ length: 10 }, (_, i) => ({ id: i === 0 ? 'ev1_dj2' : `ev1_dj2_${i}`, _deleted: true, _lastChangedAt: i + 1 }));
  joinWorld({ links: chain });
  await assert.rejects(J._resolveLink('ev1', 'dj2'), /too many rejoins/, 'a rejoin loop cannot run forever');
});
test('joinEvent/index.js:resolveLink performance — 9 rejoins resolved 100 times', async () => {
  const chain = Array.from({ length: 9 }, (_, i) => ({ id: i === 0 ? 'ev1_dj2' : `ev1_dj2_${i}`, _deleted: true, _lastChangedAt: i + 1 }));
  joinWorld({ links: chain });
  const t = await seconds(100, () => J._resolveLink('ev1', 'dj2'));
  assert.ok(t < 3, `${t}s`);
});

test('joinEvent/index.js:existingLink security — ignores deleted links and other events', async () => {
  joinWorld({ ignoreEventFilter: true, links: [
    { id: 'rand1', eventID: 'other', djID: 'dj2', _deleted: null },
    { id: 'rand2', eventID: 'ev1', djID: 'dj2', _deleted: true },
  ] });
  assert.strictEqual(await J._existingLink('ev1', 'dj2'), null);
});
test('joinEvent/index.js:existingLink performance — 1,000 admin-made links for one DJ', async () => {
  joinWorld({ ignoreEventFilter: true, links: Array.from({ length: 1_000 }, (_, i) => ({ id: `r${i}`, eventID: `e${i}`, djID: 'dj2', _deleted: null })) });
  const t = await seconds(20, () => J._existingLink('ev1', 'dj2'));
  assert.ok(t < 3, `${t}s`);
});

test('joinEvent/index.js:hasInvite security — only a host invite, for this event, in this DM room', async () => {
  const cases = [
    { senderID: 'host', chatRoomID: 'rX', content: invite('ev1') },                 // wrong room
    { senderID: 'dj2', chatRoomID: 'r1', content: invite('ev1') },                   // self-invite
    { senderID: 'host', chatRoomID: 'r1', content: invite('ev2') + ' ev1' },          // other event
    { senderID: 'host', chatRoomID: 'r1', content: invite('ev1'), _deleted: true },   // deleted
    { senderID: 'host', chatRoomID: 'r1', content: JSON.stringify({ type: 'event_invite', eventID: 'ev1', pad: 'x'.repeat(5000) }) }, // oversized
  ];
  for (const m of cases) {
    joinWorld({ ignoreSenderKey: true, messages: [{ id: 'm', ...m }] });
    assert.strictEqual(await J._hasInvite('host', 'dj2', 'ev1'), false, JSON.stringify(m).slice(0, 60));
  }
  joinWorld({ messages: [{ id: 'm', senderID: 'host', chatRoomID: 'r1', content: invite('ev1') }] });
  assert.strictEqual(await J._hasInvite('host', 'dj2', 'ev1'), true);
});
test('joinEvent/index.js:hasInvite performance — 1,000 non-invite messages, no room lookups', async () => {
  const { fake } = joinWorld({ messages: Array.from({ length: 1_000 }, (_, i) => ({ id: `m${i}`, senderID: 'host', chatRoomID: 'r1', content: `chat about ev1 #${i}` })) });
  const t = await seconds(5, () => J._hasInvite('host', 'dj2', 'ev1'));
  assert.ok(t < 3, `${t}s`);
  assert.strictEqual(fake.calls.filter((c) => c.field === 'getChatRoom').length, 0);
});

test('joinEvent/index.js:join security — fans, closed events and uninvited DJs are refused', async () => {
  joinWorld();
  assert.strictEqual(body(await J._join('fan', 'ev1')).errorCode, 'NOT_A_DJ');
  assert.strictEqual(body(await J._join('host', 'live')).errorCode, 'EVENT_NOT_OPEN');
  assert.strictEqual(body(await J._join('dj2', 'ev1')).errorCode, 'NOT_INVITED');
  assert.strictEqual(body(await J._join('host', 'missing')).errorCode, 'EVENT_NOT_FOUND');
});
test('joinEvent/index.js:join performance — 200 idempotent re-joins', async () => {
  const { db } = joinWorld();
  await J._join('host', 'ev1');
  const t = await seconds(200, () => J._join('host', 'ev1'));
  assert.ok(t < 3, `${t}s`); assert.strictEqual(db.links.length, 1);
});

test('joinEvent/index.js:handler security — method, identity and input are checked first', async () => {
  const { db } = joinWorld();
  assert.strictEqual((await J.handler(req('host', { eventID: 'ev1' }, 'GET'))).statusCode, 405);
  assert.strictEqual((await J.handler(req(null, { eventID: 'ev1' }))).statusCode, 401);
  for (const bad of [{}, { eventID: '' }, { eventID: { $ne: 1 } }, { eventID: '../ev1' }]) {
    assert.strictEqual((await J.handler(req('host', bad))).statusCode, 400, JSON.stringify(bad));
  }
  const r = await J.handler(req('dj2', { eventID: 'ev1', userID: 'host', djID: 'host' }));
  assert.strictEqual(body(r).errorCode, 'NOT_INVITED', 'body-supplied identities are ignored');
  assert.strictEqual(db.links.length, 0);
});
test('joinEvent/index.js:handler performance — oversized bodies rejected without AppSync calls', async () => {
  const { fake } = joinWorld();
  const big = req('host', JSON.stringify({ eventID: 'ev1', pad: 'x'.repeat(5 * 1024 * 1024) }));
  const t = await seconds(20, () => J.handler(big));
  assert.ok(t < 2, `${t}s`); assert.strictEqual(fake.calls.length, 0);
});

// ── purchaseTicket/index.js ──────────────────────────────────────────────────

const future = new Date(Date.now() + 86400e3).toISOString();
function ticketWorld(o = {}) {
  const db = {
    event: { id: 'ev1', venueID: 'v1', status: 'live', eventDate: future, ticketPrice: 0, availableTickets: 5, _version: 3, _deleted: null, ...(o.event || {}) },
    venue: o.venue === undefined ? { id: 'v1', maxCapacity: 150, _deleted: null } : o.venue,
    links: o.links || [], tickets: o.tickets || [], allowances: o.allowances || {},
  };
  let automerge = o.automerge || 0;
  const fake = install(ticket, {
    getEvent: () => ({ data: { getEvent: db.event } }),
    getVenue: () => ({ data: { getVenue: db.venue } }),
    eventDJLinksByEventIDAndCreatedAt: ({ nextToken }) => {
      const page = nextToken ? Number(nextToken) : 0; const items = db.links.slice(page * 100, page * 100 + 100);
      return { data: { eventDJLinksByEventIDAndCreatedAt: { items, nextToken: (page + 1) * 100 < db.links.length ? String(page + 1) : null } } };
    },
    ticketsByUserIDAndPurchaseTime: ({ userID, eventID }) => ({ data: { ticketsByUserIDAndPurchaseTime: {
      items: db.tickets.filter((t) => (o.ignoreUserKey || t.userID === userID) && t.eventID === eventID), nextToken: null } } }),
    getTicketAllowance: ({ id }) => ({ data: { getTicketAllowance: db.allowances[id] ? { ...db.allowances[id] } : null } }),
    createTicketAllowance: ({ input }) => {
      if (db.allowances[input.id]) return condFail;
      db.allowances[input.id] = { ...input, _version: 1, _deleted: null };
      return { data: { createTicketAllowance: db.allowances[input.id] } };
    },
    updateTicketAllowance: ({ input, condition }) => {
      const row = db.allowances[input.id];
      if (!row || row._version !== input._version) return { errors: [{ message: 'c', errorType: 'ConflictUnhandled' }] };
      if (condition && row.issued !== condition.issued.eq) return condFail;
      db.allowances[input.id] = { ...row, issued: input.issued, _version: row._version + 1 };
      return { data: { updateTicketAllowance: db.allowances[input.id] } };
    },
    updateEvent: ({ input, condition }) => {
      if (automerge > 0) { automerge -= 1; db.event = { ...db.event, _version: db.event._version + 1 }; return { data: { updateEvent: db.event } }; }
      if (db.event.availableTickets !== condition.availableTickets.eq) return condFail;
      db.event = { ...db.event, availableTickets: input.availableTickets, _version: db.event._version + 1 };
      return { data: { updateEvent: db.event } };
    },
    createTicket: ({ input }) => {
      if (o.createError) return { errors: [o.createError] };
      const t = { id: `t${db.tickets.length + 1}`, ...input, _version: 1 }; db.tickets.push(t);
      return { data: { createTicket: t } };
    },
  }, db);
  return { db, fake };
}

test('purchaseTicket/index.js:tallyEnforced security — only the exact string "true" enables it', () => {
  const saved = process.env.TALLY_ENFORCED;
  try {
    for (const v of ['TRUE', '1', 'yes', ' true', '']) { process.env.TALLY_ENFORCED = v; assert.strictEqual(T.tallyEnforced(), false, v); }
    process.env.TALLY_ENFORCED = 'true'; assert.strictEqual(T.tallyEnforced(), true);
  } finally { if (saved === undefined) delete process.env.TALLY_ENFORCED; else process.env.TALLY_ENFORCED = saved; }
});
test('purchaseTicket/index.js:tallyEnforced performance — 1M reads', async () => {
  const t = await seconds(1_000_000, () => T.tallyEnforced());
  assert.ok(t < 2, `${t}s`);
});

test('purchaseTicket/index.js:requiredTally security — bad prices cannot shrink the bar', () => {
  for (const p of [NaN, -10, 0, undefined]) assert.strictEqual(ticket.lambda._requiredTally(150, p), 40, String(p));
  assert.ok(ticket.lambda._requiredTally(150, 1e9) >= 20, 'expensive tickets halve the bar at most');
  assert.ok(ticket.lambda._requiredTally(-5, 1) >= 10);
  assert.strictEqual(ticket.lambda._requiredTally(Infinity, 0), 80);
});
test('purchaseTicket/index.js:requiredTally performance — 1M computations', async () => {
  const t = await seconds(1_000_000, (i) => ticket.lambda._requiredTally(100 + (i % 900), i % 80));
  assert.ok(t < 2, `${t}s`);
});

test('purchaseTicket/index.js:tallyMet security — deleted venue or links never count', async () => {
  ticketWorld({ venue: { id: 'v1', maxCapacity: 150, _deleted: true }, links: [{ coinContribution: 999, _deleted: null }] });
  assert.strictEqual((await T.tallyMet({ id: 'ev1', venueID: 'v1', ticketPrice: 0 })).met, false);
  ticketWorld({ links: [{ coinContribution: 999, _deleted: true }, { coinContribution: 25, _deleted: null }] });
  assert.deepStrictEqual(await T.tallyMet({ id: 'ev1', venueID: 'v1', ticketPrice: 0 }), { met: false, current: 25, required: 40 });
});
test('purchaseTicket/index.js:tallyMet performance — 2,000 links over 20 pages', async () => {
  ticketWorld({ links: Array.from({ length: 2_000 }, () => ({ coinContribution: 5, _deleted: null })) });
  let r; const t = await seconds(1, async () => { r = await T.tallyMet({ id: 'ev1', venueID: 'v1', ticketPrice: 0 }); });
  assert.strictEqual(r.current, 10_000); assert.ok(t < 3, `${t}s`);
});

test('purchaseTicket/index.js:isConditionFailure security — only AppSync condition errors count', () => {
  const e = new Error('ConditionalCheckFailed'); e.errorTypes = ['DynamoDB:ConditionalCheckFailedException'];
  assert.strictEqual(T.isConditionFailure(e), false, 'a look-alike plain Error is not retried');
  assert.strictEqual(T.isConditionFailure(new (require(`${FN}/purchaseTicket/src/appsync.js`).GraphQLError)([{ message: 'x', errorType: 'Unauthorized' }])), false);
  assert.strictEqual(T.isConditionFailure(new ticket.appsync.GraphQLError([{ message: 'x', errorType: 'ConflictUnhandled' }])), true);
});
test('purchaseTicket/index.js:isConditionFailure performance — 500k checks', async () => {
  const e = new ticket.appsync.GraphQLError([{ message: 'x', errorType: 'DynamoDB:ConditionalCheckFailedException' }]);
  const t = await seconds(500_000, () => T.isConditionFailure(e));
  assert.ok(t < 2, `${t}s`);
});

test('purchaseTicket/index.js:getEvent security — deleted events are not found', async () => {
  ticketWorld({ event: { _deleted: true } });
  assert.strictEqual(await T.getEvent('ev1'), null);
});
test('purchaseTicket/index.js:getEvent performance — 500 reads', async () => {
  ticketWorld();
  const t = await seconds(500, () => T.getEvent('ev1'));
  assert.ok(t < 3, `${t}s`);
});

test('purchaseTicket/index.js:applied security — an AUTOMERGE success with a stale version is not applied', () => {
  assert.strictEqual(T.applied({ availableTickets: 4, _version: 5 }, 'availableTickets', 4, 3), false);
  assert.strictEqual(T.applied({ availableTickets: 5, _version: 4 }, 'availableTickets', 4, 3), false);
  assert.strictEqual(T.applied(null, 'availableTickets', 4, 3), false);
  assert.strictEqual(T.applied({ availableTickets: 4, _version: 4 }, 'availableTickets', 4, 3), true);
});
test('purchaseTicket/index.js:applied performance — 1M checks', async () => {
  const row = { availableTickets: 4, _version: 4 };
  const t = await seconds(1_000_000, () => T.applied(row, 'availableTickets', 4, 3));
  assert.ok(t < 2, `${t}s`);
});

test('purchaseTicket/index.js:adjustStock security — never below zero; merged writes are retried', async () => {
  const { db } = ticketWorld({ event: { availableTickets: 1 } });
  assert.strictEqual(await T.adjustStock('ev1', -2), null, 'oversell refused');
  assert.strictEqual(db.event.availableTickets, 1);
  const w = ticketWorld({ automerge: 2 });
  assert.strictEqual(await T.adjustStock('ev1', -1), 4);
  assert.strictEqual(w.db.event.availableTickets, 4, 'a merged (ignored) write is not mistaken for success');
});
test('purchaseTicket/index.js:adjustStock performance — 200 sequential decrements', async () => {
  const { db } = ticketWorld({ event: { availableTickets: 200 } });
  const t = await seconds(200, () => T.adjustStock('ev1', -1));
  assert.ok(t < 3, `${t}s`); assert.strictEqual(db.event.availableTickets, 0);
});

test('purchaseTicket/index.js:allowanceID security — one row per (event, buyer)', () => {
  assert.notStrictEqual(T.allowanceID('ev1', 'a'), T.allowanceID('ev1', 'b'));
  assert.notStrictEqual(T.allowanceID('ev1', 'a'), T.allowanceID('ev2', 'a'));
  assert.ok(!ticket.http.isValidID('ev1_a'), 'ids that could forge another row are refused at the handler');
});
test('purchaseTicket/index.js:allowanceID performance — 1M ids', async () => {
  const t = await seconds(1_000_000, () => T.allowanceID('ev1', 'sub'));
  assert.ok(t < 2, `${t}s`);
});

test('purchaseTicket/index.js:heldFromTickets security — only my live tickets for this event', async () => {
  ticketWorld({ tickets: [
    { userID: 'me', eventID: 'ev1', quantity: 2, _deleted: null },
    { userID: 'me', eventID: 'ev1', quantity: 5, _deleted: true },
    { userID: 'me', eventID: 'ev2', quantity: 5, _deleted: null },
    { userID: 'other', eventID: 'ev1', quantity: 5, _deleted: null },
  ] });
  assert.strictEqual(await T.heldFromTickets('me', 'ev1'), 2);
});
test('purchaseTicket/index.js:heldFromTickets performance — 1,000 tickets summed', async () => {
  ticketWorld({ tickets: Array.from({ length: 1_000 }, () => ({ userID: 'me', eventID: 'ev1', quantity: 1, _deleted: null })) });
  let n; const t = await seconds(5, async () => { n = await T.heldFromTickets('me', 'ev1'); });
  assert.strictEqual(n, 1_000); assert.ok(t < 3, `${t}s`);
});

test('purchaseTicket/index.js:reserveAllowance security — the per-buyer cap holds', async () => {
  const { db } = ticketWorld();
  assert.deepStrictEqual(await T.reserveAllowance('me', 'ev1', 10), { reserved: true });
  assert.deepStrictEqual(await T.reserveAllowance('me', 'ev1', 1), { reserved: false, held: 10 });
  assert.strictEqual(db.allowances.ev1_me.issued, 10);
  ticketWorld({ allowances: { ev1_me: { id: 'ev1_me', issued: 0, _version: 1, _deleted: true } } });
  await assert.rejects(T.reserveAllowance('me', 'ev1', 1), /deleted/, 'a deleted allowance fails closed, not reset to 0');
});
test('purchaseTicket/index.js:reserveAllowance performance — 10 reservations for 100 buyers', async () => {
  ticketWorld();
  const t = await seconds(100, (i) => T.reserveAllowance(`b${i}`, 'ev1', 1));
  assert.ok(t < 3, `${t}s`);
});

test('purchaseTicket/index.js:releaseAllowance security — never negative; missing rows untouched', async () => {
  const { db } = ticketWorld({ allowances: { ev1_me: { id: 'ev1_me', issued: 1, _version: 1, _deleted: null } } });
  await T.releaseAllowance('me', 'ev1', 5);
  assert.strictEqual(db.allowances.ev1_me.issued, 0);
  await T.releaseAllowance('ghost', 'ev1', 5);
  assert.strictEqual(db.allowances.ev1_ghost, undefined, 'releasing never creates rows');
});
test('purchaseTicket/index.js:releaseAllowance performance — 200 releases', async () => {
  ticketWorld({ allowances: { ev1_me: { id: 'ev1_me', issued: 200, _version: 1, _deleted: null } } });
  const t = await seconds(200, () => T.releaseAllowance('me', 'ev1', 1));
  assert.ok(t < 3, `${t}s`);
});

test('purchaseTicket/index.js:releaseQuietly security — a failed release never masks the original error', async () => {
  install(ticket, { getTicketAllowance: () => ({ errors: [{ message: 'down', errorType: 'Internal' }] }) });
  const { lines } = await quiet(() => T.releaseQuietly('me', 'ev1', 1));
  assert.ok(lines.some((l) => l.includes('ALLOWANCE NOT RELEASED')), 'the drift is logged for an operator');
});
test('purchaseTicket/index.js:releaseQuietly performance — 200 quiet releases', async () => {
  ticketWorld({ allowances: { ev1_me: { id: 'ev1_me', issued: 200, _version: 1, _deleted: null } } });
  const t = await seconds(200, () => T.releaseQuietly('me', 'ev1', 1));
  assert.ok(t < 3, `${t}s`);
});

test('purchaseTicket/index.js:purchase security — paid, ended, unlisted and over-cap purchases refused', async () => {
  ticketWorld({ event: { ticketPrice: 20 } });
  assert.strictEqual(body(await T.purchase('me', 'ev1', 1)).errorCode, 'PAYMENT_REQUIRED');
  ticketWorld({ event: { eventDate: new Date(Date.now() - 1000).toISOString() } });
  assert.strictEqual(body(await T.purchase('me', 'ev1', 1)).errorCode, 'EVENT_ENDED');
  ticketWorld({ event: { status: 'pending' } });
  assert.strictEqual(body(await T.purchase('me', 'ev1', 1)).errorCode, 'EVENT_NOT_ON_SALE');
  const { db } = ticketWorld({ event: { availableTickets: 50 }, allowances: { ev1_me: { id: 'ev1_me', issued: 9, _version: 1, _deleted: null } } });
  assert.strictEqual(body(await T.purchase('me', 'ev1', 2)).errorCode, 'LIMIT_REACHED');
  assert.strictEqual(db.event.availableTickets, 50, 'no stock taken on refusal');
});
test('purchaseTicket/index.js:purchase performance — 100 buyers sell out a 100-ticket event', async () => {
  const { db } = ticketWorld({ event: { availableTickets: 100 } });
  const t = await seconds(100, (i) => T.purchase(`b${i}`, 'ev1', 1));
  assert.ok(t < 4, `${t}s`);
  assert.strictEqual(db.event.availableTickets, 0); assert.strictEqual(db.tickets.length, 100);
});

test('purchaseTicket/index.js:handler security — quantity and identity validated before any read', async () => {
  const { fake } = ticketWorld();
  for (const q of [0, 11, 1.5, '2', -1, null]) {
    assert.strictEqual((await ticket.lambda.handler(req('me', { eventID: 'ev1', quantity: q }))).statusCode, 400, String(q));
  }
  assert.strictEqual((await ticket.lambda.handler(req(null, { eventID: 'ev1' }))).statusCode, 401);
  assert.strictEqual((await ticket.lambda.handler(req('me', { eventID: 'ev1_x' }))).statusCode, 400);
  assert.strictEqual(fake.calls.length, 0);
  const r = await ticket.lambda.handler(req('me', { eventID: 'ev1', userID: 'victim', pricePaid: -5 }));
  assert.strictEqual(r.statusCode, 200);
});
test('purchaseTicket/index.js:handler performance — 10 MB bodies refused without AppSync calls', async () => {
  const { fake } = ticketWorld();
  const big = req('me', JSON.stringify({ eventID: 'ev1', pad: 'x'.repeat(10 * 1024 * 1024) }));
  const t = await seconds(20, () => ticket.lambda.handler(big));
  assert.ok(t < 2, `${t}s`); assert.strictEqual(fake.calls.length, 0);
});

// ── rankPromotion/index.js ───────────────────────────────────────────────────

function rankWorld({ users, endorsements = [], links = [] }) {
  const db = { users: structuredClone(users), endorsements: structuredClone(endorsements), links };
  const fake = install(rank, {
    getUser: ({ id }) => ({ data: { getUser: db.users[id] || null } }),
    endorsementRequestsByFromUserIDAndTimestamp: ({ fromUserID, targetRank }) => ({ data: { endorsementRequestsByFromUserIDAndTimestamp: {
      items: db.endorsements.filter((e) => e.fromUserID === fromUserID && e.targetRank === targetRank && e.status === 'approved'), nextToken: null } } }),
    eventDJLinksByDjIDAndCreatedAt: ({ djID }) => ({ data: { eventDJLinksByDjIDAndCreatedAt: { items: db.links.filter((l) => l.djID === djID), nextToken: null } } }),
    getEndorsementRequest: ({ id }) => ({ data: { getEndorsementRequest: db.endorsements.find((e) => e.id === id) || null } }),
    updateEndorsementRequest: ({ input }) => {
      const e = db.endorsements.find((x) => x.id === input.id); Object.assign(e, { status: input.status, _version: e._version + 1 });
      return { data: { updateEndorsementRequest: e } };
    },
    updateUser: ({ input }) => {
      const u = db.users[input.id];
      if (input._version !== u._version) return condFail;
      db.users[input.id] = { ...u, djRank: input.djRank, _version: u._version + 1 };
      return { data: { updateUser: db.users[input.id] } };
    },
  }, db);
  return { db, fake };
}
const dj = (id, r) => ({ id, isDJ: true, djRank: r, _version: 1, _deleted: null });
const approval = (to, r = 2, from = 'cand') => ({ id: `e-${from}-${to}-${r}`, fromUserID: from, toUserID: to, targetRank: r, status: 'approved',
  createdAt: '2026-10-01T00:00:00Z', updatedAt: '2026-10-02T00:00:00Z', _version: 2, _deleted: null });
const L = (djID, eventID) => ({ djID, eventID, _deleted: null });
const img = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, typeof v === 'number' ? { N: String(v) } : typeof v === 'boolean' ? { BOOL: v } : { S: v }]));
const modify = (n, o) => ({ eventName: 'MODIFY', dynamodb: { NewImage: img(n), OldImage: img(o) } });
const base = { id: 'e1', fromUserID: 'cand', toUserID: 'a', targetRank: 2 };

test('rankPromotion/index.js:requiredEndorsements security — senior ranks need three', () => {
  assert.strictEqual(rank.lambda._requiredEndorsements(2), 2);
  for (const r of [4, 5, 99, Infinity]) assert.strictEqual(rank.lambda._requiredEndorsements(r), 3);
});
test('rankPromotion/index.js:requiredEndorsements performance — 1M lookups', async () => {
  const t = await seconds(1_000_000, (i) => rank.lambda._requiredEndorsements(i % 6));
  assert.ok(t < 2, `${t}s`);
});

test('rankPromotion/index.js:attr security — unknown or hostile attribute shapes read as undefined', () => {
  assert.strictEqual(R.attr({ x: { M: { S: 'nested' } } }, 'x'), undefined);
  assert.strictEqual(R.attr({}, '__proto__'), undefined, 'prototype keys are not attributes');
  assert.strictEqual(R.attr({ x: { NULL: true } }, 'x'), null);
  assert.strictEqual(R.attr(undefined, 'x'), undefined);
  assert.ok(Number.isNaN(R.attr({ x: { N: 'abc' } }, 'x')), 'malformed numbers fail Number.isInteger later');
});
test('rankPromotion/index.js:attr performance — 1M reads', async () => {
  const image = img(base);
  const t = await seconds(1_000_000, () => R.attr(image, 'targetRank'));
  assert.ok(t < 2, `${t}s`);
});

test('rankPromotion/index.js:identityChanged security — re-pointing who or what is endorsed is caught', () => {
  assert.strictEqual(R.identityChanged(img({ ...base, toUserID: 'b' }), img(base)), true);
  assert.strictEqual(R.identityChanged(img({ ...base, targetRank: 3 }), img(base)), true);
  assert.strictEqual(R.identityChanged(img({ ...base, status: 'approved' }), img(base)), false);
});
test('rankPromotion/index.js:identityChanged performance — 500k comparisons', async () => {
  const a = img(base); const b = img(base);
  const t = await seconds(500_000, () => R.identityChanged(a, b));
  assert.ok(t < 2, `${t}s`);
});

test('rankPromotion/index.js:approvalsFromStream security — only genuine pending→approved updates', () => {
  const ev = { Records: [
    { eventName: 'INSERT', dynamodb: { NewImage: img({ ...base, status: 'approved' }) } },
    modify({ ...base, status: 'approved', toUserID: 'b' }, { ...base, status: 'pending' }),
    modify({ ...base, status: 'approved', _deleted: true }, { ...base, status: 'pending' }),
    modify({ ...base, status: 'approved', targetRank: 2.5 }, { ...base, status: 'pending', targetRank: 2.5 }),
  ] };
  assert.deepStrictEqual(rank.lambda._approvalsFromStream(ev), []);
});
test('rankPromotion/index.js:approvalsFromStream performance — 10k records deduplicated', async () => {
  const rec = modify({ ...base, status: 'approved' }, { ...base, status: 'pending' });
  const ev = { Records: Array.from({ length: 10_000 }, () => rec) };
  let out; const t = await seconds(5, () => { out = rank.lambda._approvalsFromStream(ev); });
  assert.strictEqual(out.length, 1); assert.ok(t < 2, `${t}s`);
});

test('rankPromotion/index.js:suspectsFromStream security — pre-approved inserts and re-pointed approvals flagged', () => {
  const s = rank.lambda._suspectsFromStream({ Records: [
    { eventName: 'INSERT', dynamodb: { NewImage: img({ ...base, id: 'forged', status: 'approved' }) } },
    modify({ ...base, id: 'moved', status: 'approved', toUserID: 'b' }, { ...base, status: 'pending' }),
    modify({ ...base, id: 'fine', status: 'approved' }, { ...base, status: 'pending' }),
  ] });
  assert.deepStrictEqual(s.map((x) => [x.id, x.resetTo]), [['forged', 'pending'], ['moved', 'rejected']]);
});
test('rankPromotion/index.js:suspectsFromStream performance — 10k records', async () => {
  const ev = { Records: Array.from({ length: 10_000 }, (_, i) => ({ eventName: 'INSERT', dynamodb: { NewImage: img({ ...base, id: `f${i % 100}`, status: 'approved' }) } })) };
  let out; const t = await seconds(5, () => { out = rank.lambda._suspectsFromStream(ev); });
  assert.strictEqual(out.length, 100); assert.ok(t < 2, `${t}s`);
});

test('rankPromotion/index.js:getUser security — deleted users are not found', async () => {
  rankWorld({ users: { gone: { ...dj('gone', 4), _deleted: true } } });
  assert.strictEqual(await R.getUser('gone'), null);
  assert.strictEqual(await R.getUser('missing'), null);
});
test('rankPromotion/index.js:getUser performance — 500 reads', async () => {
  rankWorld({ users: { a: dj('a', 3) } });
  const t = await seconds(500, () => R.getUser('a'));
  assert.ok(t < 3, `${t}s`);
});

test('rankPromotion/index.js:approvedByUpdate security — created-approved records never count', () => {
  assert.strictEqual(R.approvedByUpdate({ createdAt: 'x', updatedAt: 'x' }), false);
  assert.strictEqual(R.approvedByUpdate({ createdAt: 'x' }), false);
  assert.strictEqual(R.approvedByUpdate({ createdAt: 1, updatedAt: 2 }), false, 'non-string timestamps refused');
  assert.strictEqual(R.approvedByUpdate({ createdAt: 'x', updatedAt: 'y' }), true);
});
test('rankPromotion/index.js:approvedByUpdate performance — 1M checks', async () => {
  const r = { createdAt: 'a', updatedAt: 'b' };
  const t = await seconds(1_000_000, () => R.approvedByUpdate(r));
  assert.ok(t < 2, `${t}s`);
});

test('rankPromotion/index.js:neutralize security — only still-approved records are reset', async () => {
  const { db } = rankWorld({ users: {}, endorsements: [{ ...approval('a'), id: 'x', status: 'pending' }, { ...approval('b'), id: 'y' }] });
  assert.deepStrictEqual(await R.neutralize({ id: 'x', resetTo: 'rejected' }), { neutralized: false });
  assert.strictEqual(db.endorsements[0].status, 'pending', 'a record the recipient already handled is left alone');
  assert.deepStrictEqual(await R.neutralize({ id: 'y', resetTo: 'rejected' }), { neutralized: true });
  assert.strictEqual(db.endorsements[1].status, 'rejected');
});
test('rankPromotion/index.js:neutralize performance — 200 resets', async () => {
  rankWorld({ users: {}, endorsements: Array.from({ length: 200 }, (_, i) => ({ ...approval(`u${i}`), id: `s${i}` })) });
  const t = await seconds(200, (i) => R.neutralize({ id: `s${i}`, resetTo: 'pending' }));
  assert.ok(t < 3, `${t}s`);
});

test('rankPromotion/index.js:eventIDsFor security — deleted links do not prove a shared event', async () => {
  rankWorld({ users: {}, links: [L('a', 'e1'), { ...L('a', 'e2'), _deleted: true }, L('b', 'e3')] });
  assert.deepStrictEqual([...(await R.eventIDsFor('a'))], ['e1']);
});
test('rankPromotion/index.js:eventIDsFor performance — 2,000 links', async () => {
  rankWorld({ users: {}, links: Array.from({ length: 2_000 }, (_, i) => L('a', `e${i % 500}`)) });
  let s; const t = await seconds(5, async () => { s = await R.eventIDsFor('a'); });
  assert.strictEqual(s.size, 500); assert.ok(t < 3, `${t}s`);
});

test('rankPromotion/index.js:countValidEndorsers security — self, junior, stranger and suspect endorsements do not count', async () => {
  rankWorld({
    users: { cand: dj('cand', 1), self: dj('cand', 1), junior: dj('junior', 1), stranger: dj('stranger', 5), sus: dj('sus', 5), fan: { ...dj('fan', 5), isDJ: false }, good: dj('good', 3) },
    endorsements: [approval('cand'), approval('junior'), approval('stranger'), { ...approval('sus'), id: 'suspect' }, approval('fan'), approval('good')],
    links: [L('cand', 'ev'), L('junior', 'ev'), L('sus', 'ev'), L('fan', 'ev'), L('good', 'ev'), L('stranger', 'elsewhere')],
  });
  const { count, rejected } = await R.countValidEndorsers('cand', 2, new Set(['suspect']));
  assert.strictEqual(count, 1, 'only "good" counts');
  assert.ok(rejected.length >= 4);
});
test('rankPromotion/index.js:countValidEndorsers performance — 100 endorsers', async () => {
  const users = { cand: dj('cand', 1) }; const endorsements = []; const links = [L('cand', 'ev')];
  for (let i = 0; i < 100; i += 1) { users[`u${i}`] = dj(`u${i}`, 3); endorsements.push(approval(`u${i}`)); links.push(L(`u${i}`, 'ev')); }
  rankWorld({ users, endorsements, links });
  let r; const t = await seconds(1, async () => { r = await R.countValidEndorsers('cand', 2); });
  assert.strictEqual(r.count, 100); assert.ok(t < 4, `${t}s`);
});

test('rankPromotion/index.js:evaluate security — no skipping ranks, no out-of-range targets', async () => {
  rankWorld({ users: { cand: dj('cand', 1), a: dj('a', 5), b: dj('b', 5) }, endorsements: [approval('a', 3), approval('b', 3)], links: [L('cand', 'e'), L('a', 'e'), L('b', 'e')] });
  for (const t of [0, 6, -1]) assert.strictEqual((await rank.lambda._evaluate({ candidateID: 'cand', targetRank: t })).reason, 'target out of range');
  const skip = await rank.lambda._evaluate({ candidateID: 'cand', targetRank: 3 });
  assert.strictEqual(skip.promoted, false, 'rank 1 → 3 is refused even with valid rank-3 endorsements');
});
test('rankPromotion/index.js:evaluate performance — 100 evaluations', async () => {
  const t = await seconds(100, async () => {
    rankWorld({ users: { cand: dj('cand', 1), a: dj('a', 5), b: dj('b', 5) }, endorsements: [approval('a'), approval('b')], links: [L('cand', 'e'), L('a', 'e'), L('b', 'e')] });
    assert.strictEqual((await rank.lambda._evaluate({ candidateID: 'cand', targetRank: 2 }, new Set(), dj('cand', 1))).promoted, true);
  });
  assert.ok(t < 3, `${t}s`);
});

test('rankPromotion/index.js:climb security — never passes rank 5', async () => {
  const users = { cand: dj('cand', 4) }; const endorsements = []; const links = [L('cand', 'e')];
  for (const id of ['a', 'b', 'c']) { users[id] = dj(id, 5); links.push(L(id, 'e')); endorsements.push(approval(id, 5), approval(id, 6)); }
  const { db } = rankWorld({ users, endorsements, links });
  await rank.lambda._climb('cand');
  assert.strictEqual(db.users.cand.djRank, 5);
});
test('rankPromotion/index.js:climb performance — a full 0 → 5 climb, 20 times', async () => {
  const users = { cand: dj('cand', 0) }; const endorsements = []; const links = [L('cand', 'e')];
  for (const id of ['a', 'b', 'c']) { users[id] = dj(id, 5); links.push(L(id, 'e')); for (let r = 1; r <= 5; r += 1) endorsements.push(approval(id, r)); }
  const t = await seconds(20, async () => { const w = rankWorld({ users, endorsements, links }); await rank.lambda._climb('cand'); assert.strictEqual(w.db.users.cand.djRank, 5); });
  assert.ok(t < 4, `${t}s`);
});

test('rankPromotion/index.js:handler security — forged approvals are neutralised and never promote', async () => {
  const forged = (to) => ({ ...approval(to), id: `f-${to}`, updatedAt: '2026-10-01T00:00:00Z' });
  const { db } = rankWorld({ users: { cand: dj('cand', 1), a: dj('a', 3), b: dj('b', 3) }, endorsements: [forged('a'), forged('b')], links: [L('cand', 'e'), L('a', 'e'), L('b', 'e')] });
  const insert = (id, to) => ({ eventName: 'INSERT', dynamodb: { NewImage: img({ ...base, id, toUserID: to, status: 'approved' }) } });
  await quiet(() => rank.lambda.handler({ Records: [insert('f-a', 'a'), insert('f-b', 'b')] }));
  assert.strictEqual(db.users.cand.djRank, 1);
  assert.deepStrictEqual(db.endorsements.map((e) => e.status), ['pending', 'pending']);
});
test('rankPromotion/index.js:handler performance — a 500-record batch for one candidate climbs once', async () => {
  const { db, fake } = rankWorld({ users: { cand: dj('cand', 1), a: dj('a', 3), b: dj('b', 3) }, endorsements: [approval('a'), approval('b')], links: [L('cand', 'e'), L('a', 'e'), L('b', 'e')] });
  const rec = modify({ ...base, status: 'approved' }, { ...base, status: 'pending' });
  let t; await quiet(async () => { t = await seconds(1, () => rank.lambda.handler({ Records: Array.from({ length: 500 }, () => rec) })); });
  assert.strictEqual(db.users.cand.djRank, 2); assert.ok(t < 3, `${t}s`);
  assert.ok(fake.calls.length < 30, `deduplicated: ${fake.calls.length} AppSync calls`);
});
