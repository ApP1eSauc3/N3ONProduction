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

function world(o = {}) {
  const db = { event: ev(o.event), tickets: o.tickets || [] };
  let interleave = o.interleave || 0;
  const handlers = {
    getEvent: () => ({ data: { getEvent: db.event } }),
    ticketsByUserIDAndPurchaseTime: ({ userID, eventID }) => ({ data: { ticketsByUserIDAndPurchaseTime: {
      items: db.tickets.filter(t => t.userID === userID && t.eventID === eventID), nextToken: null } } }),
    updateEvent: ({ input, condition }) => {
      if (interleave > 0) { interleave -= 1; db.event.availableTickets -= 1; db.event._version += 1; } // another buyer wins
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
