# Tagward

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Docs](https://github.com/tagward/tagward/actions/workflows/docs.yml/badge.svg)](https://github.com/tagward/tagward/actions/workflows/docs.yml)
[![Pages](https://github.com/tagward/tagward/actions/workflows/pages.yml/badge.svg)](https://tagward.github.io/tagward/)
[![Status](https://img.shields.io/badge/status-first%20iteration-orange.svg)](ROADMAP.md)

**A tag becomes a ward.** Tagward is an all open-source, fully packaged data
governance stack: a classification confirmed in OpenMetadata becomes an enforced
policy in Trino, through Apache Ranger, with one controller in the middle, a test
that proves it, and no commercial license anywhere.

```text
OpenMetadata (classify, approve)  ──►  Tagward controller (compile, reconcile)  ──►  Ranger (policy)  ──►  Trino (enforce)
        ▲                                             │                                                    │
        └──────── status, propagated tags ◄───────────┘                       audit ─► OpenSearch ◄────────┘
```

> **Documentation site: [tagward.github.io/tagward](https://tagward.github.io/tagward/)**
>
> **Status: first iteration.** The architecture, decisions and specifications are
> written and the controller validates policy repositories. The compose stack that
> proves the enforcement and audit path without Solr is being verified, tracked in
> the [M0 issues](https://github.com/tagward/tagward/issues?q=is%3Aissue+label%3Amilestone%3AM0). See [ROADMAP.md](ROADMAP.md).

## Why

Every organisation running Trino on a lakehouse ends up with a catalog where people
describe data, a policy engine where administrators write rules, and a query engine
where access happens. The three are kept consistent by hand, and nobody can prove
that a column tagged "PII" is actually masked. Commercial products sell this loop.
Tagward is the open-source one.

## What is in this repository

This is the **master repository**: documentation, decisions, specifications, the
tested version matrix, the Helm charts, the container images we build ourselves and
the laptop demo. Releases of Tagward are releases of this repository.

| Area | Where |
| --- | --- |
| Vision, architecture, bill of materials, repositories | [`docs/`](docs/) |
| Architecture decision records | [`docs/adr/`](docs/adr/) |
| Specifications, precise enough to build from | [`docs/spec/`](docs/spec/) |
| Tested version matrix, the only place a version is pinned | [`versions.yaml`](versions.yaml) |
| Roadmap with acceptance criteria | [`ROADMAP.md`](ROADMAP.md) |
| Helm charts: umbrella, Ranger, controller | [`charts/`](charts/) |
| Container images we build: Ranger admin and usersync | [`images/`](images/) |
| One-command laptop demo, being verified | [`compose/`](compose/) |
| Documentation site sources, MkDocs Material | [`mkdocs.yml`](mkdocs.yml), [`docs/`](docs/) |
| A rendered example of a policy repository | [`policy-template-example/`](policy-template-example/) |

Two sibling repositories complete the project:

- [`tagward/tagward-controller`](https://github.com/tagward/tagward-controller): the only component with code of our own. Java. Compiles OpenMetadata tags and git intents into Ranger policies and keeps them reconciled.
- [`tagward/tagward-policy-template`](https://github.com/tagward/tagward-policy-template): the repository an organisation forks. Intents, propagation rules, subject mappings, conformance tests, one CI workflow.

## Reading order

1. [Vision and principles](docs/01-vision-and-principles.md)
2. [Architecture](docs/02-architecture.md)
3. [Bill of materials](docs/03-bill-of-materials.md)
4. [Repositories](docs/04-repositories.md)
5. [Specifications](docs/spec/README.md), in numeric order
6. [Roadmap](ROADMAP.md)

## Non-negotiables

- Every component is under Apache 2.0, PostgreSQL, or an equally permissive license. A license gate runs in CI.
- Nothing is enforced before a human confirms it.
- Each fact has exactly one system of record. Nothing is synchronized in both directions.
- Deployment is one Helm release or one compose file. If it needs a runbook, it is a bug.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). Decisions are made through ADRs, see
[GOVERNANCE.md](GOVERNANCE.md). Security reports go through
[SECURITY.md](SECURITY.md). Everyone is expected to follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

## License

Apache License 2.0. Copyright The Tagward Authors.

Apache, Apache Ranger and Trino are trademarks of their respective owners. Tagward
is not affiliated with or endorsed by the Apache Software Foundation, the Trino
Software Foundation or Collate.
