// In-memory AppSync stand-in. Routes by the GraphQL operation's root field.
const { parse } = require('graphql');
module.exports = function fakeAppSync(db, opts = {}) {
  const calls = [];
  async function fetch(url, init) {
    const { query, variables } = JSON.parse(init.body);
    const op = parse(query).definitions[0];
    const field = op.selectionSet.selections[0].name.value;
    calls.push({ field, variables, headers: init.headers, url });
    if (!init.headers.authorization || !/AWS4-HMAC-SHA256/.test(init.headers.authorization)) {
      return resp({ errors: [{ message: 'unsigned', errorType: 'UnauthorizedException' }] });
    }
    const h = opts.handlers && opts.handlers[field];
    if (h) return resp(await h(variables, db));
    return resp({ errors: [{ message: `no handler for ${field}` }] });
  }
  function resp(json) { return { ok: true, status: 200, json: async () => json }; }
  return { fetch, calls };
};
