# ADR-004 · Ranger audit goes to OpenSearch, no Solr

Status: accepted

## Context

Ranger's default audit store is Solr, which means a Solr cluster and usually
ZooKeeper. OpenMetadata already requires OpenSearch. Ranger has an OpenSearch
audit destination, added under RANGER-4676 and still being cleaned up upstream
under RANGER-5772, and Ranger admin can read audits from it. Ranger plugins write
audit directly from the enforcing process, so the destination classes on the
query path come from the Ranger client library bundled in Trino's plugin.

## Decision

One OpenSearch cluster serves OpenMetadata search and Ranger audit. No Solr, no
ZooKeeper. Two audit paths are specified:

- **Primary.** The Trino Ranger plugin writes to OpenSearch through Ranger's
  OpenSearch destination, with local spooling when OpenSearch is unavailable.
- **Fallback.** The plugin writes JSON audit files to a local volume and a Fluent
  Bit sidecar ships them into the same index. Used if the bundled destination
  proves unreliable on a pinned Trino version.

## Consequences

- The first compose stack must demonstrate a Trino query becoming an audit row
  visible in Ranger admin on the exact pinned versions. This is the first
  verification task of M1.
- The audit index template is ours to maintain, in the distribution repository.
- The controller's audit feedback reads the same index, so there is one source
  of access history for Ranger admin, OpenMetadata and OpenSearch Dashboards.
- If Ranger's OpenSearch client cleanup is not released on our pinned version, we
  may carry the patch in our Ranger image; the Trino side cannot be patched by us,
  hence the fallback path.
