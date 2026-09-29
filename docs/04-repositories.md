# 04 · Repositories

## Three repositories, one master

| Repository | Contents | Nature | Release cadence |
| --- | --- | --- | --- |
| **distribution** (this one, the master) | docs, ADRs, specs, roadmap, `versions.yaml`, umbrella chart, our charts, our images, compose, example policy repo | packaging + documentation | the product release |
| **controller** | the Java code, its integration tests, its own chart values defaults | code | its own semver, consumed by `versions.yaml` |
| **policy-template** | what a user forks: intents, rules, subjects, tests, one CI workflow | configuration + CI | tracks the spec version |

## Why the distribution repository is the master

- A release of the product is a release of the distribution. The controller is a
  component with a version pinned in `versions.yaml`, like Trino or Ranger.
- Newcomers land on one README, not on a Java project.
- Specifications, ADRs and the roadmap describe the whole system, so they belong
  where the whole system is assembled.
- The version matrix must be tested as a whole; the distribution's CI is the
  place where the compose stack and the conformance suite run against pinned versions.

The controller stays separate because it has a different build, a different test
harness, a much higher change rate, and a different contributor profile. The
policy template stays separate because it must be forkable with nothing of ours in it.

## Layout of this repository

```text
.
├── README.md
├── ROADMAP.md
├── versions.yaml                 # single source of truth for pins
├── docs/
│   ├── 01-vision-and-principles.md
│   ├── 02-architecture.md
│   ├── 03-bill-of-materials.md
│   ├── 04-repositories.md
│   ├── glossary.md
│   ├── adr/                      # one decision per file, never edited after acceptance, superseded instead
│   └── spec/                     # normative specifications, numbered
├── charts/
│   ├── tagward/                  # umbrella chart; upstream charts as dependencies
│   ├── ranger/                   # our chart
│   └── controller/               # our chart
├── images/
│   ├── ranger-admin/
│   └── ranger-usersync/
├── compose/
│   ├── docker-compose.yaml
│   └── config/                   # Trino access control, Keycloak realm, OpenSearch templates
└── policy-template-example/      # a rendered example of a user's policy repository
```

## Layout of the controller repository

```text
controller/
├── pom.xml                       # Java 21, Maven multi-module
├── spec/                         # JSON Schema for intents, rules, subjects, tests; published artifact
├── model/                        # canonical model: assets, bindings, subjects, tags, intents
├── client-openmetadata/          # REST client: entities, tags, lineage, events, custom properties
├── client-ranger/                # REST client: services, policies, tag service objects
├── client-keycloak/              # admin API: groups, attributes
├── propagation/                  # lineage closure, stop rules, declassification
├── compiler/                     # Confirmed tags × intents → plan of Ranger objects
├── applier/                      # plan → Ranger, ownership marks, orphan removal
├── drift/                        # intent vs Ranger vs observed
├── conformance/                  # test runner over Trino JDBC with synthetic users
├── bootstrap/                    # create OpenMetadata classification, custom properties, webhook, Ranger services, Keycloak realm objects
├── cli/                          # picocli: plan, apply, test, drift, bootstrap, propagate, serve
├── daemon/                       # reconcile loop, webhook receiver, status endpoint
└── it/                           # Testcontainers: whole stack, end to end
```

## Layout of the policy template repository

```text
policy-template/
├── README.md
├── tagward.yaml               # spec version, environments, controller image pin
├── intents/                      # one file per intent
├── rules/
│   ├── propagation.yaml
│   └── masks.yaml
├── subjects/
│   └── groups.yaml               # subject name → Keycloak group
├── tests/                        # conformance cases
└── .github/workflows/
    ├── plan.yaml                 # on pull request: validate schema, plan, run tests against staging
    └── apply.yaml                # on merge: apply to production, or let the daemon pick it up
```

## Naming

Repositories, all under the `tagward` GitHub organisation:
`tagward/tagward`, `tagward/tagward-controller`, `tagward/tagward-policy-template`.
