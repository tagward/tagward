# ADR-005 · Gravitino is not in the first release

Status: accepted

## Context

Apache Gravitino is a fully open-source, Apache 2.0, top-level Apache project that
federates catalogs across Trino, Spark and Flink, has its own metadata store, tags
and authorization model, and a Ranger authorization plugin. Placing it between
Trino and the sources adds one hop on every query, a fourth metadata store to keep
consistent, and a second writer into Ranger. Its Ranger plugin carries documented
limitations and its Trino connector has an open issue on forwarding the session
user, which matters for enforcement.

## Decision

Gravitino is not part of the first release. The canonical model stays
engine-agnostic so that Gravitino can be added later as an optional asset source
and possibly as a second enforcement target when several engines must see
identical catalogs.

## Consequences

- Trino reads sources through its native connectors and the Iceberg REST catalog.
- One writer into Ranger: the controller.
- Multi-engine catalog consistency is a later milestone, and Gravitino is the
  first candidate for it.
