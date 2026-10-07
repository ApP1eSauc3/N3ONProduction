// Validates GraphQL documents against the compiled AppSync schema.
const fs = require('fs');
const { buildSchema, parse, validate } = require('graphql');
const PRELUDE = `
scalar AWSDateTime scalar AWSDate scalar AWSTime scalar AWSTimestamp scalar AWSEmail
scalar AWSJSON scalar AWSURL scalar AWSPhone scalar AWSIPAddress
directive @aws_iam on OBJECT | FIELD_DEFINITION
directive @aws_cognito_user_pools(cognito_groups: [String]) on OBJECT | FIELD_DEFINITION
directive @aws_subscribe(mutations: [String]) on FIELD_DEFINITION
directive @aws_api_key on OBJECT | FIELD_DEFINITION
directive @aws_oidc on OBJECT | FIELD_DEFINITION
directive @aws_lambda on OBJECT | FIELD_DEFINITION
`;
const SCHEMA_PATH = require('path').join(__dirname, '../amplify/backend/api/n3on/build/schema.graphql');
// The compiled schema is gitignored — produced by `amplify api gql-compile` / `amplify push`.
const available = fs.existsSync(SCHEMA_PATH);
const schema = available
  ? buildSchema(PRELUDE + fs.readFileSync(SCHEMA_PATH, 'utf8'), { assumeValidSDL: true })
  : null;
const SKIP = available ? false : 'compiled schema missing — run `amplify api gql-compile` first';
module.exports = function check(docs) {
  const out = {};
  for (const [name, doc] of Object.entries(docs)) {
    const errs = validate(schema, parse(doc));
    out[name] = errs.map((e) => e.message);
  }
  return out;
};

module.exports.SKIP = SKIP;

/**
 * Validates against a modified copy of the schema — used to check documents
 * survive a planned @auth change before it is pushed. `edit(sdl) => sdl`.
 */
module.exports.checkAgainst = function checkAgainst(edit, docs) {
  const sdl = edit(fs.readFileSync(SCHEMA_PATH, 'utf8'));
  const altered = buildSchema(PRELUDE + sdl, { assumeValidSDL: true });
  const out = {};
  for (const [name, doc] of Object.entries(docs)) out[name] = validate(altered, parse(doc)).map((e) => e.message);
  return out;
};
