# Compose

The whole stack on a laptop with one command. Spec 07 is the contract.

## Status

**Written from the upstream sources, not yet run end to end.** Every image tag was
checked against its registry, the compose file passes `docker compose config`, and
the Ranger and Trino configuration follows what the pinned versions' own scripts and
`pom.xml` files say. What remains is the run, tracked as milestone M0 in issues
labelled `milestone:M0`.

Facts established by reading the sources, so nobody rediscovers them:

| Fact | Consequence here |
| --- | --- |
| Ranger admin accepts `audit_store=opensearch` only from 2.9.0 | `RANGER_VERSION=2.9.0` |
| The upstream image's entrypoint runs `setup.sh` against `/opt/ranger/admin/install.properties`, then creates dev services for hosts that do not exist | our `install.properties` is mounted there and a minimal entrypoint replaces the upstream one |
| Trino 483 bundles Ranger 2.8.0 with no OpenSearch audit destination | the plugin writes JSON files through the HDFS destination on `file://`, Fluent Bit ships them (ADR-010) |
| File events use `AuthzAuditEvent` names and `yyyy-MM-dd HH:mm:ss.SSS` dates; the index format renames three fields | Fluent Bit renames `cluster_name`, `zone_name`, `policy_version`; the index template accepts both date formats |

What M0 must prove, in order:

1. `docker compose up -d` brings every service to healthy.
2. Ranger admin 2.9.0 runs on PostgreSQL with `ranger.audit.source.type=opensearch` and no Solr container anywhere.
3. A hand-written Ranger policy on the `trino-demo` service denies a query on `tpch.tiny.customer` for user `alice`.
4. The denied and an allowed query appear as files under the `ranger-audit` volume, then in the `ranger_audits` index, then in Ranger admin's audit screen.
5. OpenMetadata starts against the same PostgreSQL and OpenSearch.
6. Keycloak imports the `data` realm with its groups, users and clients.

Open question for the run: whether the published `apache/ranger:2.9.0` tag is the
PostgreSQL flavour of the upstream multi-stage build. If it is not, the PostgreSQL
driver is missing at `/usr/share/java/postgresql.jar` and `setup.sh` fails on the
first line; the fix is our own image, which ADR-008 plans anyway.

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
| Fluent Bit health | <http://localhost:2020/api/v1/health> | none, inside the compose network only |

Follow the audit path by hand:

```bash
docker compose exec trino trino --user alice --execute "SELECT name FROM tpch.tiny.customer LIMIT 1"
docker compose exec trino sh -c 'find /var/log/ranger/audit -name "*.log" -exec tail -n 1 {} \;'
curl -s "http://localhost:9200/ranger_audits/_search?q=reqUser:alice&pretty"
```

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
config/ranger/install.properties   PostgreSQL store, OpenSearch audit source, for the upstream image
config/ranger/entrypoint.sh        setup once, start admin, no dev services
config/trino/*.properties          coordinator, Ranger access control, tpch catalog
config/trino/ranger/*.xml          plugin security and file audit configuration (Spec 05, ADR-010)
config/fluent-bit/*.conf           tail audit files, rename fields, write to OpenSearch
```
