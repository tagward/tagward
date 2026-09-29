# Specifications

Normative. "Must" means the implementation is wrong without it. "Should" means
deviate only with an ADR.

| # | Specification | Builds |
| --- | --- | --- |
| 01 | Controller | controller repository |
| 02 | Policy repository format | controller `spec` module, policy template |
| 03 | Ranger compilation rules | controller `compiler`, `applier` |
| 04 | Identity | Keycloak realm, Trino, Ranger, controller validation |
| 05 | Audit | Trino plugin config, OpenSearch template, controller feedback |
| 06 | Images | `images/` |
| 07 | Distribution | `charts/`, `compose/`, release process |
| 08 | Conformance and drift | controller `conformance`, `drift`, policy template `tests/` |
| 09 | Security model | everything |
