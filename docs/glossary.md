# Glossary

**Asset.** Anything the catalog knows: a table, a column, a view, a topic. In the
canonical model an asset has a stable identity and one or more engine bindings.

**Binding.** How an asset is addressed in one engine. For Trino: catalog, schema,
table, column, all lowercase.

**Classification.** An OpenMetadata grouping of tags, for example `PII` with tags
`PII.Email`, `PII.Phone`.

**Confirmed / Suggested.** OpenMetadata tag label states. Only Confirmed labels
are compiled.

**Manual / Automated / Propagated / Derived.** OpenMetadata tag label types. We
write Propagated; the classifier writes Automated; stewards write Manual.

**Intent.** A file in the policy repository that says what a tag means for access:
which subjects are allowed, masked or denied, with which transformation.

**Subject.** A named audience in an intent, mapped to a Keycloak group in
`subjects/groups.yaml`. Intents never name groups directly.

**Plan.** The set of Ranger objects the compiler would create, update or delete.
Printed before apply, the same way infrastructure tools do.

**Managed object.** A Ranger object created by the controller, marked with an
ownership label. Unmanaged objects are never touched.

**Orphan.** A managed object whose source intent or tag no longer exists. Removed on apply.

**Drift.** A difference between intent, the Ranger state, and the behavior observed
by conformance tests.

**Quarantine.** The default deny placed on an unclassified new column of a table
that carries a sensitive tag.

**Declassification tag.** A tag such as `Governance.Sanitized` that stops
propagation and requires a human to confirm it.

**Side door.** Any access path to the data that does not go through Trino.
Visible, flagged, not enforced in the first releases.

**Tag service.** The Ranger service of type `tag` that holds tag definitions,
tags and tag-to-resource maps, linked to the Trino service.
