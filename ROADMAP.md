# Roadmap

Each milestone has acceptance criteria that are tests, not descriptions.

## M0 · Foundations (now)

- [x] Vision, architecture, decisions, specifications written
- [x] Name chosen, GitHub organisation and three repositories created
- [x] Three repositories created, this one as master
- [x] Documentation site published from this repository with GitHub Pages
- [x] Controller validates policy repositories (`tagward validate`), image on GHCR
- [x] Compose `default` profile written, verification pending (issues labelled `milestone:M0`)
- [ ] `versions.yaml` first pins
- [ ] Compose `default` profile brings up PostgreSQL, OpenSearch, Keycloak,
      OpenMetadata, Ranger admin (our image), Trino with the Ranger plugin
- [ ] **Verification:** a hand-written Ranger policy denies a Trino query, and both
      the denied and an allowed query appear in Ranger admin's audit screen with
      OpenSearch as the store, no Solr anywhere

## M1 · A tag changes a query

- [ ] Controller: `validate`, `plan`, `apply`, `bootstrap`, `test`
- [ ] Spec 02 JSON Schema published
- [ ] Table deny and column masking from Confirmed PII tags
- [ ] Quarantine of unclassified new columns on sensitive tables
- [ ] Status custom properties written to OpenMetadata
- [ ] Umbrella chart installs on kind with two values set: domain and policy repository
- [ ] Compose `demo` profile with sample dataset and example policy repository
- [ ] **Acceptance:** confirm a `PII.Email` tag in OpenMetadata, and within one minute
      `tagward test` shows analysts receiving hashed values and `everyone` denied,
      with the asset showing `tw_enforcement=enforced`

## M2 · Atlas parity without Atlas

- [ ] Propagation engine over column lineage, Propagated + Suggested labels
- [ ] Declassification tag, depth and stop rules
- [ ] Review periods: labels back to Suggested, enforcement kept
- [ ] Daemon mode: webhook receiver, debounce, full resync, leader election
- [ ] Ranger images hardened: non-root, read-only root, probes, multi-arch
- [ ] **Acceptance:** tag a source column, see the derived column suggested within
      a reconcile, confirm it, see it enforced; reject it, see nothing enforced

## M3 · Scope and evidence

- [ ] Row filters from user attributes, per-table expansion
- [ ] Usersync or controller-pushed attributes from Keycloak, decided by ADR
- [ ] Drift detection classes A to F, exit codes, OpenMetadata announcements
- [ ] Audit feedback: `tw_recent_access` on assets
- [ ] Optional Trino event listener sink for query-completed events into OpenMetadata lineage and usage
- [ ] OpenSearch Dashboards export
- [ ] **Acceptance:** an EU analyst sees EU rows only; a hand-written permissive
      Ranger policy on a sensitive table is reported as drift within one interval

## M4 · Second targets

- [ ] OPA as second compiler target, same intents, purpose-based rules
- [ ] Table grants into Polaris or Lakekeeper for the first side door
- [ ] Gravitino as optional asset source
- [ ] Atlas read-only adapter for installed bases
- [ ] **Acceptance:** the same policy repository applied to Ranger and to OPA
      passes the same conformance suite

## Not planned

- Our own user interface
- Enforcement for engines other than Trino beyond catalog-level grants
- Multi-tenant SaaS packaging
