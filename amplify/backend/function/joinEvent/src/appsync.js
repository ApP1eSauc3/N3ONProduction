/**
 * IAM-signed AppSync GraphQL client for N3ON Lambdas.
 *
 * Why AppSync and not DynamoDB directly: the API runs with conflict detection
 * (`ConflictDetection: VERSION`, see api/n3on/transform.conf.json). Only AppSync
 * resolvers maintain `_version` / `_lastChangedAt` and fan writes out to the
 * DataStore delta-sync table and subscriptions. A raw PutItem would be invisible
 * to signed-in clients until their next full sync and would fight their writes.
 *
 * Requires the function to have API access (amplify update function → API →
 * n3on → Query + Mutation). That step adds the endpoint env var, grants
 * appsync:GraphQL, and allow-lists the role in the resolvers' `adminRoles`,
 * which is what lets IAM calls pass @auth on models without an iam rule.
 *
 * Pattern: docs.amplify.aws/gen1/react/build-a-backend/functions/graphql-from-lambda,
 * updated from the deprecated @aws-sdk/signature-v4 to @smithy/* and Node 22 fetch.
 *
 * Kept byte-identical in rankPromotion/src, joinEvent/src and purchaseTicket/src —
 * Gen 1 functions cannot share modules without a layer. Edit all three together.
 */
const { SignatureV4 } = require('@smithy/signature-v4');
const { HttpRequest } = require('@smithy/protocol-http');
const { Sha256 } = require('@aws-crypto/sha256-js');
const { defaultProvider } = require('@aws-sdk/credential-provider-node');

const ENDPOINT_ENV = 'API_N3ON_GRAPHQLAPIENDPOINTOUTPUT';

class GraphQLError extends Error {
  constructor(errors) {
    super(errors.map((e) => e.message).join('; '));
    this.name = 'GraphQLError';
    this.errors = errors;
    // AppSync sets errorType, e.g. "ConflictUnhandled", "Unauthorized",
    // "DynamoDB:ConditionalCheckFailedException".
    this.errorTypes = errors.map((e) => e.errorType).filter(Boolean);
  }
}

let deps = {
  fetch: (...args) => fetch(...args),
  signer: null,
};

function signer() {
  if (!deps.signer) {
    deps.signer = new SignatureV4({
      credentials: defaultProvider(),
      region: process.env.AWS_REGION || process.env.REGION,
      service: 'appsync',
      sha256: Sha256,
    });
  }
  return deps.signer;
}

/**
 * Executes one GraphQL operation. Throws GraphQLError when the response
 * carries `errors` (AppSync can return partial data alongside errors — callers
 * that need partial data should catch and read `err.errors`).
 */
async function graphql(query, variables = {}) {
  const raw = process.env[ENDPOINT_ENV];
  if (!raw) {
    throw new Error(`${ENDPOINT_ENV} is not set — grant this function API access (amplify update function)`);
  }
  const endpoint = new URL(raw);
  const body = JSON.stringify({ query, variables });

  const request = new HttpRequest({
    method: 'POST',
    protocol: endpoint.protocol,
    hostname: endpoint.host,
    path: endpoint.pathname,
    headers: { 'Content-Type': 'application/json', host: endpoint.host },
    body,
  });
  const signed = await signer().sign(request);

  const res = await deps.fetch(endpoint.href, {
    method: 'POST',
    headers: signed.headers,
    body,
  });
  const json = await res.json();
  if (json.errors && json.errors.length) throw new GraphQLError(json.errors);
  if (!res.ok) throw new Error(`AppSync HTTP ${res.status}`);
  return json.data;
}

/** Follows `nextToken` until exhausted. `pick` extracts the connection object. */
async function graphqlAll(query, variables, pick) {
  const items = [];
  let nextToken = null;
  do {
    const data = await graphql(query, { ...variables, nextToken });
    const conn = pick(data) || { items: [], nextToken: null };
    items.push(...conn.items.filter(Boolean));
    nextToken = conn.nextToken;
  } while (nextToken);
  return items;
}

module.exports = {
  graphql,
  graphqlAll,
  GraphQLError,
  // Test seam only.
  _setDeps: (d) => {
    deps = { ...deps, ...d };
  },
};
