# Architecture decision records

One decision per file. A record is never edited after acceptance; a new record
supersedes it. Status values: proposed, accepted, superseded.

| # | Decision | Status |
| --- | --- | --- |
| 001 | No Apache Atlas; its features are mapped to replacements | accepted |
| 002 | Ranger is the first enforcement backend, OPA the second | accepted |
| 003 | Policy intent lives in git, not in the catalog | accepted |
| 004 | Ranger audit goes to OpenSearch, no Solr | accepted |
| 005 | Gravitino is not in the first release | accepted |
| 006 | Compile and reconcile, never two-way sync | accepted |
| 007 | Controller in Java 21 | proposed |
| 008 | Own Ranger images and chart, built from Apache release artifacts | accepted |
| 009 | Fail-safe defaults: quarantine, expiry, unknown group | accepted |
