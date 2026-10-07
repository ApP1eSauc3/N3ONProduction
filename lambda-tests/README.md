# Lambda tests

Unit tests for the N3ON Amplify functions. No AWS access needed — AppSync is
faked in memory, but every request goes through the real SigV4 signer, and every
GraphQL document is validated against the compiled schema
(`amplify/backend/api/n3on/build/schema.graphql`).

```bash
cd lambda-tests && npm install && npm test
```

Run before every `amplify push` that touches `amplify/backend/function/`.
Re-run after `amplify push` regenerates the schema build — a renamed field fails
the `*schema*` checks instead of failing in production.
