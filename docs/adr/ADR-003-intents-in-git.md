# ADR-003 · Policy intent lives in git

Status: accepted

## Context

An intent, the rule that says what a tag means for access, could live as custom
entities in OpenMetadata, as policies typed directly in Ranger, or as files in a
git repository. OpenMetadata tags are flat labels with no attributes. Ranger
policies are already the compiled output. Policy changes need review, history,
tests and rollback.

## Decision

Intents, propagation rules, subject mappings and conformance tests are plain YAML
files in a git repository the organisation owns, validated by a published JSON
Schema. OpenMetadata displays them on the asset through custom properties. The
controller reads them from a checkout or a URL.

## Consequences

- Portability: an organisation's governance is a folder of YAML with a schema.
  Nothing of ours is required to read it.
- The pull request is the approval workflow for policy. CI runs plan and
  conformance tests before merge.
- Tag attributes such as review period, owner subject and mask function are keyed
  by tag name in these files rather than stored on the tag.
- A steward without git access changes classification in OpenMetadata, which is
  the common case; only policy semantics need a pull request.
