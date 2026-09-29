# ADR-008 · Own Ranger images and chart, built from Apache release artifacts

Status: accepted

## Context

The official `apache/ranger` images come from the project's developer docker
setup: configuration written by setup scripts at container start, companion
images for the database, ZooKeeper and Solr assumed, processes running as root,
no probes designed for Kubernetes. Community Helm charts wrap those images and
depend on Bitnami PostgreSQL, which is no longer freely maintained.

## Decision

We build and maintain our own `ranger-admin` and `ranger-usersync` images from the
Apache Ranger release tarball, and our own Helm chart. The images are
configuration-driven, non-root, PostgreSQL-only, OpenSearch for audit, with no
Solr or ZooKeeper, and expose health endpoints for probes. Specification in
`docs/spec/06-images.md`.

## Consequences

- We own security updates and version bumps of the Ranger image. `versions.yaml`
  tracks the upstream release we build from.
- The official image remains the reference for behavior; every divergence is
  documented in the image README.
- The same approach is available for any other component whose upstream
  packaging regresses; each such case gets its own ADR.
