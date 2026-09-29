# ADR-001 · No Apache Atlas

Status: accepted

## Context

The classic open-source path to tag-based access control is Atlas classifications
feeding Ranger tag-sync. Atlas requires JanusGraph, HBase or Cassandra, Solr or
Elasticsearch, and Kafka. It has no Trino entity types in its base type
definitions, and the only Trino tag-sync mapper in the wild is proprietary.
OpenMetadata already covers the catalog role with a fraction of the footprint.

## Decision

Atlas is not part of the stack. Every feature Atlas provided is mapped to a replacement,
and the requirement is that none is lost.

| Atlas feature | Replacement | Provided by |
| --- | --- | --- |
| Metadata repository, types, relationships | OpenMetadata entities | OpenMetadata |
| Classifications on entities and columns | OpenMetadata classifications and tag labels | OpenMetadata |
| Classification attributes | Attributes keyed by tag name in intent files; per-asset overrides as custom properties | controller, git |
| Propagation along lineage | Controller propagation engine over OpenMetadata column lineage, writes Propagated + Suggested labels | controller |
| Propagation controls | Propagation rules: depth, stop tags, declassification tag, transformation exceptions | git |
| Real-time hooks | OpenMetadata connectors on schedule, OpenLineage connector for events | OpenMetadata |
| Kafka change feed | OpenMetadata change events API and webhooks | OpenMetadata |
| Feed to Ranger tag-sync | Controller writes tag service objects directly through the Ranger REST API | controller |
| Glossary, business metadata | OpenMetadata glossary, custom properties | OpenMetadata |
| Lineage queries, search | OpenMetadata lineage API and search | OpenMetadata |
| Entity audit and versions | OpenMetadata versions and change events | OpenMetadata |
| Metadata access control | OpenMetadata roles and policies | OpenMetadata |
| Import and export | OpenMetadata bulk import/export, git | both |

## Consequences

- Three features move into the controller: propagation, attributes, the Ranger feed.
  They become code we own and test, and rules that live in git and get reviewed.
- Organisations that already run Atlas can be served later by a read-only Atlas
  adapter that feeds classifications into OpenMetadata. Not in scope for M1.
- No Ranger tag-sync daemon is deployed at all.
