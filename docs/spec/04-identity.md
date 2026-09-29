# Spec 04 · Identity

One identity provider, one group name space, three consumers.

## Keycloak realm

Realm `data`, provisioned from a realm export in the distribution and finished by
`tagward bootstrap`.

| Client | Type | Used by |
| --- | --- | --- |
| `openmetadata` | OIDC, confidential | OpenMetadata SSO |
| `trino` | OIDC, confidential | Trino OAuth2 authentication |
| `ranger` | OIDC via SAML/OIDC bridge or reverse proxy | Ranger admin login |
| `tagward-controller` | OIDC, service account | controller reads groups and attributes |
| `conformance` | OIDC, direct grant, confidential | synthetic test users only, disabled outside test |

Mappers:

- `groups` claim on every access token: group names, flat, no path prefix.
- User attributes needed by row filters (`region`, `department`, ...) as claims
  and as LDAP-visible attributes when usersync is LDAP-based.

Groups are flat. Nested groups exist in Keycloak but are exported flattened, so
a name is a name everywhere.

## Trino

- Authentication: OAuth2 against Keycloak, `groups` claim mapped to Trino groups
  through `http-server.authentication.oauth2.groups-field=groups`.
- Access control: Ranger plugin. It passes the identity user and groups on each
  request, so policy evaluation does not depend on Ranger usersync.
- Impersonation from BI tools: service account with `impersonation` rule limited to
  users of a group; Ranger sees the impersonated user.
- Views: the conformance suite flags `SECURITY DEFINER` views over tables that
  carry sensitive tags (Spec 09).

## Ranger

- Admin UI login through Keycloak.
- Usersync: needed only for the UI autocompletion and for user attributes used
  in row filter macros. Source is LDAP; when Keycloak is the only directory, the
  distribution runs a minimal LDAP facade or uses Keycloak's user federation
  against an existing directory. The controller can alternatively push users,
  groups and attributes through Ranger's REST API from Keycloak. M3 decides which.
- Ranger service account for the controller: role `ROLE_SYS_ADMIN` scoped by
  service where Ranger allows, otherwise admin with the ownership rules of Spec 03 as the guard.

## OpenMetadata

- SSO through Keycloak.
- Bot `tagward-controller` with a token; policy limited to tag operations and
  custom property updates on data assets.

## Controller validation

- Every subject group must exist in Keycloak. Unknown group fails the plan.
- Every `${USER.<attr>}` used in a filter must be a known user attribute in the realm.
- Group name casing is compared exactly. The controller warns on two groups that
  differ only in case.

## Synthetic users for conformance

Created by `bootstrap` in the `data` realm, disabled by default, enabled by the test
runner for the duration of a run, with membership matching each subject used in
`tests/`. Their credentials come from `TAGWARD_TEST_USERS_SECRET`, never from the repo.
