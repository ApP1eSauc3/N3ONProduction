/* Amplify Params - DO NOT EDIT
	API_N3ON_GRAPHQLAPIENDPOINTOUTPUT
	API_N3ON_GRAPHQLAPIIDOUTPUT
	ENV
	REGION
Amplify Params - DO NOT EDIT *//**
 * joinEvent — POST /events/join  { "eventID": "..." }
 *
 * Adds the calling DJ to an event's lineup by creating an EventDJLink with a
 * server-computed rank snapshot. This is what makes the limbo tally
 * trustworthy: rankAtJoining / coinContribution come from the DJ's current
 * User record and the weight table here, never from the client.
 *
 * Who may join (all re-checked server-side):
 *   - the caller is a DJ (User.isDJ) and the event is still "pending" (limbo);
 *   - the caller IS the host, or
 *   - the host sent the caller an event invite in their DJ↔DJ room. Invites are
 *     chat messages (EventInviteSheet) in the room named
 *     "dm-{sortedID1}-{sortedID2}" (ChatRoomService.openDJDirectRoom). The
 *     message's `senderID` cannot be forged: it is Message's @auth ownerField,
 *     so the createMessage resolver rejects any senderID other than the
 *     caller's own sub, and no client role may update a message afterwards.
 *
 * Idempotent: the link ID is derived from (eventID, djID), so a retry or a
 * double tap returns the existing link instead of double-counting the tally.
 *
 * Rank weights mirror the documented 0/5/7/10/25 table (Data/RankWeight.swift).
 * Override without a redeploy of code via the RANK_WEIGHTS env var, e.g.
 * {"1":0,"2":5,"3":7,"4":10,"5":25}.
 */
const { graphql, graphqlAll, GraphQLError } = require('./appsync');
const { callerSub, parseBody, ok, fail } = require('./http');

const DEFAULT_WEIGHTS = { 1: 0, 2: 5, 3: 7, 4: 10, 5: 25 };

function rankWeights() {
  if (!process.env.RANK_WEIGHTS) return DEFAULT_WEIGHTS;
  try {
    return { ...DEFAULT_WEIGHTS, ...JSON.parse(process.env.RANK_WEIGHTS) };
  } catch {
    console.error('RANK_WEIGHTS is not valid JSON — using defaults');
    return DEFAULT_WEIGHTS;
  }
}

/** Same rule as RankWeight.coins(forRank:): unranked/rank 1 → 0, ≥5 → rank-5 weight. */
function coinsForRank(rank) {
  const w = rankWeights();
  if (rank < 2) return w[1];
  if (rank >= 5) return w[5];
  return w[rank];
}

/** Deterministic room name — must match ChatRoomService.openDJDirectRoom. */
function dmRoomName(a, b) {
  const [x, y] = [a, b].sort();
  return `dm-${x}-${y}`;
}

/** Deterministic link ID — makes joins idempotent under retries/races. */
function linkID(eventID, djID) {
  return `${eventID}_${djID}`;
}

// ── GraphQL documents ────────────────────────────────────────────────────────

const GET_EVENT = /* GraphQL */ `
  query GetEvent($id: ID!) {
    getEvent(id: $id) { id hostDJID status _deleted }
  }
`;

const GET_USER = /* GraphQL */ `
  query GetUser($id: ID!) {
    getUser(id: $id) { id isDJ djRank _deleted }
  }
`;

const GET_LINK = /* GraphQL */ `
  query GetLink($id: ID!) {
    getEventDJLink(id: $id) { id eventID djID rankAtJoining coinContribution _deleted _lastChangedAt }
  }
`;

const LINKS_BY_DJ = /* GraphQL */ `
  query LinksByDJ($djID: ID!, $eventID: ID!, $nextToken: String) {
    eventDJLinksByDjIDAndCreatedAt(
      djID: $djID
      filter: { eventID: { eq: $eventID } }
      limit: 100
      nextToken: $nextToken
    ) {
      items { id eventID djID rankAtJoining coinContribution _deleted }
      nextToken
    }
  }
`;

const HOST_INVITES = /* GraphQL */ `
  query HostInvites($senderID: ID!, $eventID: String!, $nextToken: String) {
    messagesBySenderIDAndTimestamp(
      senderID: $senderID
      filter: { content: { contains: $eventID } }
      sortDirection: DESC
      limit: 100
      nextToken: $nextToken
    ) {
      items { id senderID chatRoomID content _deleted }
      nextToken
    }
  }
`;

const GET_ROOM = /* GraphQL */ `
  query GetRoom($id: ID!) {
    getChatRoom(id: $id) { id name _deleted }
  }
`;

// All EventDJLink scalars + sync metadata so DataStore subscribers (the
// limbo tally observer in EventDraftViewModel) receive a complete record.
const CREATE_LINK = /* GraphQL */ `
  mutation CreateLink($input: CreateEventDJLinkInput!) {
    createEventDJLink(input: $input) {
      id eventID djID rankAtJoining coinContribution createdAt updatedAt
      owner _version _deleted _lastChangedAt
    }
  }
`;

// ── Domain logic ─────────────────────────────────────────────────────────────

/**
 * Resolves the deterministic link ID for (event, DJ). DataStore deletes are
 * soft (a `_deleted` tombstone keeps the key), so a DJ who left and rejoins
 * gets a successor ID derived from the tombstone's `_lastChangedAt` —
 * still deterministic, so concurrent retries converge on the same ID.
 * Returns { id, live } where `live` is an existing non-deleted link.
 */
async function resolveLink(eventID, djID) {
  let id = linkID(eventID, djID);
  for (let i = 0; i < 10; i += 1) {
    const link = (await graphql(GET_LINK, { id })).getEventDJLink;
    if (!link) return { id, live: null };
    if (!link._deleted) return { id, live: link };
    id = `${linkID(eventID, djID)}_${link._lastChangedAt}`;
  }
  throw new Error(`too many rejoins for ${eventID}/${djID}`);
}

async function existingLink(eventID, djID) {
  const { live } = await resolveLink(eventID, djID);
  if (live) return live;
  // Links made by the admin console (AdminService.attachDJ) use random IDs.
  const links = await graphqlAll(LINKS_BY_DJ, { djID, eventID }, (d) => d.eventDJLinksByDjIDAndCreatedAt);
  return links.find((l) => !l._deleted && l.eventID === eventID) || null;
}

async function hasInvite(hostID, djID, eventID) {
  const expectedRoom = dmRoomName(hostID, djID);
  const messages = await graphqlAll(
    HOST_INVITES,
    { senderID: hostID, eventID },
    (d) => d.messagesBySenderIDAndTimestamp,
  );
  for (const m of messages) {
    // The index is keyed by senderID; re-check rather than trust the query shape.
    if (m._deleted || m.senderID !== hostID) continue;
    let payload;
    try {
      payload = JSON.parse(m.content);
    } catch {
      continue;
    }
    if (!payload || payload.type !== 'event_invite' || payload.eventID !== eventID) continue;
    const room = (await graphql(GET_ROOM, { id: m.chatRoomID })).getChatRoom;
    if (room && !room._deleted && room.name === expectedRoom) return true;
  }
  return false;
}

async function join(sub, eventID) {
  const event = (await graphql(GET_EVENT, { id: eventID })).getEvent;
  if (!event || event._deleted) return fail(404, 'EVENT_NOT_FOUND');
  if (event.status !== 'pending') return fail(409, 'EVENT_NOT_OPEN', { status: event.status });

  const dj = (await graphql(GET_USER, { id: sub })).getUser;
  if (!dj || dj._deleted || !dj.isDJ) return fail(403, 'NOT_A_DJ');

  const already = await existingLink(eventID, sub);
  if (already) {
    return ok({ linkID: already.id, coinContribution: already.coinContribution, alreadyJoined: true });
  }

  if (event.hostDJID !== sub && !(await hasInvite(event.hostDJID, sub, eventID))) {
    return fail(403, 'NOT_INVITED');
  }

  const rank = dj.djRank || 1;
  const { id } = await resolveLink(eventID, sub);
  const input = {
    id,
    eventID,
    djID: sub,
    rankAtJoining: rank,
    coinContribution: coinsForRank(rank),
    createdAt: new Date().toISOString(),
  };
  try {
    const link = (await graphql(CREATE_LINK, { input })).createEventDJLink;
    return ok({ linkID: link.id, coinContribution: link.coinContribution, alreadyJoined: false });
  } catch (err) {
    // Lost a race with a concurrent join for the same (event, DJ): the
    // deterministic ID makes the second create fail its existence condition.
    const types = (err instanceof GraphQLError && err.errorTypes) || [];
    if (types.some((t) => t.includes('ConditionalCheckFailed') || t === 'ConflictUnhandled')) {
      const link = await existingLink(eventID, sub);
      if (link) return ok({ linkID: link.id, coinContribution: link.coinContribution, alreadyJoined: true });
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
  if (!body || typeof body.eventID !== 'string' || !body.eventID) {
    return fail(400, 'INVALID_REQUEST');
  }
  try {
    return await join(sub, body.eventID);
  } catch (err) {
    console.error(JSON.stringify({ msg: 'joinEvent failed', sub, eventID: body.eventID, error: err.message }));
    return fail(500, 'SERVER_ERROR');
  }
};

// Exposed for unit tests only.
exports._documents = { GET_EVENT, GET_USER, GET_LINK, LINKS_BY_DJ, HOST_INVITES, GET_ROOM, CREATE_LINK };
exports._coinsForRank = coinsForRank;
exports._dmRoomName = dmRoomName;
