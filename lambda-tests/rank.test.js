process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT = 'https://abc.appsync-api.us-east-1.amazonaws.com/graphql';
process.env.AWS_REGION = 'us-east-1';
process.env.AWS_ACCESS_KEY_ID = 'AKIDEXAMPLE'; process.env.AWS_SECRET_ACCESS_KEY = 'secret';
const test = require('node:test'); const assert = require('node:assert');
const appsync = require('../amplify/backend/function/rankPromotion/src/appsync.js');
const lambda = require('../amplify/backend/function/rankPromotion/src/index.js');
const fakeAppSync = require('./fake-appsync');

function world({ users, endorsements, links, updateError }) {
  const db = { users: structuredClone(users), endorsements, links };
  const handlers = {
    getUser: ({ id }) => ({ data: { getUser: db.users[id] || null } }),
    endorsementRequestsByFromUserIDAndTimestamp: ({ fromUserID, targetRank }) => ({
      data: { endorsementRequestsByFromUserIDAndTimestamp: {
        items: db.endorsements.filter(e => e.fromUserID === fromUserID && e.targetRank === targetRank && e.status === 'approved'),
        nextToken: null } } }),
    eventDJLinksByDjIDAndCreatedAt: ({ djID }) => ({
      data: { eventDJLinksByDjIDAndCreatedAt: { items: db.links.filter(l => l.djID === djID), nextToken: null } } }),
    updateUser: ({ input }) => {
      if (updateError) return { errors: [updateError] };
      db.users[input.id] = { ...db.users[input.id], djRank: input.djRank, _version: db.users[input.id]._version + 1 };
      return { data: { updateUser: db.users[input.id] } };
    },
  };
  const fake = fakeAppSync(db, { handlers });
  appsync._setDeps({ fetch: fake.fetch, signer: null });
  return { db, fake };
}
const dj = (id, rank) => ({ id, isDJ: true, djRank: rank, _version: 1, _deleted: null });
const approved = (to, rank = 2) => ({ id: `e-${to}`, fromUserID: 'cand', toUserID: to, targetRank: rank, status: 'approved', _deleted: null });
const link = (djID, eventID) => ({ djID, eventID, _deleted: null });

function streamEvent(newStatus, oldStatus, extra = {}) {
  const img = (s) => ({ fromUserID: { S: 'cand' }, targetRank: { N: String(extra.targetRank || 2) }, status: { S: s } });
  return { Records: [{ eventName: oldStatus ? 'MODIFY' : 'INSERT', dynamodb: { NewImage: img(newStatus), OldImage: oldStatus ? img(oldStatus) : undefined } }] };
}

test('promotes 1 → 2 with two valid endorsers who shared an event', async () => {
  const { db, fake } = world({
    users: { cand: dj('cand', 1), a: dj('a', 2), b: dj('b', 3) },
    endorsements: [approved('a'), approved('b')],
    links: [link('cand', 'ev1'), link('a', 'ev1'), link('b', 'ev1')],
  });
  await lambda.handler(streamEvent('approved', 'pending'));
  assert.strictEqual(db.users.cand.djRank, 2);
  const upd = fake.calls.find(c => c.field === 'updateUser');
  assert.deepStrictEqual(upd.variables.input, { id: 'cand', djRank: 2, _version: 1 });
  assert.deepStrictEqual(upd.variables.condition, { djRank: { eq: 1 } });
  assert.match(upd.headers.authorization, /^AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE\/\d{8}\/us-east-1\/appsync\/aws4_request/);
  assert.strictEqual(upd.url, process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT);
});

test('colluding junior endorsers do not count', async () => {
  const { db } = world({
    users: { cand: dj('cand', 1), a: dj('a', 1), b: dj('b', 1) },
    endorsements: [approved('a'), approved('b')],
    links: [link('cand', 'ev1'), link('a', 'ev1'), link('b', 'ev1')],
  });
  await lambda.handler(streamEvent('approved', 'pending'));
  assert.strictEqual(db.users.cand.djRank, 1);
});

test('endorsers without a shared event do not count', async () => {
  const { db } = world({
    users: { cand: dj('cand', 1), a: dj('a', 2), b: dj('b', 2) },
    endorsements: [approved('a'), approved('b')],
    links: [link('cand', 'ev1'), link('a', 'ev1'), link('b', 'ev2')],
  });
  const r = await lambda._evaluate({ candidateID: 'cand', targetRank: 2 });
  assert.strictEqual(r.promoted, false);
  assert.strictEqual(r.reason, '1/2 valid endorsements');
  assert.strictEqual(db.users.cand.djRank, 1);
});

test('duplicate approvals from one endorser count once', async () => {
  const { db } = world({
    users: { cand: dj('cand', 1), a: dj('a', 2) },
    endorsements: [approved('a'), { ...approved('a'), id: 'dup' }],
    links: [link('cand', 'ev1'), link('a', 'ev1')],
  });
  await lambda.handler(streamEvent('approved', 'pending'));
  assert.strictEqual(db.users.cand.djRank, 1);
});

test('rank 4 → 5 needs three endorsers', async () => {
  const users = { cand: dj('cand', 4), a: dj('a', 5), b: dj('b', 5), c: dj('c', 5) };
  const links = [link('cand', 'ev'), link('a', 'ev'), link('b', 'ev'), link('c', 'ev')];
  let w = world({ users, endorsements: [approved('a', 5), approved('b', 5)], links });
  assert.strictEqual((await lambda._evaluate({ candidateID: 'cand', targetRank: 5 })).promoted, false);
  w = world({ users, endorsements: [approved('a', 5), approved('b', 5), approved('c', 5)], links });
  assert.strictEqual((await lambda._evaluate({ candidateID: 'cand', targetRank: 5 })).promoted, true);
  assert.strictEqual(w.db.users.cand.djRank, 5);
});

test('stale / skipping targets are refused', async () => {
  world({ users: { cand: dj('cand', 1) }, endorsements: [], links: [] });
  assert.strictEqual((await lambda._evaluate({ candidateID: 'cand', targetRank: 3 })).reason, 'current rank 1');
  assert.strictEqual((await lambda._evaluate({ candidateID: 'cand', targetRank: 6 })).reason, 'target out of range');
});

test('unranked DJ (null djRank) can reach rank 1 with attributeExists condition', async () => {
  const { fake } = world({
    users: { cand: { ...dj('cand', null) }, a: dj('a', 1), b: dj('b', 2) },
    endorsements: [approved('a', 1), approved('b', 1)],
    links: [link('cand', 'ev'), link('a', 'ev'), link('b', 'ev')],
  });
  const r = await lambda._evaluate({ candidateID: 'cand', targetRank: 1 });
  assert.strictEqual(r.promoted, true);
  assert.deepStrictEqual(fake.calls.find(c => c.field === 'updateUser').variables.condition,
    { or: [{ djRank: { attributeExists: false } }, { djRank: { eq: 0 } }] });
});

test('stream filter: ignores re-saves, deletes, rejections, removals', () => {
  assert.strictEqual(lambda._approvalsFromStream(streamEvent('approved', 'approved')).length, 0);
  assert.strictEqual(lambda._approvalsFromStream(streamEvent('rejected', 'pending')).length, 0);
  assert.strictEqual(lambda._approvalsFromStream({ Records: [{ eventName: 'REMOVE', dynamodb: {} }] }).length, 0);
  const del = streamEvent('approved', 'pending'); del.Records[0].dynamodb.NewImage._deleted = { BOOL: true };
  assert.strictEqual(lambda._approvalsFromStream(del).length, 0);
  const two = { Records: [...streamEvent('approved').Records, ...streamEvent('approved', 'pending').Records] };
  assert.strictEqual(lambda._approvalsFromStream(two).length, 1, 'dedupes same candidate+rank');
});

test('concurrent rank change is swallowed, other errors make the batch retry', async () => {
  const setup = (err) => world({
    users: { cand: dj('cand', 1), a: dj('a', 2), b: dj('b', 2) },
    endorsements: [approved('a'), approved('b')],
    links: [link('cand', 'e'), link('a', 'e'), link('b', 'e')], updateError: err });
  setup({ message: 'cond', errorType: 'DynamoDB:ConditionalCheckFailedException' });
  await lambda.handler(streamEvent('approved', 'pending'));
  setup({ message: 'conflict', errorType: 'ConflictUnhandled' });
  await lambda.handler(streamEvent('approved', 'pending'));
  setup({ message: 'Not Authorized to access updateUser', errorType: 'Unauthorized' });
  await assert.rejects(lambda.handler(streamEvent('approved', 'pending')), /Not Authorized/);
});

test('missing endpoint env gives an actionable error', async () => {
  const saved = process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT; delete process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT;
  await assert.rejects(appsync.graphql('query{__typename}'), /grant this function API access/);
  process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT = saved;
});
