# Compose

Laptop and CI deployment of the whole stack. Profiles `default`, `demo`, `ci`.
Spec 07 describes the contract; `config/` will hold Trino access control files,
the Keycloak realm export and the OpenSearch audit index template (Spec 05).

Target: `docker compose --profile demo up` to an enforced demo in under ten minutes.
