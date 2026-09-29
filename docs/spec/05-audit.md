# Spec 05 · Audit

Ranger plugins write audit from the enforcing process. In this stack that is the
Trino coordinator. No Solr, no ZooKeeper. ADR-004.

## Primary path: plugin → OpenSearch

Trino side, `ranger-trino-audit.xml` mounted by the chart:

| Property | Value |
| --- | --- |
| `xasecure.audit.is.enabled` | `true` |
| `xasecure.audit.destination.opensearch` | `true` |
| `xasecure.audit.destination.opensearch.urls` | OpenSearch service host |
| `xasecure.audit.destination.opensearch.port` | 9200 |
| `xasecure.audit.destination.opensearch.protocol` | https |
| `xasecure.audit.destination.opensearch.index` | `ranger_audits` |
| `xasecure.audit.destination.opensearch.user` / `password` | from secret |
| `xasecure.audit.provider.summary.enabled` | `true` |
| local spool | `xasecure.audit.destination.opensearch.batch.filespool.enable=true`, directory on an emptyDir volume |

Ranger admin side: audit source type OpenSearch, same index, read-only credentials.

Verification, first task of M1: run a denied and an allowed query in Trino, see
both rows in Ranger admin's audit screen, on the pinned Trino and Ranger versions.
Check that the destination class exists in the Ranger client library bundled in
Trino's plugin jar. If TLS to OpenSearch fails, the known upstream gap, terminate
TLS at an in-cluster proxy in front of OpenSearch for the audit path.

## Fallback path: plugin → file → Fluent Bit → OpenSearch

Used when the primary is unreliable on a pinned version.

- `xasecure.audit.destination.log4j=true` with a JSON layout to a file on an
  emptyDir volume shared with a Fluent Bit sidecar.
- Fluent Bit tails, parses JSON, writes to `ranger_audits` with the same field
  names. The index template below makes both paths produce identical documents.
- Ranger admin reads the same index, unchanged.

## Index template

Owned in `compose/config/opensearch/ranger-audits-template.json` and installed by
the chart's init job. Fields per Ranger's `AuthzAuditEvent`: `evtTime`, `reqUser`,
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
