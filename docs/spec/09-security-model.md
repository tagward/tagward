# Spec 09 · Security model

What the stack protects, what it does not, and what we do about the gap.

## Trust boundaries

- **Enforcement point:** the Trino coordinator with the Ranger plugin. Every
  query through Trino is subject to policy. Nothing else is.
- **Policy authority:** Ranger admin. Its API credentials are the crown jewels of
  the stack. The controller's account is the only automated writer; humans keep
  admin access through Keycloak SSO with MFA recommended.
- **Intent authority:** the policy repository. Branch protection and required
  review on the default branch are part of the installation checklist.
- **Classification authority:** OpenMetadata stewards. Their roles are scoped in
  OpenMetadata; the classifier bot can only suggest.

## Covered in Trino

| Path | Handling |
| --- | --- |
| Table and column access | Ranger access policies |
| Sensitive column read | masking policies |
| Row scoping | row filter policies |
| `SELECT *` | masks apply to each column |
| CTAS or INSERT from masked columns | masked values are what gets written; the new table has no tags until propagation suggests them and a steward confirms |
| Views with `SECURITY INVOKER` | policies evaluated for the querying user |
| Views with `SECURITY DEFINER` over sensitive tables | not protected by policy on the underlying table; flagged by drift class C-like rule, denied by a default managed policy on `CREATE VIEW` where Ranger's Trino service allows, otherwise reported |
| Iceberg metadata tables (`$files`, `$snapshots`, ...) | denied to `everyone` except owner subject by a default managed policy on sensitive tables |
| `information_schema` and `system` catalogs | Ranger policies apply; columns names are visible to users with any access to the table, which is accepted |
| Query text in audit | stored, not indexed, shorter retention (Spec 05) |
| Table functions, procedures | unmanaged; Ranger default deny unless a human writes a policy |

## Not covered, by design, and made visible

| Side door | Visibility | Later |
| --- | --- | --- |
| Spark, Flink, other engines reading the same tables | OpenLineage into OpenMetadata shows the reads; the asset shows `side doors: yes` | table grants pushed to the Iceberg REST catalog (Polaris or Lakekeeper), M4 |
| Direct object-store access | bucket access logs are outside the stack | bucket policy generation is out of scope |
| Trino clusters not registered in `tagward.yaml` | none | registration is the only fix |

## Secrets

- Never in the policy repository. Environment and Kubernetes secrets only.
- HMAC keys for deterministic masking are per environment and rotated with a
  planned re-hash; the mask catalog names the key by reference.
- Synthetic test users are disabled except during a run.

## Threats considered

- **Steward error:** a wrong Confirmed tag denies access. Reversible in the UI,
  propagates within a minute. Acceptable and visible.
- **Classifier error:** cannot enforce anything, by construction.
- **Compromised controller credentials:** can write any Ranger policy. Mitigation:
  managed objects are labelled, every apply is logged with a plan, and drift class
  B catches unlabelled changes. Ranger admin audit logs the controller's writes.
- **Rogue Ranger admin:** can grant access by hand. Drift class C reports it within
  a reconcile interval. We do not auto-revert unmanaged policies, on purpose.
- **Missed webhook:** full resync interval bounds the exposure.
- **Group renamed in Keycloak:** plan fails on unknown subject; nothing changes
  in Ranger until the mapping is fixed. Existing policies keep the old name and
  therefore match no one: fail-safe.
