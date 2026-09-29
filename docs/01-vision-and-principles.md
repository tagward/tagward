# 01 · Vision and principles

## The problem

Every organisation that runs Trino on a lakehouse ends up with the same three
systems: a catalog where people describe data, a policy engine where administrators
write access rules, and the query engine where access actually happens. The three
are installed separately, speak different type systems, and are kept consistent by
hand. Classification in the catalog is descriptive only; nobody can prove that a
column tagged "PII" is actually masked for the people who should not see it.

Commercial products sell exactly this loop. No packaged open-source equivalent exists.
The classic open-source answer, Apache Atlas feeding Ranger tag-sync, needs a heavy
runtime, has no open Trino mapper, and stops at the enforcement boundary with no
feedback.

## The goal

A tag confirmed in OpenMetadata becomes a denied, masked or filtered query in Trino
within a minute, with a test that proves it, a status that shows it, and an audit
row that records who was affected. All of it deploys as one Helm release or one
compose file, and every component is permissively licensed.

## Principles

1. **One system of record per fact.** Classification and approval live in
   OpenMetadata. Policy intent lives in git. Compiled policy lives in Ranger.
   Identity lives in Keycloak. Nothing is synchronized in both directions; the
   controller compiles and reconciles, it does not replicate.
2. **Nothing is enforced before a human confirms it.** Automated and propagated
   tags are suggestions. Only Confirmed tags reach the compiler. A false positive
   from a classifier can never lock anyone out.
3. **Fail safe by default.** A new column on a table that carries any sensitive tag
   is denied until classified. A tag whose review date passes stays enforced until
   re-reviewed. A group that does not exist in the identity provider fails the plan.
4. **Prove it, do not claim it.** The conformance suite runs real queries against
   Trino as synthetic users and asserts the outcome. Drift detection compares
   intent, Ranger state and observed behavior. Both run in CI and in production.
5. **Everything is portable.** A company's governance lives in its own git
   repository as plain YAML with a published schema. Our images and charts can be
   replaced without losing a single policy.
6. **Upstream first, own it when upstream is not good enough.** We use official
   images and charts where they are production quality. Where they are not, and
   Ranger is the first case, we build and maintain our own, from the Apache release
   artifacts, and we say so.
7. **License is a hard gate.** Apache 2.0, PostgreSQL, MIT, BSD. No SSPL, no BSL,
   no Elastic License, no Bitnami "secure images". CI fails on a violation.
8. **Deployment is a breeze or it is a bug.** A first install must not need a
   runbook. Bootstrap of services, realms, custom properties and webhooks is done
   by the controller, not by shell scripts.

## Non-goals for the first releases

- Enforcement outside Trino. Spark, direct object-store access and other engines
  are visible in the catalog and flagged as side doors, not enforced, until the
  Iceberg REST catalog target ships.
- A user interface of our own. OpenMetadata is the front door, Ranger admin is
  the operator console, the controller is a CLI, a daemon and a status endpoint.
- Replacing OpenMetadata's classifier. We consume its suggestions; we do not
  build a better one.
- Multi-tenant SaaS packaging. One stack per organisation.

## Who this is for

- **Data platform teams** who run Trino and need real enforcement without a
  commercial governance suite.
- **Data stewards and privacy officers** who need to see, on the asset itself,
  that a classification is actually enforced and who has been accessing it.
- **Security teams** who want policy as code, reviewed in pull requests, tested
  in CI, and auditable.
