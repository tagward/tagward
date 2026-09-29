# ADR-002 · Ranger is the first enforcement backend, OPA the second

Status: accepted

## Context

Trino ships two policy-driven access control plugins in its own repository: one
for Apache Ranger and one for Open Policy Agent. Both support catalog, schema,
table and column authorization, column masking and row filtering. Ranger brings
an admin UI, an audit store and a tag-based policy model that maps directly to
catalog classifications. OPA brings policy as code in Rego, unit tests, and a
richer condition language for attribute and purpose-based rules, but no admin UI
and no audit store.

## Decision

Ranger is the enforcement backend for the first releases. The compiler emits an
intermediate representation from day one so that OPA can be a second target
without changing the model. Purpose-based and consent-based rules are deferred
to the OPA target.

## Consequences

- Ranger semantics constrain the compiler: tag policies are evaluated before
  resource policies, deny wins over allow, masking exists as tag-based policies,
  row filters are resource-based only and must be expanded per table.
- User attributes for row filters come from Ranger usersync, populated from Keycloak.
- The intent format must not contain anything only one backend can express.
  Where it does, the file declares which backend it requires and the plan fails
  for the other.
