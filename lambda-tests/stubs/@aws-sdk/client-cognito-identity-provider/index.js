class Cmd { constructor(input) { this.input = input; this.name = this.constructor.name; } }
class AdminAddUserToGroupCommand extends Cmd {}
class CognitoIdentityProviderClient { async send() { throw new Error('real client must not be used in tests'); } }
module.exports = { AdminAddUserToGroupCommand, CognitoIdentityProviderClient };
