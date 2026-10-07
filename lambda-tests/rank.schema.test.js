const test = require('node:test'); const assert = require('node:assert');
const check = require('./schema-validate');
const { _documents } = require('../amplify/backend/function/rankPromotion/src/index.js');
test('rankPromotion GraphQL documents are valid against the deployed schema', { skip: check.SKIP }, () => {
  const res = check(_documents);
  for (const [k, errs] of Object.entries(res)) assert.deepStrictEqual(errs, [], k);
});
