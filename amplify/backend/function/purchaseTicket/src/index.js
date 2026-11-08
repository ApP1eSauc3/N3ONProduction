/* Amplify Params - DO NOT EDIT
	API_N3ON_GRAPHQLAPIENDPOINTOUTPUT
	API_N3ON_GRAPHQLAPIIDOUTPUT
	ENV
	REGION
Amplify Params - DO NOT EDIT *//**
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
 * Per-user cap: a check of "tickets already held" followed by the stock CAS is
 * check-then-act — two concurrent requests both see 0 held and both buy 10
 * (LEAN-RESEARCH.md F1). The cap is instead a TicketAllowance row per
 * (event, buyer), id `<eventID>_<sub>`, raised with a conditional write
 * `issued == n` (so `n + q <= 10` holds at write time) BEFORE stock is taken,
 * and lowered again if the purchase then fails. The check and the write are
 * one DynamoDB operation, which is what closes the race.
 *
 * AUTOMERGE caveat (AWS AppSync conflict-resolution docs): on a versioned
 * table with the Automerge handler, a write carrying a stale _version is NOT
 * rejected — the server keeps its own scalar values, bumps _version and
 * returns success. Event uses Automerge (DataStore clients need it), so every
 * CAS here also checks the response: success only if the returned row has
 * our value at exactly _version + 1. TicketAllowance is configured with
 * OPTIMISTIC_CONCURRENCY in transform.conf.json, so a stale write is rejected
 * outright; the response check covers it too.
 *
 * Tally gate: with TALLY_ENFORCED=true, sales stay closed until the lineup's
 * coinContribution sum reaches the venue tier's required tally (schema
 * comment on EventDJLink; Prompt/Event/CLAUDE.md). Off by default — curated
 * mode lets admins publish events without an accrued lineup.
 *
 * DEPLOY ORDER: the minted Ticket has `owner = null` (CreateTicketInput has no
 * owner field and IAM callers carry no user claims), so the buyer can only read
 * it once Ticket's @auth reads by `ownerField: "userID"` — see
 * docs/schema-auth-hardening.md. Ship that schema change with this function.
 */
const { graphql, graphqlAll, GraphQLError } = require('./appsync');
const { callerSub, parseBody, ok, fail } = require('./http');

const MAX_PER_REQUEST = 10;
// Server-side tally gate. Off while the platform is in bootstrap/curated mode
// (CurationConfig.platformMode == .curated, where admins force-publish); set
// TALLY_ENFORCED=true when flipping to .community.
const tallyEnforced = () => process.env.TALLY_ENFORCED === 'true';
const MAX_PER_USER_PER_EVENT = 10;
const CAS_ATTEMPTS = 5;

const GET_EVENT = /* GraphQL */ `
  query GetEvent($id: ID!) {
    getEvent(id: $id) { id venueID status eventDate ticketPrice availableTickets _version _deleted }
  }
`;

const GET_VENUE = /* GraphQL */ `
  query GetVenue($id: ID!) {
    getVenue(id: $id) { id maxCapacity _deleted }
  }
`;

const EVENT_LINKS = /* GraphQL */ `
  query EventLinks($eventID: ID!, $nextToken: String) {
    eventDJLinksByEventIDAndCreatedAt(eventID: $eventID, limit: 100, nextToken: $nextToken) {
      items { coinContribution _deleted }
      nextToken
    }
  }
`;

// Every TicketAllowance scalar + sync metadata (AppSync subscriptions deliver
// only selected fields — see the root CLAUDE.md "Lambda mutations" rule).
const ALLOWANCE_FIELDS = 'id eventID userID issued createdAt updatedAt _version _deleted _lastChangedAt';

const GET_ALLOWANCE = /* GraphQL */ `
  query GetAllowance($id: ID!) {
    getTicketAllowance(id: $id) { ${ALLOWANCE_FIELDS} }
  }
`;

const CREATE_ALLOWANCE = /* GraphQL */ `
  mutation CreateAllowance($input: CreateTicketAllowanceInput!) {
    createTicketAllowance(input: $input) { ${ALLOWANCE_FIELDS} }
  }
`;

const SET_ALLOWANCE = /* GraphQL */ `
  mutation SetAllowance($input: UpdateTicketAllowanceInput!, $condition: ModelTicketAllowanceConditionInput) {
    updateTicketAllowance(input: $input, condition: $condition) { ${ALLOWANCE_FIELDS} }
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

// NOTE: no `owner` in CREATE_TICKET's selection — once Ticket's @auth uses
// `ownerField: "userID"` (docs/schema-auth-hardening.md) the implicit `owner`
// field no longer exists on Ticket and selecting it would fail validation.

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
      _version _deleted _lastChangedAt
    }
  }
`;

/**
 * Mirror of EventDraftViewModel.requiredTally: capacity tier base (40/55/80),
 * scaled by a price factor clamped to [0.5, 1.0], floored at 10. Free events
 * use the base. Keep the two in lockstep.
 */
function requiredTally(capacity, ticketPrice) {
  let base;
  let midpointPrice;
  if (capacity <= 200) { base = 40; midpointPrice = 20; }
  else if (capacity <= 500) { base = 55; midpointPrice = 30; }
  else { base = 80; midpointPrice = 50; }
  if (!(ticketPrice > 0)) return base;
  const factor = Math.min(1.0, Math.max(0.5, midpointPrice / ticketPrice));
  return Math.max(10, Math.round(base * factor));
}

async function tallyMet(event) {
  const venue = (await graphql(GET_VENUE, { id: event.venueID })).getVenue;
  if (!venue || venue._deleted) return { met: false, current: 0, required: null };
  const links = await graphqlAll(EVENT_LINKS, { eventID: event.id }, (d) => d.eventDJLinksByEventIDAndCreatedAt);
  const current = links.filter((l) => !l._deleted).reduce((n, l) => n + l.coinContribution, 0);
  const required = requiredTally(venue.maxCapacity, event.ticketPrice);
  return { met: current >= required, current, required };
}

function isConditionFailure(err) {
  const types = (err instanceof GraphQLError && err.errorTypes) || [];
  return types.some((t) => t.includes('ConditionalCheckFailed') || t === 'ConflictUnhandled');
}

async function getEvent(id) {
  const e = (await graphql(GET_EVENT, { id })).getEvent;
  return e && !e._deleted ? e : null;
}

/**
 * True only if the write we sent is the one that landed: the returned row
 * holds our value and moved exactly one version past the row we read. Under
 * Automerge a stale write "succeeds" without applying (see header), and the
 * returned row then fails this check.
 */
function applied(row, field, value, readVersion) {
  return !!row && row[field] === value && row._version === readVersion + 1;
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
      const row = (await graphql(SET_STOCK, {
        input: { id: eventID, availableTickets: next, _version: event._version },
        condition: { availableTickets: { eq: event.availableTickets } },
      })).updateEvent;
      if (applied(row, 'availableTickets', next, event._version)) return next;
      // Merged, not applied — someone else wrote first. Re-read and retry.
    } catch (err) {
      if (!isConditionFailure(err)) throw err;
      // Someone else bought in between — re-read and retry.
    }
  }
  throw new Error('stock contention: retries exhausted');
}

const allowanceID = (eventID, sub) => `${eventID}_${sub}`;

/** Tickets the buyer already holds for this event, from Ticket rows. */
async function heldFromTickets(sub, eventID) {
  const held = await graphqlAll(MY_TICKETS, { userID: sub, eventID }, (d) => d.ticketsByUserIDAndPurchaseTime);
  return held.filter((t) => !t._deleted).reduce((n, t) => n + t.quantity, 0);
}

/**
 * Reserves `quantity` of the buyer's per-event cap. Returns
 * `{ reserved: true }` or `{ reserved: false, held }` when it would pass the
 * cap. The row is created on the buyer's first purchase, seeded from tickets
 * minted before TicketAllowance existed; `create` fails if another request
 * created it first (key condition), and the loop then re-reads it.
 */
async function reserveAllowance(sub, eventID, quantity) {
  const id = allowanceID(eventID, sub);
  for (let attempt = 0; attempt < CAS_ATTEMPTS; attempt += 1) {
    const row = (await graphql(GET_ALLOWANCE, { id })).getTicketAllowance;
    if (row && row._deleted) throw new Error(`allowance ${id} is deleted`);
    const held = row ? row.issued : await heldFromTickets(sub, eventID);
    if (held + quantity > MAX_PER_USER_PER_EVENT) return { reserved: false, held };
    const issued = held + quantity;
    try {
      if (!row) {
        await graphql(CREATE_ALLOWANCE, { input: { id, eventID, userID: sub, issued } });
        return { reserved: true };
      }
      const updated = (await graphql(SET_ALLOWANCE, {
        input: { id, issued, _version: row._version },
        condition: { issued: { eq: row.issued } },
      })).updateTicketAllowance;
      if (applied(updated, 'issued', issued, row._version)) return { reserved: true };
    } catch (err) {
      if (!isConditionFailure(err)) throw err;
    }
    // Another purchase by the same buyer got there first — re-read and retry.
  }
  throw new Error('allowance contention: retries exhausted');
}

/** Gives back a reservation after a failed purchase. Never goes below 0. */
async function releaseAllowance(sub, eventID, quantity) {
  const id = allowanceID(eventID, sub);
  for (let attempt = 0; attempt < CAS_ATTEMPTS; attempt += 1) {
    const row = (await graphql(GET_ALLOWANCE, { id })).getTicketAllowance;
    if (!row || row._deleted) return;
    const issued = Math.max(0, row.issued - quantity);
    try {
      const updated = (await graphql(SET_ALLOWANCE, {
        input: { id, issued, _version: row._version },
        condition: { issued: { eq: row.issued } },
      })).updateTicketAllowance;
      if (applied(updated, 'issued', issued, row._version)) return;
    } catch (err) {
      if (!isConditionFailure(err)) throw err;
    }
  }
  throw new Error('allowance release contention: retries exhausted');
}

/** Release that never masks the original outcome; a failure only over-restricts the buyer. */
async function releaseQuietly(sub, eventID, quantity) {
  try {
    await releaseAllowance(sub, eventID, quantity);
  } catch (err) {
    console.error(JSON.stringify({ msg: 'ALLOWANCE NOT RELEASED — buyer cap over-counts', sub, eventID, quantity, error: err.message }));
  }
}

async function purchase(sub, eventID, quantity) {
  const event = await getEvent(eventID);
  if (!event) return fail(404, 'EVENT_NOT_FOUND');
  if (event.status !== 'live') return fail(409, 'EVENT_NOT_ON_SALE', { status: event.status });
  if (new Date(event.eventDate).getTime() <= Date.now()) return fail(409, 'EVENT_ENDED');
  if (tallyEnforced()) {
    const tally = await tallyMet(event);
    if (!tally.met) return fail(409, 'TALLY_NOT_MET', { current: tally.current, required: tally.required });
  }
  if (event.ticketPrice > 0) return fail(402, 'PAYMENT_REQUIRED');
  if (event.availableTickets < quantity) {
    return fail(409, 'SOLD_OUT', { remainingStock: Math.max(0, event.availableTickets) });
  }

  // Cap first, then stock — the order the F1 fix was proven in.
  const allowance = await reserveAllowance(sub, eventID, quantity);
  if (!allowance.reserved) {
    return fail(409, 'LIMIT_REACHED', { limit: MAX_PER_USER_PER_EVENT, held: allowance.held });
  }

  let remaining;
  try {
    remaining = await adjustStock(eventID, -quantity);
  } catch (err) {
    await releaseQuietly(sub, eventID, quantity);
    throw err;
  }
  if (remaining === null) {
    await releaseQuietly(sub, eventID, quantity);
    return fail(409, 'SOLD_OUT', { remainingStock: 0 });
  }

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
    await releaseQuietly(sub, eventID, quantity);
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
exports._documents = {
  GET_EVENT, GET_VENUE, EVENT_LINKS, MY_TICKETS, SET_STOCK, CREATE_TICKET,
  GET_ALLOWANCE, CREATE_ALLOWANCE, SET_ALLOWANCE,
};
exports._requiredTally = requiredTally;
