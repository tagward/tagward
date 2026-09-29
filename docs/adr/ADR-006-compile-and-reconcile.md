# ADR-006 · Compile and reconcile, never two-way sync

Status: accepted

## Context

The original idea was a two-way synchronisation between the catalog and the
policy engine. Bidirectional replication between systems with different type
systems means conflict resolution, loops and unclear ownership, and every
outage leaves the two sides in an unknown relation.

## Decision

Each fact has exactly one system of record. The controller compiles desired
state from its sources into the enforcement backend and reads back actual state
to detect drift, the way a Kubernetes controller reconciles. Information flows
back to the catalog only as status and as suggestions, never as a second copy of
the same fact.

| Fact | Record | Writers |
| --- | --- | --- |
| Asset and schema | source system, mirrored by ingestion | ingestion |
| Classification | OpenMetadata tag labels | classifier, controller for Propagated, stewards |
| Approval | OpenMetadata tag state | stewards |
| Intent, rules, masks, tests | git | pull requests |
| Compiled policy | Ranger managed objects | controller |
| Hand-written policy | Ranger unmanaged objects | Ranger admins |
| Identity | Keycloak | identity team |
| Audit | OpenSearch audit index | Ranger plugin |
| Enforcement status | derived | controller |

## Consequences

- The controller is stateless. Destroying it loses nothing.
- Full resync on an interval is mandatory, because webhooks can be missed.
- Ranger remains usable by hand; unmanaged policies are respected and reported.
