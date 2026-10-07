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

function parseBody(event) {
  if (!event || event.body == null || event.body === '') return {};
  const raw = event.isBase64Encoded ? Buffer.from(event.body, 'base64').toString('utf8') : event.body;
  try {
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

/** Response envelope shared with the iOS client's decoders. */
function respond(statusCode, payload) {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  };
}

const ok = (payload) => respond(200, { success: true, ...payload });
const fail = (statusCode, errorCode, extra = {}) =>
  respond(statusCode, { success: false, errorCode, ...extra });

module.exports = { callerSub, parseBody, respond, ok, fail };
