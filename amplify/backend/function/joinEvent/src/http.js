/**
 * API Gateway (REST, Lambda proxy) helpers for N3ON's n3onAPI functions.
 *
 * Kept byte-identical in joinEvent/src and purchaseTicket/src — edit together.
 */

/**
 * The caller's Cognito user-pool `sub` (== User.id), taken from the
 * IAM-authenticated request context that API Gateway populates. n3onAPI paths
 * are "private" (signed with identity-pool credentials), so this value is set
 * by AWS and cannot be forged by the client.
 *
 * Format: "cognito-idp.<region>.amazonaws.com/<poolId>,cognito-idp.<region>.amazonaws.com/<poolId>:CognitoSignIn:<sub>"
 *
 * Never read the user's ID from the request body — that is client-controlled.
 */
function callerSub(event) {
  const provider = event && event.requestContext && event.requestContext.identity
    && event.requestContext.identity.cognitoAuthenticationProvider;
  if (typeof provider !== 'string') return null;
  const match = provider.match(/:CognitoSignIn:([^:,\s]+)$/);
  return match ? match[1] : null;
}

/** Largest request body accepted. These endpoints take a few fields; API
 * Gateway allows 10 MB, which must not reach JSON.parse. */
const MAX_BODY_BYTES = 16 * 1024;

function parseBody(event) {
  if (!event || event.body == null || event.body === '') return {};
  if (typeof event.body !== 'string' || Buffer.byteLength(event.body, 'utf8') > MAX_BODY_BYTES * 2) return null;
  const raw = event.isBase64Encoded ? Buffer.from(event.body, 'base64').toString('utf8') : event.body;
  if (Buffer.byteLength(raw, 'utf8') > MAX_BODY_BYTES) return null;
  try {
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

/**
 * Record IDs from the client (event IDs). DataStore IDs are UUIDs; anything
 * else is refused before it reaches a query filter or a derived key — link
 * IDs are `<eventID>_<sub>`, which is only collision-free when event IDs
 * contain no `_` (LEAN-RESEARCH.md, Ids.link_collision).
 */
function isValidID(id) {
  return typeof id === 'string' && /^[A-Za-z0-9-]{1,64}$/.test(id);
}

/** Response envelope shared with the iOS client's decoders. */
function respond(statusCode, payload) {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  };
}

// The envelope keys go last so a payload can never overwrite them (an
// `extra.success: true` used to turn a failure into a success).
const ok = (payload) => respond(200, { ...payload, success: true });
const fail = (statusCode, errorCode, extra = {}) =>
  respond(statusCode, { ...extra, success: false, errorCode });

module.exports = { callerSub, parseBody, isValidID, respond, ok, fail, MAX_BODY_BYTES };
