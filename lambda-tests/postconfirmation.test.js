const test = require('node:test');
const assert = require('node:assert');
const mod = require('../amplify/backend/function/n3on3dbadbe4PostConfirmation/src/add-to-group.js');

function stub() { const sent = []; mod._setClient({ send: async (c) => { sent.push(c); } }); return sent; }
const base = { userPoolId: 'us-east-1_pool', userName: 'abc-123', request: { userAttributes: { 'custom:role': 'AdminUser' } } };

test('sign-up adds user to UserGroup', async () => {
  const sent = stub(); process.env.GROUP = 'UserGroup';
  const ev = { ...base, triggerSource: 'PostConfirmation_ConfirmSignUp' };
  assert.strictEqual(await mod.handler(ev), ev);
  assert.strictEqual(sent.length, 1);
  assert.strictEqual(sent[0].name, 'AdminAddUserToGroupCommand');
  assert.deepStrictEqual(sent[0].input, { GroupName: 'UserGroup', UserPoolId: 'us-east-1_pool', Username: 'abc-123' });
});

test('legacy GROUP=Users falls back to UserGroup, never creates a group', async () => {
  const sent = stub(); process.env.GROUP = 'Users';
  await mod.handler({ ...base, triggerSource: 'PostConfirmation_ConfirmSignUp' });
  assert.strictEqual(sent[0].input.GroupName, 'UserGroup');
});

test('privileged GROUP env values are refused', async () => {
  for (const g of ['AdminUser', 'VenueOwnerUser', 'DJUser']) {
    const sent = stub(); process.env.GROUP = g;
    await mod.handler({ ...base, triggerSource: 'PostConfirmation_ConfirmSignUp' });
    assert.strictEqual(sent[0].input.GroupName, 'UserGroup', g);
  }
});

test('custom:role attribute is ignored', async () => {
  const sent = stub(); delete process.env.GROUP;
  await mod.handler({ ...base, triggerSource: 'PostConfirmation_ConfirmSignUp' });
  assert.strictEqual(sent[0].input.GroupName, 'UserGroup');
});

test('password reset confirmation does not touch groups', async () => {
  const sent = stub(); process.env.GROUP = 'UserGroup';
  const ev = { ...base, triggerSource: 'PostConfirmation_ConfirmForgotPassword' };
  assert.strictEqual(await mod.handler(ev), ev);
  assert.strictEqual(sent.length, 0);
});

test('Cognito errors propagate (confirmation surfaces the failure)', async () => {
  mod._setClient({ send: async () => { throw new Error('boom'); } });
  await assert.rejects(mod.handler({ ...base, triggerSource: 'PostConfirmation_ConfirmSignUp' }), /boom/);
});
