# ADR-009 · Fail-safe defaults

Status: accepted

## Context

Any gap between the moment an asset changes and the moment its policy is updated
is either a leak or an outage. The defaults decide which.

## Decision

The stack fails safe. In order of precedence:

1. **Quarantine.** A column added to a table that carries any tag marked
   `sensitive: true` in an intent is denied to everyone except the table owner's
   subject until it carries a Confirmed tag, or a Confirmed `Governance.Public` tag.
2. **Expiry keeps enforcing.** When a tag's review period lapses, the controller
   sets the label back to Suggested for review but keeps the compiled policy in
   place until a steward rejects the tag. Review lapses never open access.
3. **Unknown subject fails the plan.** An intent that names a subject whose group
   does not exist in Keycloak fails validation. Nothing is applied.
4. **Renames are deletes plus creates.** A renamed table loses its managed
   policies as orphans and gains quarantine on the new name until its tags are
   re-confirmed. OpenMetadata keeps tags across renames when it detects them;
   the controller trusts OpenMetadata's asset identity, not the name.
5. **Deny beats mask beats allow** when several intents apply to one column.

## Consequences

- Stewards will see quarantined columns as work items. That is the intended pressure.
- Table owners keep access to their own quarantined columns so pipelines do not break silently.
- These defaults are overridable per environment in `tagward.yaml`, and the
  override is itself reported by drift as a weakened posture.
