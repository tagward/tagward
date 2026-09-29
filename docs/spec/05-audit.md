# Spec 05 · Audit

Ranger plugins write audit from the enforcing process. In this stack that is the
Trino coordinator. No Solr, no ZooKeeper. ADR-004.

## What the pinned versions actually support

Verified against the upstream sources of the pinned versions (ADR-010):

| Fact | Source |
|---|---|
| Trino 483 bundles Ranger 2.8.0 client libraries | `plugin/trino-ranger/pom.xml` at tag 483 |
| Those libraries ship Elasticsearch, HDFS, log4j, Solr, Kafka and CloudWatch destinations, no OpenSearch destination | `agents-audit/pom.xml` at `release-ranger-2.8.0` and `release-ranger-2.9.0` |
| Ranger admin reads audits from OpenSearch from 2.9.0 | `security-admin/scripts/setup.sh`, `audit_store=opensearch` and `ranger.audit.opensearch.*` |
| File audit events use the `AuthzAuditEvent` field names and dates as `yyyy-MM-dd HH:mm:ss.SSS` | `agents-audit/core/.../AuthzAuditEvent.java`, `MiscUtil.java` |
| Index documents rename `cluster_name`, `zone_name`, `policy_version` to `cluster`, `zoneName`, `policyVersion` | `agents-audit/dest-es/.../ElasticSearchAuditDestination.java` |

## Path in use: plugin → local files → Fluent Bit → OpenSearch

Trino side, `ranger-trino-audit.xml` mounted by the chart and by compose:

| Property | Value |
|---|---|
| `xasecure.audit.is.enabled` | `true` |
| `xasecure.audit.destination.hdfs` | `true` |
| `xasecure.audit.destination.hdfs.dir` | `file:///var/log/ranger/audit` |
| `xasecure.audit.destination.hdfs.subdir` | `%app-type%/%time:yyyyMMdd%` |
| `xasecure.audit.destination.hdfs.filename.format` | `%app-type%_ranger_audit_%hostname%.log` |
| `xasecure.audit.destination.hdfs.file.rollover.sec` | `300` |
| `xasecure.audit.destination.hdfs.batch.filespool.enable` | `true` |
| `xasecure.audit.destination.hdfs.batch.filespool.dir` | `/var/log/ranger/spool` |
| `xasecure.audit.provider.summary.enabled` | `true` |

The HDFS destination accepts `file://` and writes one JSON object per line.

Fluent Bit sidecar, sharing the volume:

- `tail` input on `/var/log/ranger/audit/**/*.log`, JSON parser, database file on the
  volume so restarts do not re-ship.
- `modify` filter renaming `cluster_name` → `cluster`, `zone_name` → `zoneName`,
  `policy_version` → `policyVersion`.
- `opensearch` output to the `ranger_audits` index, `Suppress_Type_Name On`,
  `Replace_Dots Off`, `Generate_ID Off` so the document id stays Ranger's `id`
  through `Id_Key id`.

Ranger admin side, `install.properties`: `audit_store=opensearch`,
`audit_opensearch_urls`, `audit_opensearch_port`, `audit_opensearch_protocol`,
`audit_opensearch_index=ranger_audits`, `audit_opensearch_bootstrap_enabled=false`.
Ranger admin 2.9.0 or newer.

## Direct path, when upstream allows it

The day a Trino release bundles a Ranger client with an OpenSearch destination, the
plugin writes directly with `xasecure.audit.destination.opensearch.*` and the
sidecar is removed. The index format does not change.

## Index template

Owned in `compose/config/opensearch/ranger-audits-template.json` and installed by
the chart's init job and by the compose `opensearch-init` service, before Ranger
admin or Fluent Bit start. Ranger admin's own bootstrap is disabled so the two do
not fight over the mapping. `evtTime` accepts `yyyy-MM-dd HH:mm:ss.SSS`,
ISO 8601 and epoch milliseconds. Fields per Ranger's `AuthzAuditEvent`: `evtTime`, `reqUser`,
`access`, `resource`, `resType`, `result`, `policy`, `enforcer`, `repo`,
`cliIP`, `reqData` (query text), `tags`, `cluster_name`, `zoneName`,
`policyVersion`, `event_count`, `event_dur_ms`, `datatype`. Index lifecycle:
daily rollover, retention configurable, default 400 days.

`reqData` contains the SQL text. It is sensitive. The template marks it
`index: false` by default and the retention for it can be shorter than for the
rest of the document.

## What is audited

- Every access decision on catalog, schema, table, column: allow, deny.
- Column masking and row filtering applied: recorded as allow with policy id.
- Policy download and refresh by the plugin.
- Not audited by Ranger: query results, row counts. Trino's own event listener
  covers query completion (Spec 07 optional events sink).

## Feedback into the catalog

The controller's audit feedback job runs every hour:

1. Query `ranger_audits` for the last 7 days, group by resource for resources that
   carry a Confirmed sensitive tag.
2. Write `tw_recent_access` on the corresponding OpenMetadata asset: count and
   number of distinct users. Never user names, to keep the catalog itself free of
   access-history PII.
3. Emit metrics: sensitive accesses per intent, denies per intent.

## Dashboards

OpenSearch Dashboards is optional and permissively licensed. The distribution
ships one saved-objects export: denies over time, top denied users, sensitive
column reads by group, policy version changes.
