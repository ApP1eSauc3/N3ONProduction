const test = require('node:test');
const assert = require('node:assert');
const mod = require('../amplify/backend/function/n3on3dbadbe4CustomMessage/src/verification-link.js');

const ev = (triggerSource) => ({
  triggerSource,
  userName: '44d86468-sub',
  request: { codeParameter: '{####}', userAttributes: { email: 'a@example.com' } },
  response: { emailSubject: null, emailMessage: null, smsMessage: null },
});

for (const source of ['CustomMessage_SignUp', 'CustomMessage_ResendCode']) {
  test(`${source} email carries the code placeholder, not a link`, async () => {
    const out = await mod.handler(ev(source));
    assert.ok(out.response.emailMessage.includes('{####}'));
    assert.ok(out.response.smsMessage.includes('{####}'));
    assert.ok(!/https?:\/\//.test(out.response.emailMessage), 'no verification link');
    assert.ok(!out.response.emailMessage.includes('44d86468-sub'), 'no internal user ID');
    assert.ok(out.response.emailSubject);
  });
}

test('other triggers keep the pool default message', async () => {
  for (const source of ['CustomMessage_ForgotPassword', 'CustomMessage_AdminCreateUser', 'CustomMessage_UpdateUserAttribute']) {
    const out = await mod.handler(ev(source));
    assert.strictEqual(out.response.emailMessage, null, source);
  }
});
