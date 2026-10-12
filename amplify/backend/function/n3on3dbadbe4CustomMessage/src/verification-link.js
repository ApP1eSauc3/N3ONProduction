/**
 * Sign-up verification email — sends the 6-digit code the app's confirmation
 * screen asks for (ConfirmationSignupView → AuthService.confirmSignUp).
 *
 * This module used to replace the code with a link to an S3 static-site
 * "verification bucket" (`n3on3dbadbe4verificationbucket-dev`). That bucket has
 * no website configuration and no objects, so the link was dead and the code
 * only appeared as a query parameter inside it. The module name is kept because
 * the trigger's MODULES env var (managed by the Amplify CLI) refers to it.
 *
 * `codeParameter` is Cognito's `{####}` placeholder; Cognito substitutes the
 * real code after this trigger returns and rejects a message that omits it.
 *
 * @type {import('@types/aws-lambda').CustomMessageTriggerHandler}
 */
const CODE_TRIGGERS = new Set(['CustomMessage_SignUp', 'CustomMessage_ResendCode']);

exports.handler = async (event) => {
  if (!CODE_TRIGGERS.has(event.triggerSource)) return event;

  const { codeParameter } = event.request;
  event.response.emailSubject = 'Your N3ON verification code';
  event.response.emailMessage =
    `Thanks for signing up for N3ON. Your verification code is ${codeParameter}. ` +
    'Enter it in the app to finish creating your account. ' +
    "If you didn't sign up, you can ignore this email.";
  event.response.smsMessage = `Your N3ON verification code is ${codeParameter}`;
  return event;
};
