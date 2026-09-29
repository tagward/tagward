# Spec 08 · Conformance and drift

Nobody trusts enforcement they cannot test. The suite runs real queries as
synthetic users and asserts what comes back. Drift compares three views of truth.

## Conformance cases

```yaml
spec: 1
kind: ConformanceTests
env: staging
cases:
  - id: analysts-see-hashed-email
    as: analysts                        # subject; the runner picks the synthetic user for it
    sql: SELECT email FROM lakehouse.crm.customers LIMIT 1
    expect:
      outcome: success
      column: email
      matches: "^[0-9a-f]{64}$"         # hashed
  - id: everyone-denied-national-id
    as: everyone
    sql: SELECT national_id FROM lakehouse.crm.customers LIMIT 1
    expect:
      outcome: denied
      errorContains: "Access Denied"
  - id: regional-analyst-sees-own-region
    as: regional-analysts
    user: eu-analyst                    # a specific synthetic user with attribute region=eu
    sql: SELECT DISTINCT region FROM lakehouse.sales.orders
    expect:
      outcome: success
      rows: [["eu"]]
  - id: quarantine-blocks-new-column
    as: analysts
    sql: SELECT phone_alt FROM lakehouse.crm.customers LIMIT 1
    expect:
      outcome: denied
```

Runner behavior:

- Authenticates each synthetic user against Keycloak, direct grant, `conformance` client.
- Runs each case over Trino JDBC, captures outcome, error message, first row, column values.
- Waits for policy propagation before running: polls Ranger's plugin status
  endpoint or the admin's policy version until the coordinator has the version
  the last apply produced, with a timeout of two poll intervals.
- Produces JUnit XML and a human table. Non-zero exit on any failure.
- Never runs against an environment not listed in `tagward.yaml`.

## Generated cases

Beyond hand-written cases, `tagward test --generate` derives one case per
(intent, subject, effect) on one sample asset per tag, so every intent has at
least one proof even if nobody wrote a test. Generated cases are reported
separately.

## Drift classes

| Class | Compares | Example | Severity |
| --- | --- | --- | --- |
| A | intent → Ranger | a managed policy missing or edited | high, apply fixes it |
| B | Ranger → intent | a managed object with no source, an orphan not yet removed | medium |
| C | Ranger unmanaged | a hand-written policy that grants access to a resource carrying a sensitive tag | high, reported, never auto-fixed |
| D | observed → intent | a conformance case fails although Ranger state matches intent | critical, means the plugin or Trino is not enforcing |
| E | catalog → intent | a Confirmed sensitive tag on a table with no binding in Trino, or a binding the catalog no longer has | medium |
| F | posture | fail-safe defaults overridden in `tagward.yaml` | info |

`tagward drift` exit codes: 0 none, 1 medium only, 2 high, 3 critical.

## Where results go

- CI: job status and JUnit report.
- Daemon: metrics per class, `/status`, and `tw_enforcement=drift` with
  `tw_drift` text on the affected asset in OpenMetadata.
- Class C and D also produce an OpenMetadata announcement on the asset so
  stewards see it where they work.
