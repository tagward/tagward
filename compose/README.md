# Compose

The whole stack on a laptop with one command. Spec 07 is the contract.

## Status

**Not yet verified.** The file and its configuration were written from the
upstream images' documentation and have not been run end to end. Verification is
milestone M0; each step below is an issue labelled `milestone:M0` in this repository.

What M0 must prove, in order:

1. `docker compose up -d` brings every service to healthy.
2. Ranger admin runs on PostgreSQL with no Solr container anywhere.
3. A hand-written Ranger policy on the `trino-demo` service denies a query on `tpch.tiny.customer` for user `alice`.
4. The denied and an allowed query both appear in Ranger admin's audit screen with OpenSearch as the store.
5. OpenMetadata starts against the same PostgreSQL and OpenSearch.
6. Keycloak imports the `data` realm with its groups, users and clients.

Expected trouble, so nobody is surprised: the upstream `apache/ranger` image is a
developer image whose setup script generates its own `install.properties`. The
mounted override may not be honoured, and `audit_store=opensearch` may not be a
value the 2.8 setup understands. Both outcomes feed straight into
`images/ranger-admin`, which is why ADR-008 exists.

## Run

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

| Service | URL | Credentials |
| --- | --- | --- |
| Trino | <http://localhost:8080> | header `X-Trino-User`, no password in M0 |
| Ranger admin | <http://localhost:6080> | `admin` / value of `RANGER_ADMIN_PASSWORD` |
| OpenMetadata | <http://localhost:8585> | `admin@open-metadata.org` / `admin` |
| Keycloak | <http://localhost:8180> | `admin` / value of `KEYCLOAK_ADMIN_PASSWORD` |

## Profiles

- `default`: everything above.
- `demo`: adds a sample dataset with PII columns and mounts `policy-template-example/`. Not written yet.
- `ci`: `default` without published ports, used by the version-matrix job. Not written yet.

## Layout

```text
docker-compose.yaml
.env.example                       image tags mirror versions.yaml
config/postgres/init.sql           three databases, three roles
config/opensearch/*.json           ranger_audits index template (Spec 05)
config/keycloak/realm-data.json    realm, groups, demo users, trino and conformance clients (Spec 04)
config/ranger/install.properties   PostgreSQL + OpenSearch overrides for the upstream image
config/trino/*.properties          coordinator, Ranger access control, tpch catalog
config/trino/ranger/*.xml          plugin security and audit configuration (Spec 05)
```
