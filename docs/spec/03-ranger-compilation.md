# Spec 03 · Ranger compilation rules

How Confirmed tag labels and intents become Ranger objects, and how the applier
keeps them reconciled.

## Ranger objects we manage

| Ranger object | Service | Derived from |
| --- | --- | --- |
| Tag definition (`tagdef`) | tag service | every tag referenced by an intent, name `tw:PII.Email` |
| Tag (`tag`) | tag service | one per tag definition, attributes from intent (review owner, intent id) |
| Service resource | tag service | one per Confirmed label target: column or table binding |
| Tag-resource map | tag service | label → tag on resource |
| Tag-based access policy | tag service, policyType access | intent subjects with allow/deny |
| Tag-based masking policy | tag service, policyType dataMask | intent subjects with mask |
| Resource-based row filter policy | trino service, policyType rowFilter | intent subjects with filter, expanded per table |
| Resource-based quarantine policy | trino service, policyType access, deny | new unclassified columns (ADR-009) |

Trino resource hierarchy in the Ranger Trino service definition: `catalog`,
`schema`, `table`, `column`, plus `trinouser`, `systemproperty`,
`sessionproperty`, `function`, `procedure`, `schemafunction`, `queryid`,
`sysinfo`. We manage only `catalog/schema/table/column`. Unmanaged policies on the
others are respected.

## Resource mapping

OpenMetadata table FQN `service.database.schema.table` maps to Trino
`catalog.schema.table` through the binding:

- `catalog` = the Trino catalog name configured for that OpenMetadata service in
  `tagward.yaml` (`services: { lakehouse-om: lakehouse }`).
- `schema`, `table`, `column` = lowercase of the OpenMetadata names. Trino lowercases
  identifiers; a mismatch here is the classic silent miss.
- The same physical table reachable under two Trino catalogs gets two bindings and
  two service resources, both tagged.

## Tag-based access and masking

For an intent with tags T and subjects S:

1. Create `tagdef tw:T` and `tag tw:T` for each T. Attributes: `intent`, `reviewOwner`, `sensitive`.
2. For every Confirmed label of any T on a column or table, create a service
   resource for the binding and a tag-resource map to `tw:T`.
3. Tag-based **access** policy `tw:<intent>:access`, resource `tag = tw:T...`:
   - allow items: subjects with `effect: allow`, accesses `select` for tables and columns.
   - deny items: subjects with `effect: deny`, accesses `select`.
   - `denyAllElse` is not used; Ranger's default for a resource with no allow is deny,
     but a resource policy elsewhere could allow. We therefore always emit explicit
     deny for `everyone` when the intent lists it.
4. Tag-based **masking** policy `tw:<intent>:mask`, one item per masking subject,
   mask type from the mask catalog. Ranger evaluates masking items in order; the
   first match wins, so `deny` subjects are excluded from masking items and are
   handled by the access policy.

Ranger evaluates tag policies before resource policies and a deny in a tag policy
is final. Column masks and row filters apply after access is allowed.

## Row filters

Ranger row filter policies are resource-based only. For an intent with
`effect: filter`:

1. Find every table carrying a Confirmed label of a matching tag.
2. For each table, verify `requires` columns exist in the binding. Missing: plan fails naming the table.
3. Emit one resource policy `tw:<intent>:filter:<catalog>.<schema>.<table>`,
   policyType rowFilter, items per filter subject with the expression, macros as-is.
4. Ranger supports `${USER}` and `${USER.<attr>}` macros in row filter expressions;
   attributes must be synced by usersync (Spec 04). A user without the attribute
   evaluates to null, which filters out every row: fail-safe.

## Quarantine

For every table that carries at least one Confirmed label of a tag with
`sensitive: true`:

- Compute the set of columns with no Confirmed label at all (any tag counts, including `Governance.Public`).
- Emit `tw:quarantine:<catalog>.<schema>.<table>`, resource policy, deny `select` on
  exactly those columns for `public`, allow for the owner's group.
- Empty set: no policy; an existing one becomes an orphan and is removed.

## Ordering of applies

1. Orphan deletions of policies, then tag maps, then service resources, then tags, then tagdefs.
2. Creates and updates of tagdefs, tags, service resources, maps.
3. Access policies, masking policies, row filter policies, quarantine policies.

Failures stop the sequence, report per object, and leave Ranger in a state that
the next reconcile repairs. Never leave a resource tagged with a tag whose access
policy failed to create: step 3 failure triggers removal of step 2 maps for that
intent within the same run.

## Diff and plan output

```text
Plan: 3 to create, 1 to update, 2 to delete

  - tag-resource-map   lakehouse.crm.customers.email → tw:PII.Email        (label removed by steward j.doe, 2026-09-28)
  ~ policy access      tw:pii-default:access                                 (subject analysts: mask → deny)
  + policy rowFilter   tw:region-scoping:filter:lakehouse.sales.orders      (new Confirmed Governance.RegionScoped)
  + policy access      tw:quarantine:lakehouse.crm.customers                 (new column phone_alt, unclassified)
```

Every line has a reason traceable to a label, an intent or a rule.

## What the applier never does

- Touch a policy without the ownership label.
- Rename a managed object; changes in identity are delete plus create.
- Apply when validation failed.
- Apply a plan built from a read that failed or timed out.
