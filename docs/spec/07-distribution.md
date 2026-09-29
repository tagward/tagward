# Spec 07 · Distribution

Deployment must be a breeze: one Helm release for a cluster, one compose file for
a laptop. Everything is driven by `versions.yaml`.

## Umbrella chart `charts/tagward`

Dependencies, each toggled by `enabled` so an organisation can bring its own:

| Dependency | Source | Default |
| --- | --- | --- |
| `trino` | upstream chart | enabled |
| `openmetadata` | upstream chart | enabled |
| `opensearch` | upstream chart | enabled |
| `keycloak` | upstream operator CR or upstream chart | enabled |
| `postgresql` | CloudNativePG cluster manifests | enabled |
| `ranger` | `charts/ranger`, ours | enabled |
| `controller` | `charts/controller`, ours | enabled |
| `fluent-bit` | upstream chart | disabled, enabled by `audit.path=fallback` |
| `opensearch-dashboards` | upstream chart | disabled |

Values contract, top level:

```yaml
global:
  domain: data.example.internal
  tls: { issuer: letsencrypt-internal }
identity:
  realm: data
  adminGroup: data-platform-admins
policyRepo:
  url: https://github.com/acme/governance-policies
  ref: main
  secretRef: policy-repo-credentials
audit:
  path: primary            # primary | fallback
  retentionDays: 400
trino:
  catalogs: {}             # passed through to the Trino chart
  rangerPlugin:
    pollIntervalMs: 30000
```

Everything else has a working default. A first install needs the domain and the
policy repository URL, nothing more.

## Bootstrap sequence

Helm hooks run in order, all idempotent, all executed by `tagward bootstrap`:

1. PostgreSQL databases and roles: `openmetadata`, `ranger`, `keycloak`.
2. Keycloak realm import, clients, groups, mappers.
3. OpenSearch index templates: OpenMetadata's own, `ranger_audits`.
4. Ranger schema, then `trino` service and `tag` service, linked, with the
   controller service account.
5. OpenMetadata: classification `Governance` with `Public`, `Sanitized`,
   `RegionScoped`; custom properties from Spec 01; bot and token; webhook to the
   controller; Trino service and ingestion pipelines.
6. Controller starts, first full reconcile.

## Trino configuration produced by the chart

- `access-control.properties`: `access-control.name=ranger`, security and audit
  xml paths, service names from values.
- `ranger-trino-security.xml`: admin URL, service name, poll interval, cache dir on emptyDir.
- `ranger-trino-audit.xml`: Spec 05.
- OAuth2 authentication against Keycloak, `groups` claim mapping.
- Optional `http-event-listener` posting query-completed events to the
  controller's events sink for lineage and usage (M3).

## Compose `compose/docker-compose.yaml`

Same images, same versions, same bootstrap command. Profiles:

- `default`: everything, single node, self-signed TLS, one PostgreSQL with three
  databases, one OpenSearch node, Keycloak in dev mode with the realm import.
- `demo`: `default` plus a sample Iceberg dataset with PII columns and a demo
  policy repository mounted from `policy-template-example/`.
- `ci`: `default` without UIs exposed, used by the conformance run.

Target: `docker compose --profile demo up` to a working, enforced demo in under
ten minutes on a laptop with 16 GB.

## Upgrades

- `versions.yaml` is the only place a version changes. A pull request that bumps
  it runs the compose `ci` profile and the conformance suite.
- Chart version is the distribution version. Component versions appear in chart
  values and in the release notes generated from the diff of `versions.yaml`.
- Ranger schema upgrades run in the init job; OpenMetadata migrations run through
  its own chart hook; the controller has no schema.
- A distribution upgrade never changes managed Ranger objects unless the
  controller version changed the compiler, in which case the release notes
  say so and the first reconcile shows the plan.

## Release process

1. Bump `versions.yaml`, mark entries `verified` once CI passes.
2. Tag `vX.Y.Z`. CI publishes the umbrella chart, our charts, our images, SBOMs.
3. Release notes: component version diff, ADRs accepted since last release, conformance results.

## CI in this repository

- Lint charts, render templates against a kind cluster, `helm install --dry-run`.
- Build our images, multi-arch, SBOM, license gate.
- Compose `ci` profile up, `tagward bootstrap`, `tagward apply` with the example policy
  repository, `tagward test`, tear down. This is the version-matrix test.
- Docs: link check, mermaid render check, spec numbering check.
