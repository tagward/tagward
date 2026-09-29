# ADR-010 · Plugin audit reaches OpenSearch through files and Fluent Bit

Status: accepted. Amends the "primary path" of ADR-004; the rest of ADR-004 stands.

## Context

ADR-004 assumed the Ranger plugin inside Trino could write audit events straight
to OpenSearch through a Ranger OpenSearch audit destination. Reading the upstream
sources for the pinned versions shows otherwise:

- Trino 483 bundles Ranger 2.8.0 client libraries. Its audit destinations are
  Elasticsearch, HDFS, log4j, Solr, Kafka and CloudWatch. There is no OpenSearch
  destination in Ranger 2.8.0, and none in 2.9.0 either. RANGER-4676 added an
  OpenSearch dispatcher to the separate Ranger Audit Server, not to the plugin library.
- The Elasticsearch destination against OpenSearch is the configuration whose
  failure motivated RANGER-4676 in the first place.
- Ranger admin gained OpenSearch as an audit *source* in 2.9.0: `setup.sh`
  accepts `audit_store=opensearch` and writes `ranger.audit.source.type` and the
  `ranger.audit.opensearch.*` properties. Ranger admin 2.8.0 does not.
- The HDFS destination writes JSON lines through Hadoop's filesystem API and
  accepts `file://` URIs, producing one JSON object per line with the field names of
  `AuthzAuditEvent`. Field names differ from the index format in three places:
  `cluster_name`, `zone_name` and `policy_version` become `cluster`, `zoneName` and
  `policyVersion`. Dates are written as `yyyy-MM-dd HH:mm:ss.SSS`.

## Decision

1. Ranger admin is pinned to 2.9.0 or newer and reads audits from OpenSearch natively.
2. The Trino plugin writes audit through the HDFS destination to a local volume
   (`file:///var/log/ranger/audit`), with the plugin's own spooling. A Fluent Bit
   sidecar tails those files, renames the three fields, and writes to the
   `ranger_audits` index in OpenSearch.
3. The index template is ours, installed before anything writes, with `evtTime`
   accepting both the file date format and epoch milliseconds, and Ranger admin's
   own index bootstrap disabled.
4. When a Trino release bundles a Ranger client with a working OpenSearch
   destination, the sidecar is removed and the plugin writes directly. That change
   is a version bump, not a redesign, because the index format is the same.

## Consequences

- One more container on the Trino side. It is small and stateless.
- Audit events are durable on the local volume between plugin and OpenSearch; an
  OpenSearch outage delays indexing, it does not lose events.
- The compose stack, Spec 05 and the Trino configuration follow this record.
- The M0 verification of the audit path tests this design, not the one in ADR-004.
