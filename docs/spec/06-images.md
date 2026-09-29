# Spec 06 · Images

We build only what upstream does not package well. Today that is Ranger. Every
image we build follows the same rules.

## Common rules

- Built from the upstream **release** artifact, never from a git snapshot. The
  version in `versions.yaml` is the upstream release.
- Multi-arch: linux/amd64, linux/arm64.
- Non-root user, read-only root filesystem where the software allows, writable
  volumes declared.
- All configuration from environment variables and mounted files. No setup
  script that writes configuration at container start unless it is our own,
  idempotent, and reads only from environment.
- Health endpoints documented; the chart's probes use them.
- SBOM published with the image; license gate in CI.
- Base image: a distroless or a minimal Debian-slim Java runtime, Temurin 17 or
  21 as the software requires. No Bitnami base.
- Tags: `<upstream version>-<our build>`, for example `2.8.0-3`, plus a moving
  `<upstream version>` tag.
- A `README.md` per image listing every divergence from upstream behavior.

## ranger-admin

Source: `apache-ranger-<version>.tar.gz` built with the admin profile, or the
release's `ranger-<version>-admin.tar.gz` when the project publishes binaries.

Requirements:

- PostgreSQL only. The JDBC driver is included. Schema creation runs as an init
  container using Ranger's own `db_setup.py`, executed once, idempotent.
- Audit source: OpenSearch. No Solr client configuration present in the image.
- Authentication: OIDC through a fronting proxy header or Ranger's own SSO
  support, decided in M1 after testing what Ranger 2.8 supports natively.
- `ranger-admin-site.xml` and `install.properties` are rendered by our entrypoint
  from environment variables named `RANGER_ADMIN_<PROPERTY>`.
- Ports: 6080 http, 6182 https. Health: `GET /service/public/v2/api/servicedef/name/trino` with a
  service account, or the simpler `GET /login.jsp` for liveness.
- Plugin download endpoint reachable by Trino inside the cluster.
- Log to stdout.
- Optional: carry the RANGER-5772 OpenSearch client patch if not released in the pinned version. Documented.

## ranger-usersync

- Sources: LDAP, or file for tests. Unix sync disabled.
- Configured from environment, same convention.
- Only deployed when the environment uses LDAP-based attributes; the chart makes it optional.

## Init job image

The Ranger init job that creates the `trino` service, the `tag` service and the
link between them runs the controller image with `tagward bootstrap --only ranger`.
No separate image.

## Images we do not build

Trino, OpenMetadata, Keycloak, OpenSearch, PostgreSQL, Fluent Bit. Their
configuration is mounted. If one regresses, a new ADR and a new directory here.

## Controller image

Built in the controller repository from its release, distroless Java 21, non-root,
`tagward` as entrypoint. Referenced here by `versions.yaml`.
