process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT = 'https://abc.appsync-api.us-east-1.amazonaws.com/graphql';
process.env.AWS_REGION = 'us-east-1';
process.env.AWS_ACCESS_KEY_ID = 'AKIDEXAMPLE'; process.env.AWS_SECRET_ACCESS_KEY = 'secret';
const test = require('node:test'); const assert = require('node:assert');
const check = require('./schema-validate');
const appsync = require('../amplify/backend/function/purchaseTicket/src/appsync.js');
const lambda = require('../amplify/backend/function/purchaseTicket/src/index.js');
const fakeAppSync = require('./fake-appsync');

const PROVIDER = (sub) => `cognito-idp.us-east-1.amazonaws.com/p,cognito-idp.us-east-1.amazonaws.com/p:CognitoSignIn:${sub}`;
const req = (sub, body, method = 'POST') => ({ httpMethod: method, body: JSON.stringify(body),
  requestContext: { identity: { cognitoAuthenticationProvider: sub ? PROVIDER(sub) : undefined } } });
const future = new Date(Date.now() + 86400e3).toISOString();
const ev = (o = {}) => ({ id: 'ev1', status: 'live', eventDate: future, ticketPrice: 0, availableTickets: 5, _version: 3, _deleted: null, ...o });

const condFail = { errors: [{ message: 'cond', errorType: 'DynamoDB:ConditionalCheckFailedException' }] };

// A barrier: the first `n` callers wait until all `n` have arrived, so
// concurrent requests finish their reads before any of them writes.
function barrier(n) {
  let waiting = []; let left = n;
  return () => {
    if (left <= 0) return Promise.resolve();
    left -= 1;
    const p = new Promise((res) => waiting.push(res));
    if (left === 0) { waiting.forEach((r) => r()); waiting = []; }
    return p;
  };
}

function world(o = {}) {
  const db = { event: ev(o.event), tickets: o.tickets || [], allowances: structuredClone(o.allowances || {}) };
  let interleave = o.interleave || 0;
  const heldGate = barrier(o.barrier || 0);
  const handlers = {
    getEvent: () => ({ data: { getEvent: db.event } }),
    ticketsByUserIDAndPurchaseTime: async ({ userID, eventID }) => {
      await heldGate();
      return { data: { ticketsByUserIDAndPurchaseTime: {
        items: db.tickets.filter(t => t.userID === userID && t.eventID === eventID), nextToken: null } } };
    },
    // TicketAllowance: DynamoDB semantics under OPTIMISTIC_CONCURRENCY —
    // create fails on an existing id; a stale _version or a false condition is rejected.
    getTicketAllowance: async ({ id }) => {
      await heldGate();
      return { data: { getTicketAllowance: db.allowances[id] ? { ...db.allowances[id] } : null } };
    },
    createTicketAllowance: ({ input }) => {
      if (db.allowances[input.id]) return condFail;
      db.allowances[input.id] = { ...input, _version: 1, _deleted: null };
      return { data: { createTicketAllowance: { ...db.allowances[input.id] } } };
    },
    updateTicketAllowance: ({ input, condition }) => {
      const row = db.allowances[input.id];
      if (!row || row._version !== input._version) return { errors: [{ message: 'conflict', errorType: 'ConflictUnhandled' }] };
      if (condition && row.issued !== condition.issued.eq) return condFail;
      db.allowances[input.id] = { ...row, issued: input.issued, _version: row._version + 1 };
      return { data: { updateTicketAllowance: { ...db.allowances[input.id] } } };
    },
    updateEvent: ({ input, condition }) => {
      if (interleave > 0) { interleave -= 1; db.event.availableTickets -= 1; db.event._version += 1; } // another buyer wins
      // Event runs on AUTOMERGE: a stale _version is not rejected — the server
      // keeps its scalar values, bumps _version and returns success.
      if (o.automerge && input._version !== db.event._version) {
        db.event = { ...db.event, _version: db.event._version + 1 };
        return { data: { updateEvent: db.event } };
      }
      if (db.event.availableTickets !== condition.availableTickets.eq)
        return { errors: [{ message: 'cond', errorType: 'DynamoDB:ConditionalCheckFailedException' }] };
      db.event = { ...db.event, availableTickets: input.availableTickets, _version: db.event._version + 1 };
      return { data: { updateEvent: db.event } };
    },
    createTicket: ({ input }) => {
      if (o.createError) return { errors: [o.createError] };
      const t = { id: `t${db.tickets.length + 1}`, ...input, owner: null, _version: 1 }; db.tickets.push(t);
      return { data: { createTicket: t } };
    },
  };
  const fake = fakeAppSync(db, { handlers });
  appsync._setDeps({ fetch: fake.fetch, signer: null });
  return { db, fake };
}
const b = (r) => JSON.parse(r.body);

test('documents are valid against the deployed schema', { skip: check.SKIP }, () => {
  for (const [k, errs] of Object.entries(check(lambda._documents))) assert.deepStrictEqual(errs, [], k);
});

test('free ticket: mints for the token sub, ignores client userID/price, decrements stock', async () => {
  const { db, fake } = world();
  const r = await lambda.handler(req('buyer', { eventID: 'ev1', quantity: 2, userID: 'victim', pricePaid: 0, ticketPrice: 0 }));
  assert.strictEqual(r.statusCode, 200, r.body);
  assert.deepStrictEqual(b(r), { success: true, ticketID: 't1', remainingStock: 3 });
  assert.strictEqual(db.tickets[0].userID, 'buyer');
  assert.strictEqual(db.tickets[0].quantity, 2);
  assert.strictEqual(db.tickets[0].pricePaid, 0);
  const upd = fake.calls.find(c => c.field === 'updateEvent').variables;
  assert.deepStrictEqual(upd, { input: { id: 'ev1', availableTickets: 3, _version: 3 }, condition: { availableTickets: { eq: 5 } } });
});

test('paid events never mint (402) and stock is untouched', async () => {
  const { db } = world({ event: { ticketPrice: 25 } });
  const r = await lambda.handler(req('buyer', { eventID: 'ev1' }));
  assert.deepStrictEqual([r.statusCode, b(r).errorCode], [402, 'PAYMENT_REQUIRED']);
  assert.deepStrictEqual([db.tickets.length, db.event.availableTickets], [0, 5]);
});

test('status, date, existence and sold-out gates', async () => {
  world({ event: { status: 'pending' } });
  assert.strictEqual(b(await lambda.handler(req('u', { eventID: 'ev1' }))).errorCode, 'EVENT_NOT_ON_SALE');
  world({ event: { eventDate: '2020-01-01T00:00:00Z' } });
  assert.strictEqual(b(await lambda.handler(req('u', { eventID: 'ev1' }))).errorCode, 'EVENT_ENDED');
  world({ event: { _deleted: true } });
  assert.strictEqual(b(await lambda.handler(req('u', { eventID: 'ev1' }))).errorCode, 'EVENT_NOT_FOUND');
  world({ event: { availableTickets: 1 } });
  const r = await lambda.handler(req('u', { eventID: 'ev1', quantity: 2 }));
  assert.deepStrictEqual([r.statusCode, b(r).errorCode, b(r).remainingStock], [409, 'SOLD_OUT', 1]);
});

test('per-user cap counts existing tickets', async () => {
  world({ event: { availableTickets: 50 }, tickets: [{ userID: 'u', eventID: 'ev1', quantity: 9, _deleted: null }] });
  const r = b(await lambda.handler(req('u', { eventID: 'ev1', quantity: 2 })));
  assert.deepStrictEqual([r.errorCode, r.held], ['LIMIT_REACHED', 9]);
});

test('CAS retries under contention and never oversells', async () => {
  const { db } = world({ event: { availableTickets: 3 }, interleave: 2 });
  const r = b(await lambda.handler(req('u', { eventID: 'ev1', quantity: 1 })));
  assert.deepStrictEqual([r.success, r.remainingStock, db.event.availableTickets], [true, 0, 0]);
  const { db: db2 } = world({ event: { availableTickets: 2 }, interleave: 2 });
  const r2 = b(await lambda.handler(req('u', { eventID: 'ev1', quantity: 1 })));
  assert.deepStrictEqual([r2.errorCode, db2.event.availableTickets, db2.tickets.length], ['SOLD_OUT', 0, 0]);
});

// ── F1 (LEAN-RESEARCH.md): the per-user cap under concurrency ─────────────
test('per-user cap holds under concurrent requests', async () => {
  const { db } = world({ event: { availableTickets: 100 }, barrier: 2 });
  const rs = await Promise.all([
    lambda.handler(req('buyer', { eventID: 'ev1', quantity: 10 })),
    lambda.handler(req('buyer', { eventID: 'ev1', quantity: 10 })),
  ]);
  const held = db.tickets.filter(t => t.userID === 'buyer').reduce((n, t) => n + t.quantity, 0);
  assert.ok(held <= 10, `buyer holds ${held}`);
  assert.deepStrictEqual(rs.map(r => b(r).errorCode || 'ok').sort(), ['LIMIT_REACHED', 'ok']);
  assert.strictEqual(db.event.availableTickets, 90, 'the refused request took no stock');
});

test('per-user cap: smaller concurrent requests fill the cap exactly', async () => {
  const { db } = world({ event: { availableTickets: 100 }, barrier: 3 });
  const rs = await Promise.all([4, 4, 4].map(q => lambda.handler(req('buyer', { eventID: 'ev1', quantity: q }))));
  const held = db.tickets.reduce((n, t) => n + t.quantity, 0);
  assert.strictEqual(held, 8);
  assert.strictEqual(rs.filter(r => b(r).errorCode === 'LIMIT_REACHED').length, 1);
  assert.strictEqual(db.allowances['ev1_buyer'].issued, 8);
});

test('allowance is seeded from tickets bought before it existed', async () => {
  const { db } = world({ event: { availableTickets: 50 }, tickets: [{ userID: 'u', eventID: 'ev1', quantity: 7, _deleted: null }] });
  assert.strictEqual(b(await lambda.handler(req('u', { eventID: 'ev1', quantity: 3 }))).success, true);
  assert.strictEqual(db.allowances['ev1_u'].issued, 10);
  const r = b(await lambda.handler(req('u', { eventID: 'ev1', quantity: 1 })));
  assert.deepStrictEqual([r.errorCode, r.limit, r.held], ['LIMIT_REACHED', 10, 10]);
});

test('sold out after reserving releases the allowance', async () => {
  const { db } = world({ event: { availableTickets: 2 }, interleave: 2 });
  const r = b(await lambda.handler(req('u', { eventID: 'ev1', quantity: 1 })));
  assert.strictEqual(r.errorCode, 'SOLD_OUT');
  assert.strictEqual(db.allowances['ev1_u'].issued, 0);
});

test('a failed mint releases the allowance as well as the stock', async () => {
  const { db } = world({ createError: { message: 'boom', errorType: 'Unauthorized' } });
  await lambda.handler(req('u', { eventID: 'ev1', quantity: 2 }));
  assert.strictEqual(db.allowances['ev1_u'].issued, 0);
  assert.strictEqual(db.event.availableTickets, 5);
});

test('a stale stock write merged by AUTOMERGE is not mistaken for success', async () => {
  // interleave bumps _version under us; automerge then "succeeds" without
  // applying our value. The CAS must notice and retry, not oversell.
  const { db } = world({ event: { availableTickets: 3 }, interleave: 1, automerge: true });
  const r = b(await lambda.handler(req('u', { eventID: 'ev1', quantity: 1 })));
  assert.deepStrictEqual([r.success, r.remainingStock, db.event.availableTickets], [true, 1, 1]);
});

test('ticket write failure restores the stock', async () => {
  const { db } = world({ createError: { message: 'boom', errorType: 'Unauthorized' } });
  const r = await lambda.handler(req('u', { eventID: 'ev1', quantity: 2 }));
  assert.deepStrictEqual([r.statusCode, b(r).errorCode], [500, 'SERVER_ERROR']);
  assert.strictEqual(db.event.availableTickets, 5);
});

test('input validation and auth', async () => {
  world();
  for (const bad of [{}, { eventID: 'ev1', quantity: 0 }, { eventID: 'ev1', quantity: 11 }, { eventID: 'ev1', quantity: 1.5 }, { eventID: 'ev1', quantity: '2' }])
    assert.strictEqual((await lambda.handler(req('u', bad))).statusCode, 400, JSON.stringify(bad));
  assert.strictEqual((await lambda.handler(req(null, { eventID: 'ev1' }))).statusCode, 401);
  assert.strictEqual((await lambda.handler(req('u', { eventID: 'ev1' }, 'GET'))).statusCode, 405);
  assert.strictEqual((await lambda.handler({ ...req('u', {}), body: 'null' })).statusCode, 400);
});

test('CREATE_TICKET survives Ticket @auth moving to ownerField "userID" (implicit owner field removed)', { skip: check.SKIP }, () => {
  const dropTicketOwner = (sdl) => sdl.replace(/(type Ticket [^{]*\{[\s\S]*?)\n\s*owner: String\n/, '$1\n');
  const res = check.checkAgainst(dropTicketOwner, { CREATE_TICKET: lambda._documents.CREATE_TICKET });
  assert.deepStrictEqual(res.CREATE_TICKET, []);
  // Control: the edit really removed the field.
  const ctl = check.checkAgainst(dropTicketOwner, { probe: 'mutation{ createTicket(input:{eventID:"e",userID:"u",quantity:1,purchaseTime:"2026-01-01T00:00:00Z"}){ owner } }' });
  assert.match(ctl.probe[0], /Cannot query field "owner" on type "Ticket"/);
});

test('requiredTally mirrors EventDraftViewModel.requiredTally', () => {
  const cases = [[100, 0, 40], [100, 20, 40], [100, 40, 20], [100, 100, 20], [300, 30, 55], [300, 60, 28], [600, 25, 80], [600, 200, 40], [200, 10, 40], [201, 0, 55], [501, 0, 80],
    // F12: negative (corrupt) capacity → smallest tier on both sides.
    [-1, 0, 40], [-500, 40, 20], [0, 0, 40]];
  for (const [cap, price, want] of cases) assert.strictEqual(lambda._requiredTally(cap, price), want, `${cap}/${price}`);
});

function tallyWorld(links, capacity = 150) {
  const w = world();
  const orig = w.fake.fetch;
  appsync._setDeps({ fetch: async (url, init) => {
    const { query } = JSON.parse(init.body);
    if (query.includes('getVenue')) return { ok: true, status: 200, json: async () => ({ data: { getVenue: { id: 'v1', maxCapacity: capacity, _deleted: null } } }) };
    if (query.includes('eventDJLinksByEventIDAndCreatedAt')) return { ok: true, status: 200, json: async () => ({ data: { eventDJLinksByEventIDAndCreatedAt: { items: links, nextToken: null } } }) };
    return orig(url, init);
  } });
  return w;
}

test('tally gate (TALLY_ENFORCED=true) blocks sales until the lineup tally is met', async () => {
  process.env.TALLY_ENFORCED = 'true';
  try {
    let w = tallyWorld([{ coinContribution: 25, _deleted: null }, { coinContribution: 10, _deleted: null }, { coinContribution: 25, _deleted: true }]);
    let r = await lambda.handler(req('u', { eventID: 'ev1' }));
    assert.deepStrictEqual([r.statusCode, b(r).errorCode, b(r).current, b(r).required], [409, 'TALLY_NOT_MET', 35, 40]);
    assert.strictEqual(w.db.event.availableTickets, 5, 'stock untouched');
    w = tallyWorld([{ coinContribution: 25, _deleted: null }, { coinContribution: 25, _deleted: null }]);
    r = await lambda.handler(req('u', { eventID: 'ev1' }));
    assert.strictEqual(b(r).success, true);
  } finally { delete process.env.TALLY_ENFORCED; }
});

test('tally gate is off by default (curated mode)', async () => {
  tallyWorld([]);
  assert.strictEqual(b(await lambda.handler(req('u', { eventID: 'ev1' }))).success, true);
});

// TicketAllowance's cap guarantee assumes a stale write is REJECTED. That is
// only true under OPTIMISTIC_CONCURRENCY; the project default AUTOMERGE would
// merge it. Amplify CLI 13 takes the per-model handler from cli-inputs.json
// (transform.conf.json alone is ignored — verified with gql-compile).
test('TicketAllowance is configured for OPTIMISTIC_CONCURRENCY', () => {
  const fs = require('fs'); const path = require('path');
  const api = path.join(__dirname, '../amplify/backend/api/n3on');
  const inputs = JSON.parse(fs.readFileSync(path.join(api, 'cli-inputs.json'), 'utf8'));
  const per = inputs.serviceConfiguration.conflictResolution.perModelResolutionStrategy || [];
  assert.deepStrictEqual(per.find(m => m.entityName === 'TicketAllowance'),
    { resolutionStrategy: { type: 'OPTIMISTIC_CONCURRENCY' }, entityName: 'TicketAllowance' });
  const stack = path.join(api, 'build/stacks/TicketAllowance.json');
  if (fs.existsSync(stack)) {
    const handlers = new Set([...fs.readFileSync(stack, 'utf8').matchAll(/"ConflictHandler":\s*"(\w+)"/g)].map(m => m[1]));
    assert.deepStrictEqual([...handlers], ['OPTIMISTIC_CONCURRENCY'], 'compiled stack');
  }
});

test('allowance mutations select every TicketAllowance scalar', { skip: check.SKIP }, () => {
  const fs = require('fs'); const path = require('path');
  const sdl = fs.readFileSync(path.join(__dirname, '../amplify/backend/api/n3on/build/schema.graphql'), 'utf8');
  const body = sdl.match(/type TicketAllowance [^{]*\{([^}]*)\}/)[1];
  const scalars = [...body.matchAll(/^\s*(\w+):\s*(ID|String|Int|Float|Boolean|AWS\w+)!?\s*$/gm)].map(m => m[1]);
  for (const doc of [lambda._documents.CREATE_ALLOWANCE, lambda._documents.SET_ALLOWANCE]) {
    for (const f of scalars) assert.match(doc, new RegExp(`\\b${f}\\b`), f);
  }
});
