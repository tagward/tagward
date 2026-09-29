# Spec 01 · Controller

## Purpose

The controller turns Confirmed classifications in OpenMetadata and intents in a
git repository into managed Ranger objects, keeps them reconciled, propagates
tags along lineage as suggestions, verifies enforcement against Trino, and
writes status back to the catalog. It is the only component in the stack with
code of our own.

## Modes

One executable, two ways to run it.

| Mode | Invocation | Used by |
| --- | --- | --- |
| CLI | `tagward <command>` | CI in the policy repository, operators |
| Daemon | `tagward serve` | the Helm chart, as a Deployment with one replica and leader election optional |

The same code path produces a plan in both modes. Whatever CI validated is what
the daemon applies.

## Commands

| Command | Reads | Writes | Exit code |
| --- | --- | --- | --- |
| `validate` | policy repo | nothing | non-zero on schema or reference error |
| `plan` | policy repo, OpenMetadata, Keycloak, Ranger | plan file, human diff | non-zero on validation failure; zero with empty plan |
| `apply` | plan or same as plan | Ranger, OpenMetadata status | non-zero if any object failed; partial applies are reported object by object |
| `propagate` | OpenMetadata lineage and tags, rules | OpenMetadata Propagated + Suggested labels | |
| `test` | policy repo `tests/`, Trino, Keycloak | report | non-zero on any failed case |
| `drift` | policy repo, OpenMetadata, Ranger, optionally Trino | report | non-zero on drift, class-dependent |
| `bootstrap` | `tagward.yaml` | OpenMetadata, Ranger, Keycloak initial objects | idempotent |
| `serve` | all | all | runs until stopped |

## Inputs

- **Policy repository.** A local path or a git URL with ref. Layout per Spec 02.
- **OpenMetadata.** REST API with a bot token. Entities, tag labels, lineage,
  change events, custom properties.
- **Ranger admin.** REST API with a service account. Services, resource policies,
  tag service objects (tag defs, tags, service resources, tag-resource maps).
- **Keycloak.** Admin API, read-only client. Groups and, for row filters, user attributes.
- **Trino.** JDBC, used only by `test` and by observed-behavior drift, with
  synthetic users authenticated through Keycloak.

## Canonical model

```text
Asset        id (OpenMetadata id), type (table | column), fqn, owner subject, parent
Binding      asset → engine, catalog, schema, table, column     (Trino: lowercase)
Tag          fqn (Classification.Tag), attributes from intents
TagLabel     asset, tag, labelType, state, source, appliedAt
Subject      name → identity provider group
Intent       match, subjects with effect, transform, options     (Spec 02)
Rule         propagation and mask rules                           (Spec 02)
PlanItem     operation (create | update | delete), Ranger object type, id, before, after, reason
```

Identity of an asset is OpenMetadata's entity id, never its name. Renames are
handled by the binding changing under the same asset.

## Reconcile loop (daemon)

```text
on start:           full reconcile
on webhook event:   debounce 5 s, incremental reconcile for the affected assets
every N minutes:    full reconcile (default 10)
reconcile:
  1. load policy repo at configured ref
  2. validate                      → on failure: report, keep last good state, do not apply
  3. read Confirmed labels (incremental: only changed assets)
  4. read Keycloak groups          → unknown subject: fail plan
  5. propagate                     → write Suggested labels
  6. compile → plan
  7. apply plan to Ranger          → per-object result
  8. read back Ranger state        → drift class A (intent vs Ranger)
  9. write status to OpenMetadata  → custom properties per asset
 10. emit metrics and a status document
```

Full reconcile must be idempotent. Running it twice with no input change produces
an empty plan.

## Ownership of Ranger objects

Every object the controller writes carries an ownership marker:

- Policies: `policyLabels` contains `managed-by=tagward` and
  `intent=<intent id>`; `description` carries the source (tag, intent, asset) in one line.
- Tag definitions and tags: name prefixed with the configured namespace, default `tw:`.
- Service resources and tag-resource maps: derived from managed tags only.

Rules:

- The controller never modifies or deletes an object without its marker.
- A managed object whose intent, tag or asset no longer exists is an orphan and
  is deleted on apply, listed in the plan first.
- If a human edits a managed object, the next plan shows the diff and apply
  restores it. The edit is reported as drift class B.

## Status written to OpenMetadata

Custom properties on `table` and `column` entities, created by `bootstrap`:

| Property | Type | Meaning |
| --- | --- | --- |
| `tw_enforcement` | enum: none, quarantined, enforced, drift, error | current state |
| `tw_policies` | string | managed policy names, comma separated |
| `tw_enforced_since` | timestamp | first apply that covered the asset |
| `tw_last_reconcile` | timestamp | |
| `tw_drift` | string | short drift description or empty |
| `tw_recent_access` | string | count of audited sensitive accesses in the last 7 days, from Spec 05 |

The controller writes these and nothing else on the asset, except Propagated labels.

## Observability

- Prometheus metrics: reconcile duration, plan size by operation, apply failures,
  orphans removed, drift by class, propagation writes, webhook lag.
- Structured JSON logs. Every plan item logged with its reason.
- `/healthz`, `/readyz`, `/status` (last reconcile summary as JSON).

## Configuration

One file, `tagward.yaml`, in the policy repository, plus secrets from environment:

```yaml
spec: 1
controller:
  namespace: tw            # prefix for managed Ranger tag objects
  resyncMinutes: 10
  environments:
    prod:
      openmetadata: https://om.example.internal
      ranger: https://ranger.example.internal
      rangerService: trino-prod        # Ranger service name for this Trino
      rangerTagService: trino-prod-tags
      trino: jdbc:trino://trino.example.internal:443
      keycloak: https://kc.example.internal/realms/data
      trinoCluster: prod                # cluster name in Ranger policies
defaults:
  quarantineNewColumns: true
  expiryKeepsEnforcing: true
```

Secrets: `TAGWARD_OM_TOKEN`, `TAGWARD_RANGER_USER`, `TAGWARD_RANGER_PASSWORD`,
`TAGWARD_KEYCLOAK_CLIENT_ID`, `TAGWARD_KEYCLOAK_CLIENT_SECRET`, `TAGWARD_TEST_USERS_SECRET`.

## Non-functional requirements

- A plan for 100 000 columns with 5 000 Confirmed labels completes in under two minutes.
- The daemon survives OpenMetadata, Ranger or Keycloak being down: it reports, keeps
  the last good state, and retries with backoff. It never applies a partial plan
  built on a failed read.
- All writes to Ranger are batched where the API allows (tag import endpoint).
- No state on disk except a cache directory that can be deleted at any time.
