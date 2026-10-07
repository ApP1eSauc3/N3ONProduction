/**
 * purchaseTicket — POST /tickets/purchase  { "eventID": "...", "quantity": 1 }
 *
 * The only path that mints Ticket rows. Price, stock and the buyer's identity
 * are all taken from server data — the request body's userID / price fields
 * (if any) are ignored.
 *
 * PAYMENTS ARE NOT IMPLEMENTED. Until the Stripe Connect charge type is decided
 * (FINANCIAL-FORMAT.md §12), only free events (ticketPrice == 0) are issued.
 * A paid event returns 402 PAYMENT_REQUIRED and never mints a ticket.
 *
 * Stock: AppSync updates cannot do an atomic in-place decrement, so the event
 * row is updated with compare-and-swap — `condition: availableTickets == n` —
 * retried on contention. If the ticket write then fails, the decrement is
 * compensated so stock is not lost.
 *
 * DEPLOY ORDER: the minted Ticket has `owner = null` (CreateTicketInput has no
 * owner field and IAM callers carry no user claims), so the buyer can only read
 * it once Ticket's @auth reads by `ownerField: "userID"` — see
 * docs/schema-auth-hardening.md. Ship that schema change with this function.
 */
const { graphql, graphqlAll, GraphQLError } = require('./appsync');
const { callerSub, parseBody, ok, fail } = require('./http');

const MAX_PER_REQUEST = 10;
const MAX_PER_USER_PER_EVENT = 10;
const CAS_ATTEMPTS = 5;

const GET_EVENT = /* GraphQL */ `
  query GetEvent($id: ID!) {
    getEvent(id: $id) { id status eventDate ticketPrice availableTickets _version _deleted }
  }
`;

const MY_TICKETS = /* GraphQL */ `
  query MyTickets($userID: ID!, $eventID: ID!, $nextToken: String) {
    ticketsByUserIDAndPurchaseTime(
      userID: $userID
      filter: { eventID: { eq: $eventID } }
      limit: 100
      nextToken: $nextToken
    ) {
      items { id quantity _deleted }
      nextToken
    }
  }
`;

// Full Event scalars + sync metadata: subscribers (map, event detail) receive
// only the fields this mutation selects.
const SET_STOCK = /* GraphQL */ `
  mutation SetStock($input: UpdateEventInput!, $condition: ModelEventConditionInput) {
    updateEvent(input: $input, condition: $condition) {
      id venueID hostDJID vjUsername package requestNote eventDate posterKey eventName
      description ticketPrice availableTickets status isFeatured createdAt updatedAt
      owner _version _deleted _lastChangedAt
    }
  }
`;

const CREATE_TICKET = /* GraphQL */ `
  mutation CreateTicket($input: CreateTicketInput!) {
    createTicket(input: $input) {
      id eventID userID quantity purchaseTime pricePaid createdAt updatedAt
      owner _version _deleted _lastChangedAt
    }
  }
`;

function isConditionFailure(err) {
  const types = (err instanceof GraphQLError && err.errorTypes) || [];
  return types.some((t) => t.includes('ConditionalCheckFailed') || t === 'ConflictUnhandled');
}

async function getEvent(id) {
  const e = (await graphql(GET_EVENT, { id })).getEvent;
  return e && !e._deleted ? e : null;
}

/**
 * Compare-and-swap on availableTickets. `delta` is negative to take stock,
 * positive to give it back. Returns the new count, or null when there is not
 * enough stock to take.
 */
async function adjustStock(eventID, delta) {
  for (let attempt = 0; attempt < CAS_ATTEMPTS; attempt += 1) {
    const event = await getEvent(eventID);
    if (!event) throw new Error(`event ${eventID} vanished during purchase`);
    const next = event.availableTickets + delta;
    if (next < 0) return null;
    try {
      await graphql(SET_STOCK, {
        input: { id: eventID, availableTickets: next, _version: event._version },
        condition: { availableTickets: { eq: event.availableTickets } },
      });
      return next;
    } catch (err) {
      if (!isConditionFailure(err)) throw err;
      // Someone else bought in between — re-read and retry.
    }
  }
  throw new Error('stock contention: retries exhausted');
}

async function purchase(sub, eventID, quantity) {
  const event = await getEvent(eventID);
  if (!event) return fail(404, 'EVENT_NOT_FOUND');
  if (event.status !== 'live') return fail(409, 'EVENT_NOT_ON_SALE', { status: event.status });
  if (new Date(event.eventDate).getTime() <= Date.now()) return fail(409, 'EVENT_ENDED');
  if (event.ticketPrice > 0) return fail(402, 'PAYMENT_REQUIRED');
  if (event.availableTickets < quantity) {
    return fail(409, 'SOLD_OUT', { remainingStock: Math.max(0, event.availableTickets) });
  }

  const held = await graphqlAll(MY_TICKETS, { userID: sub, eventID }, (d) => d.ticketsByUserIDAndPurchaseTime);
  const alreadyHeld = held.filter((t) => !t._deleted).reduce((n, t) => n + t.quantity, 0);
  if (alreadyHeld + quantity > MAX_PER_USER_PER_EVENT) {
    return fail(409, 'LIMIT_REACHED', { limit: MAX_PER_USER_PER_EVENT, held: alreadyHeld });
  }

  const remaining = await adjustStock(eventID, -quantity);
  if (remaining === null) return fail(409, 'SOLD_OUT', { remainingStock: 0 });

  try {
    const ticket = (await graphql(CREATE_TICKET, {
      input: {
        eventID,
        userID: sub,
        quantity,
        purchaseTime: new Date().toISOString(),
        pricePaid: 0,
      },
    })).createTicket;
    return ok({ ticketID: ticket.id, remainingStock: remaining });
  } catch (err) {
    // Give the stock back so a failed mint doesn't shrink the event.
    try {
      await adjustStock(eventID, quantity);
    } catch (restoreErr) {
      console.error(JSON.stringify({ msg: 'STOCK NOT RESTORED — fix manually', eventID, quantity, error: restoreErr.message }));
    }
    throw err;
  }
}

/**
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
 */
exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') return fail(405, 'METHOD_NOT_ALLOWED');
  const sub = callerSub(event);
  if (!sub) return fail(401, 'UNAUTHENTICATED');
  const body = parseBody(event);
  const quantity = body && body.quantity === undefined ? 1 : body && body.quantity;
  if (!body || typeof body.eventID !== 'string' || !body.eventID
      || !Number.isInteger(quantity) || quantity < 1 || quantity > MAX_PER_REQUEST) {
    return fail(400, 'INVALID_REQUEST');
  }
  try {
    return await purchase(sub, body.eventID, quantity);
  } catch (err) {
    console.error(JSON.stringify({ msg: 'purchaseTicket failed', sub, eventID: body.eventID, error: err.message }));
    return fail(500, 'SERVER_ERROR');
  }
};

// Exposed for unit tests only.
exports._documents = { GET_EVENT, MY_TICKETS, SET_STOCK, CREATE_TICKET };
