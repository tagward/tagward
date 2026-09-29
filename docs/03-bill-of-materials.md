# 03 · Bill of materials

Every component, its license, whether we take it upstream or own it, and why.
`versions.yaml` holds the pinned versions; this file holds the reasoning.

| Component | Role | License | Image | Chart | Ours to build |
| --- | --- | --- | --- | --- | --- |
| Trino | Query layer and enforcement point | Apache 2.0 | upstream `trinodb/trino` | upstream `trino/trino` as dependency | configuration only |
| Apache Ranger | Policy store, admin UI, audit UI | Apache 2.0 | **ours**, from the Apache release tarball | **ours** | image, chart, init job |
| OpenMetadata | Catalog, classification, lineage, approval | Apache 2.0 | upstream `openmetadata/server`, `openmetadata/ingestion` | upstream as dependency | configuration, bootstrap via controller |
| Keycloak | Identity provider | Apache 2.0 | upstream `quay.io/keycloak/keycloak` | upstream operator | realm export |
| OpenSearch | Search for OpenMetadata, audit for Ranger | Apache 2.0 | upstream `opensearchproject/opensearch` | upstream `opensearch/opensearch` | index template for audit |
| PostgreSQL | Databases | PostgreSQL License | upstream `postgres` | CloudNativePG operator (Apache 2.0) | cluster manifests |
| Fluent Bit | Fallback audit shipper | Apache 2.0 | upstream | upstream | configuration, optional |
| Controller | The product | Apache 2.0 | **ours** | **ours** | everything |

## Forbidden

| Item | Why |
| --- | --- |
| Elasticsearch | Elastic License / SSPL / AGPL mix. OpenSearch replaces it everywhere. |
| MySQL | GPL. PostgreSQL replaces it. OpenMetadata and Ranger both support PostgreSQL. |
| Bitnami charts and images | Distribution moved to a paid "secure images" model in 2025; free tags are not maintained. Use upstream operators or write our own. |
| Apache Solr as audit store | Not a license problem, an operational one. It is one more cluster, and OpenSearch is already required. ADR-004. |
| Collate-only OpenMetadata features | Not part of the open-source server. We never depend on them. The controller implements propagation itself. |
| Starburst artifacts | Proprietary. The Trino tag mapper and Atlas type definitions they ship are reimplemented here from the Apache 2.0 Ranger Hive mapper as the reference. |

## Why we build our own Ranger image and chart

The official `apache/ranger` images are built from `dev-support/ranger-docker` and are
designed for developer testing: one container per role, configuration baked in by
setup scripts at container start, companion `ranger-db`, `ranger-zk`, `ranger-solr`
images assumed. Community Helm charts wrap those images and depend on Bitnami
PostgreSQL. Neither survives a real cluster: no readiness probes that mean anything,
no externalised configuration, root user, Solr assumed.

Our image requirements are in `docs/spec/06-images.md`. In one line: built from the
Apache release tarball, configuration entirely from environment and mounted files,
non-root, health endpoints, PostgreSQL only, OpenSearch audit, no Solr and no
ZooKeeper.

## Where we would go to the same length if needed

OpenMetadata's chart and images are production quality. Trino's are excellent.
Keycloak's operator is the vendor's own. OpenSearch's chart is maintained by the
project. CloudNativePG is a CNCF project. If any of these regress, the answer is the
same as for Ranger: we build our own and record the reason in an ADR.

## License gate

CI generates a software bill of materials for every image we build and for the
umbrella chart's resolved image list, and fails on any license outside the allow
list: Apache-2.0, MIT, BSD-2-Clause, BSD-3-Clause, PostgreSQL, ISC, MPL-2.0,
EPL-2.0, CDDL for Java runtime bits. Any other license needs an ADR to be allowed.
