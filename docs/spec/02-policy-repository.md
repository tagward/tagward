# Spec 02 · Policy repository format

The policy repository is the portable heart of an organisation's governance. It is
plain YAML validated by a JSON Schema published from the controller's `spec`
module. Nothing in it references our images or charts.

## Layout

```text
tagward.yaml          controller configuration and environments (Spec 01)
intents/*.yaml           one intent per file
rules/propagation.yaml   propagation rules
rules/masks.yaml         mask catalog: name → per-type expression, per backend
subjects/groups.yaml     subject → identity provider group
tests/*.yaml             conformance cases (Spec 08)
```

Every file starts with `spec: 1`. The controller refuses a file whose spec
version it does not know.

## Intent

```yaml
spec: 1
kind: Intent
id: pii-default                      # stable, lowercase, unique across the repo
description: Default handling of direct identifiers.
match:
  tags: [PII.Email, PII.Phone, PII.NationalId]   # any of; classification.tag FQNs from OpenMetadata
  state: Confirmed                                # only value allowed in v1
  scope:                                          # optional; default: everywhere the tag lands
    catalogs: [lakehouse]
sensitive: true                      # enables quarantine of new columns on tables that carry it
subjects:
  - name: privacy-office
    effect: allow
  - name: analysts
    effect: mask
    mask: hash                       # name from rules/masks.yaml
  - name: everyone
    effect: deny
review:
  everyDays: 180                     # tag labels older than this go back to Suggested
  owner: privacy-office
```

Semantics:

- `effect` is one of `allow`, `mask`, `deny`, `filter`.
- When several subjects match a user, deny beats mask beats allow (ADR-009).
- `everyone` is a reserved subject meaning all authenticated users.
- An intent with `effect: filter` carries a `filter` expression using Ranger row
  filter syntax with `${USER}` and `${USER.attr}` macros. Spec 03 explains the
  expansion into per-table policies.

## Row filter intent

```yaml
spec: 1
kind: Intent
id: region-scoping
match:
  tags: [Governance.RegionScoped]
subjects:
  - name: regional-analysts
    effect: filter
    filter: "region = '${USER.region}'"
    requires: [column:region]        # plan fails if the table has no such column
  - name: global-analysts
    effect: allow
```

## Subjects

```yaml
spec: 1
kind: Subjects
subjects:
  privacy-office:     { group: data-privacy-office }
  analysts:           { group: analysts }
  regional-analysts:  { group: analysts-regional }
  table-owner:        { special: owner }        # resolved per asset from OpenMetadata ownership
```

Group names are Keycloak group names as they appear in the token's groups claim.
`plan` fails when a group does not exist in Keycloak.

## Propagation rules

```yaml
spec: 1
kind: PropagationRules
defaults:
  maxDepth: 3
  direction: downstream
  stopAtTags: [Governance.Sanitized, Governance.Public]
  writeAs: { labelType: Propagated, state: Suggested }
rules:
  - tags: [PII.*]
    maxDepth: 5
  - tags: [PII.*]
    when: { edgeKind: aggregate }      # OpenMetadata column lineage with aggregate function, when available
    propagate: false
declassification:
  tag: Governance.Sanitized
  requires: Confirmed                  # a Suggested Sanitized tag does not stop propagation
```

## Mask catalog

```yaml
spec: 1
kind: Masks
masks:
  hash:
    ranger: MASK_HASH
    types: [varchar, char]
  redact:
    ranger: MASK
    types: [varchar, char]
  last4:
    ranger: MASK_SHOW_LAST_4
    types: [varchar, char]
  nullify:
    ranger: MASK_NULL
    types: ["*"]
  year-only:
    ranger: MASK_DATE_SHOW_YEAR
    types: [date, timestamp]
  hmac:
    ranger: CUSTOM
    expression: "to_hex(hmac_sha256(to_utf8(cast({col} as varchar)), from_base64('${TAGWARD_HMAC_KEY}')))"
    types: [varchar, bigint, integer]
```

A mask applied to a column whose type is not in `types` fails the plan with the
column named. This is the type-safety rule Ranger does not give us.

## Tests

Conformance cases; format in Spec 08.

## Environments

`tagward.yaml` lists environments. `plan --env staging` uses staging endpoints.
The daemon runs with one environment. Intent files are environment-independent;
scope by catalog if needed.

## Versioning and compatibility

- `spec: 1` is frozen at M1 release. Additions are backward compatible within 1.
- Breaking changes create `spec: 2`; the controller supports N and N-1.
- The JSON Schema is published at a stable URL and as a Maven artifact.
