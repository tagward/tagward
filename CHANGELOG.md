# Changelog

All notable changes to the Tagward distribution are recorded here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- ADR-010: plugin audit reaches OpenSearch through files and Fluent Bit, after
  verifying that Trino 483 bundles Ranger 2.8.0 without an OpenSearch destination
  and that Ranger admin reads audits from OpenSearch only from 2.9.0.
- Compose stack for M0 with Ranger 2.9.0, a minimal Ranger entrypoint, a Fluent Bit
  audit sidecar, and image tags verified against their registries.
- Documentation site on GitHub Pages.
- Vision, architecture, bill of materials and repository layout.
- Nine architecture decision records, ADR-001 to ADR-009.
- Nine specifications: controller, policy repository format, Ranger compilation,
  identity, audit, images, distribution, conformance and drift, security model.
- `versions.yaml` as the single source of pinned versions.
- Roadmap with acceptance criteria for M0 to M4.
- Example policy repository.
- Community files: license, notice, code of conduct, contributing guide, security
  policy, governance, maintainers.
