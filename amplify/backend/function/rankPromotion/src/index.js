/* Amplify Params - DO NOT EDIT
	API_N3ON_GRAPHQLAPIENDPOINTOUTPUT
	API_N3ON_GRAPHQLAPIIDOUTPUT
	ENV
	REGION
Amplify Params - DO NOT EDIT *//**
 * rankPromotion — promotes a DJ one rank once enough valid endorsements exist.
 *
 * Trigger: DynamoDB stream on the EndorsementRequest @model table
 * (NEW_AND_OLD_IMAGES — already enabled by the transformer). Runs when a
 * request transitions to status "approved".
 *
 * The client never writes djRank for promotion. Every rule is re-derived here
 * from server data, because the endorsement records themselves are
 * client-written:
 *   - target must be exactly current rank + 1 (no skipping, no stale requests)
 *   - each endorser must currently hold djRank >= target, and
 *   - must have shared at least one event (EventDJLink) with the candidate —
 *     same rule as EndorsementService.eligibleEndorsers on the client, which a
 *     colluding pair of accounts could otherwise bypass;
 *   - endorsers are counted once each (duplicate requests don't stack).
 * Thresholds mirror EndorsementService.requiredEndorsements(forTargetRank:).
 *
 * Only the recipient's update can approve. The candidate may create a request
 * (with any status — CreateEndorsementRequestInput includes it) but holds no
 * update right, and the recipient may update every field (DataStore sends the
 * full model, so field-level @auth can't narrow it). So:
 *   - an INSERT already marked approved is a forgery: reset to "pending" so the
 *     recipient decides, and never counted;
 *   - an approving update that changes fromUserID/toUserID/targetRank re-points
 *     the endorsement at someone who never approved it: set to "rejected";
 *   - at count time only rows the server has updated since creation count
 *     (updatedAt != createdAt — both are resolver-set, absent from every input).
 * Residual: a re-pointed record could be counted by a concurrent invocation on
 * another stream shard before it is rejected. Closing that needs approval to go
 * through a server endpoint instead of a DataStore update.
 *
 * Writes go through AppSync (see appsync.js) so DataStore clients receive the
 * new rank via subscription.
 */
const { graphql, graphqlAll } = require('./appsync');

const MAX_RANK = 5;

/** Mirror of EndorsementService.requiredEndorsements(forTargetRank:). */
function requiredEndorsements(targetRank) {
  return targetRank >= 4 ? 3 : 2;
}

// ── DynamoDB stream image helpers (attribute-value JSON) ─────────────────────

function attr(image, name) {
  const v = image && image[name];
  if (!v) return undefined;
  if ('S' in v) return v.S;
  if ('N' in v) return Number(v.N);
  if ('BOOL' in v) return v.BOOL;
  if ('NULL' in v) return null;
  return undefined;
}

/** Fields that say who endorses whom for what — approving must not change them. */
const IDENTITY_FIELDS = ['fromUserID', 'toUserID', 'targetRank'];

/** A missing OldImage counts as changed, so a malformed record is never trusted. */
function identityChanged(img, old) {
  return IDENTITY_FIELDS.some((f) => attr(img, f) !== attr(old, f));
}

/**
 * Returns the distinct (candidate, targetRank) pairs whose endorsement was just
 * approved by an update. Ignores INSERTs (see suspectsFromStream), removals,
 * soft deletes, updates that changed the endorsement's identity, and records
 * that were already approved before this change (re-saves of the same row).
 */
function approvalsFromStream(event) {
  const seen = new Map();
  for (const record of event.Records || []) {
    if (record.eventName !== 'MODIFY') continue;
    const img = record.dynamodb && record.dynamodb.NewImage;
    const old = record.dynamodb && record.dynamodb.OldImage;
    if (attr(img, 'status') !== 'approved') continue;
    if (attr(img, '_deleted') === true) continue;
    if (identityChanged(img, old)) continue;
    if (attr(old, 'status') === 'approved') continue;

    const candidateID = attr(img, 'fromUserID');
    const targetRank = attr(img, 'targetRank');
    if (!candidateID || !Number.isInteger(targetRank)) continue;
    seen.set(`${candidateID}#${targetRank}`, { candidateID, targetRank });
  }
  return [...seen.values()];
}

/**
 * Returns approved records written by someone not entitled to approve them:
 * created pre-approved (reset to pending) or re-pointed while approved (rejected).
 */
function suspectsFromStream(event) {
  const suspects = new Map();
  for (const record of event.Records || []) {
    const img = record.dynamodb && record.dynamodb.NewImage;
    const old = record.dynamodb && record.dynamodb.OldImage;
    if (attr(img, 'status') !== 'approved' || attr(img, '_deleted') === true) continue;
    const id = attr(img, 'id');
    if (!id) continue;
    if (record.eventName === 'INSERT') {
      suspects.set(id, { id, resetTo: 'pending', reason: 'created pre-approved' });
    } else if (record.eventName === 'MODIFY' && identityChanged(img, old)) {
      suspects.set(id, { id, resetTo: 'rejected', reason: 'identity changed on approval' });
    }
  }
  return [...suspects.values()];
}

// ── GraphQL documents ────────────────────────────────────────────────────────

// Every scalar on User, plus the sync metadata. AppSync subscriptions only
// carry the fields the triggering mutation selected, so a short selection set
// would deliver nulls for non-null fields to DataStore subscribers.
const USER_FIELDS = `
  id username avatarKey profileAudioKey beatBPM isDJ djRank isCurated
  currentLatitude currentLongitude isSharingLocation sharingForEvent coinBalance
  createdAt updatedAt _version _deleted _lastChangedAt
`;

const GET_USER = /* GraphQL */ `
  query GetUser($id: ID!) {
    getUser(id: $id) { id isDJ djRank _version _deleted }
  }
`;

const APPROVED_ENDORSEMENTS = /* GraphQL */ `
  query Approved($fromUserID: ID!, $targetRank: Int!, $nextToken: String) {
    endorsementRequestsByFromUserIDAndTimestamp(
      fromUserID: $fromUserID
      filter: { targetRank: { eq: $targetRank }, status: { eq: "approved" } }
      limit: 100
      nextToken: $nextToken
    ) {
      items { id toUserID createdAt updatedAt _deleted }
      nextToken
    }
  }
`;

// Every EndorsementRequest scalar + sync metadata, for the same subscription
// reason as USER_FIELDS (the recipient's DataStore receives this update).
const ENDORSEMENT_FIELDS = `
  id fromUserID toUserID targetRank message status timestamp
  createdAt updatedAt owner _version _deleted _lastChangedAt
`;

const GET_ENDORSEMENT = /* GraphQL */ `
  query GetEndorsement($id: ID!) {
    getEndorsementRequest(id: $id) { id status _version _deleted }
  }
`;

const SET_ENDORSEMENT_STATUS = /* GraphQL */ `
  mutation SetEndorsementStatus($input: UpdateEndorsementRequestInput!) {
    updateEndorsementRequest(input: $input) { ${ENDORSEMENT_FIELDS} }
  }
`;

const LINKS_BY_DJ = /* GraphQL */ `
  query LinksByDJ($djID: ID!, $nextToken: String) {
    eventDJLinksByDjIDAndCreatedAt(djID: $djID, limit: 100, nextToken: $nextToken) {
      items { eventID _deleted }
      nextToken
    }
  }
`;

const SET_RANK = /* GraphQL */ `
  mutation SetRank($input: UpdateUserInput!, $condition: ModelUserConditionInput) {
    updateUser(input: $input, condition: $condition) { ${USER_FIELDS} }
  }
`;

// ── Domain logic ─────────────────────────────────────────────────────────────

async function getUser(id) {
  const data = await graphql(GET_USER, { id });
  const user = data.getUser;
  return user && !user._deleted ? user : null;
}

/**
 * Approved by an update after creation — i.e. by the recipient or an admin.
 * createdAt/updatedAt are set by the resolver and appear in no input type.
 */
function approvedByUpdate(request) {
  return typeof request.createdAt === 'string'
    && typeof request.updatedAt === 'string'
    && request.updatedAt !== request.createdAt;
}

/** Resets a suspect record. Idempotent: skips one that has already moved on. */
async function neutralize({ id, resetTo }) {
  const current = (await graphql(GET_ENDORSEMENT, { id })).getEndorsementRequest;
  if (!current || current._deleted || current.status !== 'approved') return { neutralized: false };
  await graphql(SET_ENDORSEMENT_STATUS, { input: { id, status: resetTo, _version: current._version } });
  return { neutralized: true };
}

async function eventIDsFor(djID) {
  const links = await graphqlAll(LINKS_BY_DJ, { djID }, (d) => d.eventDJLinksByDjIDAndCreatedAt);
  return new Set(links.filter((l) => !l._deleted).map((l) => l.eventID));
}

/**
 * Counts endorsers that are valid right now. Returns the count and the
 * reasons others were rejected (logged for support/debugging).
 */
async function countValidEndorsers(candidateID, targetRank, excludedIDs = new Set()) {
  const approved = await graphqlAll(
    APPROVED_ENDORSEMENTS,
    { fromUserID: candidateID, targetRank },
    (d) => d.endorsementRequestsByFromUserIDAndTimestamp,
  );
  const rejected = [];
  const trusted = approved.filter((r) => {
    if (r._deleted) return false;
    if (excludedIDs.has(r.id)) {
      rejected.push({ requestID: r.id, reason: 'suspect in this batch' });
      return false;
    }
    if (!approvedByUpdate(r)) {
      rejected.push({ requestID: r.id, reason: 'never updated after creation' });
      return false;
    }
    return true;
  });
  const endorserIDs = [
    ...new Set(trusted.map((r) => r.toUserID)),
  ].filter((id) => id !== candidateID);
  if (endorserIDs.length === 0) return { count: 0, rejected };

  const candidateEvents = await eventIDsFor(candidateID);
  let count = 0;
  for (const endorserID of endorserIDs) {
    const endorser = await getUser(endorserID);
    if (!endorser || !endorser.isDJ) {
      rejected.push({ endorserID, reason: 'not an active DJ' });
      continue;
    }
    if ((endorser.djRank || 0) < targetRank) {
      rejected.push({ endorserID, reason: `rank ${endorser.djRank} < ${targetRank}` });
      continue;
    }
    const theirEvents = await eventIDsFor(endorserID);
    const shared = [...theirEvents].some((id) => candidateEvents.has(id));
    if (!shared) {
      rejected.push({ endorserID, reason: 'no shared event' });
      continue;
    }
    count += 1;
  }
  return { count, rejected };
}

/** Evaluates one candidate. Returns a result object (also used by tests). */
async function evaluate({ candidateID, targetRank }, excludedIDs = new Set()) {
  if (targetRank < 1 || targetRank > MAX_RANK) {
    return { candidateID, targetRank, promoted: false, reason: 'target out of range' };
  }
  const user = await getUser(candidateID);
  if (!user) return { candidateID, targetRank, promoted: false, reason: 'user not found' };
  if (!user.isDJ) return { candidateID, targetRank, promoted: false, reason: 'not a DJ' };

  const current = user.djRank || 0;
  if (targetRank !== current + 1) {
    return { candidateID, targetRank, promoted: false, reason: `current rank ${current}` };
  }

  const required = requiredEndorsements(targetRank);
  const { count, rejected } = await countValidEndorsers(candidateID, targetRank, excludedIDs);
  if (count < required) {
    return { candidateID, targetRank, promoted: false, reason: `${count}/${required} valid endorsements`, rejected };
  }

  // Condition guards against a concurrent promotion/admin edit between the
  // read above and this write: only step from the rank we evaluated.
  const condition = current === 0
    ? { or: [{ djRank: { attributeExists: false } }, { djRank: { eq: 0 } }] }
    : { djRank: { eq: current } };
  await graphql(SET_RANK, {
    input: { id: candidateID, djRank: targetRank, _version: user._version },
    condition,
  });
  return { candidateID, targetRank, promoted: true, count, required };
}

/**
 * @type {import('@types/aws-lambda').DynamoDBStreamHandler}
 */
exports.handler = async (event) => {
  const failures = [];
  // Suspects first, and excluded from this batch's counting even if resetting
  // them fails (the batch then retries, and neutralize() is idempotent).
  const suspects = suspectsFromStream(event);
  const excludedIDs = new Set(suspects.map((s) => s.id));
  for (const s of suspects) {
    try {
      const { neutralized } = await neutralize(s);
      console.warn(JSON.stringify({ msg: 'suspect endorsement', ...s, neutralized }));
    } catch (err) {
      console.error(JSON.stringify({ msg: 'neutralize failed', ...s, error: err.message }));
      failures.push(err);
    }
  }

  const candidates = approvalsFromStream(event);
  for (const c of candidates) {
    try {
      const result = await evaluate(c, excludedIDs);
      console.log(JSON.stringify({ msg: 'rankPromotion', ...result }));
    } catch (err) {
      // A failed condition means someone else already changed the rank — the
      // next approval event re-evaluates, so it is not retried. With conflict
      // detection on, AppSync may report this as either errorType, so both
      // are treated the same.
      const types = err.errorTypes || [];
      if (types.some((t) => t.includes('ConditionalCheckFailed') || t === 'ConflictUnhandled')) {
        console.warn(JSON.stringify({ msg: 'rank changed concurrently', ...c }));
        continue;
      }
      console.error(JSON.stringify({ msg: 'rankPromotion failed', ...c, error: err.message }));
      failures.push(err);
    }
  }
  // Throwing makes Lambda retry the batch. evaluate() is idempotent (the
  // rank precondition stops a double promotion), so retries are safe.
  if (failures.length) throw failures[0];
};

// Exposed for unit tests only.
exports._approvalsFromStream = approvalsFromStream;
exports._suspectsFromStream = suspectsFromStream;
exports._evaluate = evaluate;
exports._requiredEndorsements = requiredEndorsements;
exports._documents = {
  GET_USER, APPROVED_ENDORSEMENTS, LINKS_BY_DJ, SET_RANK, GET_ENDORSEMENT, SET_ENDORSEMENT_STATUS,
};
