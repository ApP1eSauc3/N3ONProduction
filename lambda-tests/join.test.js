process.env.API_N3ON_GRAPHQLAPIENDPOINTOUTPUT = 'https://abc.appsync-api.us-east-1.amazonaws.com/graphql';
process.env.AWS_REGION = 'us-east-1';
process.env.AWS_ACCESS_KEY_ID = 'AKIDEXAMPLE'; process.env.AWS_SECRET_ACCESS_KEY = 'secret';
const test = require('node:test'); const assert = require('node:assert');
const check = require('./schema-validate');
const appsync = require('../amplify/backend/function/joinEvent/src/appsync.js');
const lambda = require('../amplify/backend/function/joinEvent/src/index.js');
const fakeAppSync = require('./fake-appsync');

const PROVIDER = (sub) => `cognito-idp.us-east-1.amazonaws.com/us-east-1_pool,cognito-idp.us-east-1.amazonaws.com/us-east-1_pool:CognitoSignIn:${sub}`;
const req = (sub, body, method = 'POST') => ({ httpMethod: method, body: body === undefined ? undefined : JSON.stringify(body),
  requestContext: { identity: sub ? { cognitoAuthenticationProvider: PROVIDER(sub) } : {} } });
const invite = (eventID) => JSON.stringify({ type: 'event_invite', eventID, eventName: 'N', venueName: 'V', eventDate: '2027-01-01T00:00:00Z' });

function world(o = {}) {
  const db = {
    events: { ev1: { id: 'ev1', hostDJID: 'host', status: 'pending', _deleted: null }, ...(o.events || {}) },
    users: { host: { id: 'host', isDJ: true, djRank: 5 }, dj2: { id: 'dj2', isDJ: true, djRank: 3 },
             fan: { id: 'fan', isDJ: false, djRank: null }, unranked: { id: 'unranked', isDJ: true, djRank: null }, ...(o.users || {}) },
    links: o.links || [],
    messages: o.messages || [],
    rooms: { r1: { id: 'r1', name: lambda._dmRoomName('host', 'dj2') }, rX: { id: 'rX', name: 'dm-host-zzz' }, ...(o.rooms || {}) },
  };
  const handlers = {
    getEvent: ({ id }) => ({ data: { getEvent: db.events[id] || null } }),
    getUser: ({ id }) => ({ data: { getUser: db.users[id] || null } }),
    getEventDJLink: ({ id }) => ({ data: { getEventDJLink: db.links.find(l => l.id === id) || null } }),
    eventDJLinksByDjIDAndCreatedAt: ({ djID, eventID }) => ({ data: { eventDJLinksByDjIDAndCreatedAt: {
      items: db.links.filter(l => l.djID === djID && l.eventID === eventID), nextToken: null } } }),
    messagesBySenderIDAndTimestamp: ({ senderID, eventID }) => ({ data: { messagesBySenderIDAndTimestamp: {
      items: db.messages.filter(m => (o.ignoreSenderKey || m.senderID === senderID) && m.content.includes(eventID)), nextToken: null } } }),
    getChatRoom: ({ id }) => ({ data: { getChatRoom: db.rooms[id] || null } }),
    createEventDJLink: ({ input }) => {
      if (o.createError) return { errors: [o.createError] };
      if (db.links.some(l => l.id === input.id)) return { errors: [{ message: 'exists', errorType: 'DynamoDB:ConditionalCheckFailedException' }] };
      const link = { ...input, owner: null, _deleted: null, _version: 1 }; db.links.push(link);
      return { data: { createEventDJLink: link } };
    },
  };
  const fake = fakeAppSync(db, { handlers });
  appsync._setDeps({ fetch: fake.fetch, signer: null });
  return { db, fake };
}
const body = (r) => JSON.parse(r.body);

test('documents are valid against the deployed schema', { skip: check.SKIP }, () => {
  for (const [k, errs] of Object.entries(check(lambda._documents))) assert.deepStrictEqual(errs, [], k);
});

test('host joins own pending event with rank-5 weight, server-computed', async () => {
  const { db } = world();
  const r = await lambda.handler(req('host', { eventID: 'ev1', coinContribution: 999, userID: 'someone' }));
  assert.strictEqual(r.statusCode, 200);
  assert.deepStrictEqual(body(r), { success: true, linkID: 'ev1_host', coinContribution: 25, alreadyJoined: false });
  assert.deepStrictEqual({ ...db.links[0], createdAt: undefined },
    { id: 'ev1_host', eventID: 'ev1', djID: 'host', rankAtJoining: 5, coinContribution: 25, createdAt: undefined, owner: null, _deleted: null, _version: 1 });
});

test('invited DJ joins via host-owned invite in their dm room', async () => {
  const { db } = world({ messages: [{ id: 'm1', senderID: 'host', chatRoomID: 'r1', content: invite('ev1'), _deleted: null }] });
  const r = await lambda.handler(req('dj2', { eventID: 'ev1' }));
  assert.strictEqual(r.statusCode, 200, r.body);
  assert.strictEqual(body(r).coinContribution, 7);
  assert.strictEqual(db.links[0].djID, 'dj2');
});

test('uninvited DJ is refused', async () => {
  world();
  const r = await lambda.handler(req('dj2', { eventID: 'ev1' }));
  assert.deepStrictEqual([r.statusCode, body(r).errorCode], [403, 'NOT_INVITED']);
});

test('invite JSON posted by the invitee themself does not admit them', async () => {
  // senderID is Message's @auth ownerField, so dj2 can only post as dj2 — even in the shared room.
  world({ messages: [{ id: 'm1', senderID: 'dj2', chatRoomID: 'r1', content: invite('ev1'), _deleted: null }] });
  assert.strictEqual(body(await lambda.handler(req('dj2', { eventID: 'ev1' }))).errorCode, 'NOT_INVITED');
});

test('senderID is re-checked even if the index returned a foreign message', async () => {
  world({ ignoreSenderKey: true,
    messages: [{ id: 'm1', senderID: 'dj2', chatRoomID: 'r1', content: invite('ev1'), _deleted: null }] });
  assert.strictEqual(body(await lambda.handler(req('dj2', { eventID: 'ev1' }))).errorCode, 'NOT_INVITED');
});

test('invite sent to a different DJ room does not admit the caller', async () => {
  world({ messages: [{ id: 'm1', senderID: 'host', chatRoomID: 'rX', content: invite('ev1'), _deleted: null }] });
  assert.strictEqual(body(await lambda.handler(req('dj2', { eventID: 'ev1' }))).errorCode, 'NOT_INVITED');
});

test('invite for a different event (eventID substring) is refused', async () => {
  world({ events: { ev10: { id: 'ev10', hostDJID: 'host', status: 'pending' } },
    messages: [{ id: 'm1', senderID: 'host', chatRoomID: 'r1', content: invite('ev10'), _deleted: null }] });
  assert.strictEqual(body(await lambda.handler(req('dj2', { eventID: 'ev1' }))).errorCode, 'NOT_INVITED');
});

test('non-DJ, live event, missing event are refused', async () => {
  world();
  assert.strictEqual(body(await lambda.handler(req('fan', { eventID: 'ev1' }))).errorCode, 'NOT_A_DJ');
  world({ events: { ev1: { id: 'ev1', hostDJID: 'host', status: 'live' } } });
  const r = await lambda.handler(req('host', { eventID: 'ev1' }));
  assert.deepStrictEqual([r.statusCode, body(r).errorCode], [409, 'EVENT_NOT_OPEN']);
  world();
  assert.strictEqual(body(await lambda.handler(req('host', { eventID: 'nope' }))).errorCode, 'EVENT_NOT_FOUND');
});

test('idempotent: second join returns existing link, including admin-made links', async () => {
  const { db } = world();
  await lambda.handler(req('host', { eventID: 'ev1' }));
  const again = body(await lambda.handler(req('host', { eventID: 'ev1' })));
  assert.deepStrictEqual([again.alreadyJoined, db.links.length], [true, 1]);
  world({ links: [{ id: 'random-uuid', eventID: 'ev1', djID: 'host', coinContribution: 25, _deleted: null }] });
  assert.strictEqual(body(await lambda.handler(req('host', { eventID: 'ev1' }))).linkID, 'random-uuid');
});

test('rejoin after leaving: tombstone yields a deterministic successor ID', async () => {
  const { db } = world();
  db.links.push({ id: 'ev1_host', eventID: 'ev1', djID: 'host', coinContribution: 25, _deleted: true, _lastChangedAt: 1700 });
  const r = body(await lambda.handler(req('host', { eventID: 'ev1' })));
  assert.deepStrictEqual([r.success, r.linkID, r.alreadyJoined], [true, 'ev1_host_1700', false]);
  const again = body(await lambda.handler(req('host', { eventID: 'ev1' })));
  assert.deepStrictEqual([again.linkID, again.alreadyJoined], ['ev1_host_1700', true]);
});

test('race: concurrent create conflict resolves to the winner link', async () => {
  const { db, fake } = world();
  let first = true;
  // Simulate another request creating the link between our lookup and create.
  const orig = fake.fetch;
  appsync._setDeps({ fetch: async (url, init) => {
    const { query } = JSON.parse(init.body);
    if (first && query.includes('createEventDJLink')) {
      first = false;
      db.links.push({ id: 'ev1_host', eventID: 'ev1', djID: 'host', coinContribution: 25, _deleted: null });
    }
    return orig(url, init);
  } });
  const r = body(await lambda.handler(req('host', { eventID: 'ev1' })));
  assert.deepStrictEqual([r.success, r.alreadyJoined, db.links.length], [true, true, 1]);
});

test('unexpected AppSync errors return 500 SERVER_ERROR', async () => {
  world({ createError: { message: 'Not Authorized', errorType: 'Unauthorized' } });
  const r = await lambda.handler(req('host', { eventID: 'ev1' }));
  assert.deepStrictEqual([r.statusCode, body(r).errorCode], [500, 'SERVER_ERROR']);
});

test('unranked DJ joins with 0 weight (rank 1 floor)', async () => {
  const { db } = world({ events: { ev2: { id: 'ev2', hostDJID: 'unranked', status: 'pending' } } });
  const r = body(await lambda.handler(req('unranked', { eventID: 'ev2' })));
  assert.deepStrictEqual([r.coinContribution, db.links[0].rankAtJoining], [0, 1]);
});

test('request validation and auth', async () => {
  world();
  assert.strictEqual((await lambda.handler(req(null, { eventID: 'ev1' }))).statusCode, 401);
  assert.strictEqual((await lambda.handler(req('host', { eventID: 'ev1' }, 'GET'))).statusCode, 405);
  assert.strictEqual((await lambda.handler(req('host', {}))).statusCode, 400);
  assert.strictEqual((await lambda.handler({ ...req('host'), body: '{not json' })).statusCode, 400);
  assert.strictEqual((await lambda.handler({ ...req('host'), body: '[1]' })).statusCode, 400);
});

test('RANK_WEIGHTS env override applies', () => {
  process.env.RANK_WEIGHTS = '{"4":12}';
  assert.deepStrictEqual([1, 2, 3, 4, 5, 9].map(lambda._coinsForRank), [0, 5, 7, 12, 25, 25]);
  process.env.RANK_WEIGHTS = 'garbage';
  assert.strictEqual(lambda._coinsForRank(4), 10);
  delete process.env.RANK_WEIGHTS;
});

test('default weight table matches RankWeight.swift (0/5/7/10/25)', () => {
  delete process.env.RANK_WEIGHTS;
  assert.deepStrictEqual([0, 1, 2, 3, 4, 5].map(lambda._coinsForRank), [0, 0, 5, 7, 10, 25]);
});
