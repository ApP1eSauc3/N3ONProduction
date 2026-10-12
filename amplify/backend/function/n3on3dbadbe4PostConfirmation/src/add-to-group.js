const {
  CognitoIdentityProviderClient,
  AdminAddUserToGroupCommand,
} = require('@aws-sdk/client-cognito-identity-provider');

/**
 * Every self-service sign-up lands in the baseline `UserGroup`.
 *
 * - DJ vs Regular is NOT a Cognito group decision — it lives in `User.isDJ`
 *   (DataStore) and is chosen in RoleSelectionView after sign-up.
 * - `VenueOwnerUser` and `AdminUser` are privileged and are only ever granted
 *   by an admin (console / approveVenue). A sign-up must never be able to pick
 *   them, so no client-writable attribute (e.g. `custom:role`) is read here.
 * - The group is never created on the fly: a mistyped GROUP env var used to
 *   silently create an arbitrary group (the old default was "Users", which no
 *   @auth rule references). Unknown values fall back to UserGroup.
 */
const DEFAULT_GROUP = 'UserGroup';
const SELF_SERVICE_GROUPS = new Set([DEFAULT_GROUP]);

function resolveGroup(envGroup) {
  if (envGroup && SELF_SERVICE_GROUPS.has(envGroup)) return envGroup;
  if (envGroup) {
    console.warn(`GROUP "${envGroup}" is not a self-service group; using ${DEFAULT_GROUP}`);
  }
  return DEFAULT_GROUP;
}

let client;
function cognito() {
  if (!client) client = new CognitoIdentityProviderClient({});
  return client;
}

/**
 * @type {import('@types/aws-lambda').PostConfirmationTriggerHandler}
 */
exports.handler = async (event) => {
  // This trigger also fires on ConfirmForgotPassword — a password reset must
  // not touch group membership (it would re-add admin-promoted users to the
  // baseline group).
  if (event.triggerSource !== 'PostConfirmation_ConfirmSignUp') {
    return event;
  }

  // AdminAddUserToGroup is idempotent — safe if Cognito retries the trigger.
  await cognito().send(
    new AdminAddUserToGroupCommand({
      GroupName: resolveGroup(process.env.GROUP),
      UserPoolId: event.userPoolId,
      Username: event.userName,
    }),
  );

  return event;
};

// Exposed for unit tests only.
exports._resolveGroup = resolveGroup;
exports._setClient = (c) => {
  client = c;
};
