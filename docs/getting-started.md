# Getting started

Tagward is in its first iteration. What you can do today, and what is coming.

## Today: validate a policy repository

The controller's `validate` command checks a policy repository against the
spec version 1 schemas and the cross-reference rules: unknown subjects, unknown
masks, duplicate ids, unknown environments, wrong file kinds, malformed YAML.

=== "Container image"

    ```bash
    git clone https://github.com/tagward/tagward-policy-template my-policies
    docker run --rm -v "$PWD/my-policies:/repo:ro" ghcr.io/tagward/controller:main validate /repo
    ```

=== "From source"

    ```bash
    git clone https://github.com/tagward/tagward-controller
    cd tagward-controller && mvn -B package
    java -jar cli/target/tagward.jar validate ../my-policies
    ```

Expected output on the template:

```text
valid: 0 error(s), 0 warning(s)
```

Change a subject name in an intent to something not declared in
`subjects/groups.yaml` and run it again:

```text
error: intents/pii-default.yaml /subjects/1/name: unknown subject 'marketing': declare it in subjects/groups.yaml
invalid: 1 error(s), 0 warning(s)
```

## Today: write your first intent

An intent says what a tag means for access. This one hashes direct identifiers
for analysts, shows them in clear to the privacy office, and denies everyone else:

```yaml
spec: 1
kind: Intent
id: pii-default
match:
  tags: [PII.Email, PII.Phone, PII.NationalId]
  state: Confirmed
sensitive: true
subjects:
  - name: privacy-office
    effect: allow
  - name: analysts
    effect: mask
    mask: hash
  - name: everyone
    effect: deny
review:
  everyDays: 180
  owner: privacy-office
```

The full format is in [Spec 02](spec/02-policy-repository.md).

## Next: the compose stack

The current milestone brings up the whole stack on a laptop with one command and
proves the audit path without Solr. The compose file and its configuration live in
[`compose/`](https://github.com/tagward/tagward/tree/main/compose) and are being
verified. Progress is tracked in the [roadmap](roadmap.md) and in the
[M0 issues](https://github.com/tagward/tagward/issues?q=is%3Aissue+label%3Amilestone%3AM0).

## Then: a tag changes a query

Milestone M1 delivers `plan`, `apply`, `bootstrap` and `test`, the umbrella Helm
chart, and the acceptance test that defines the product: confirm a `PII.Email` tag
in OpenMetadata, and within a minute analysts receive hashed values, everyone else
is denied, and the asset shows `enforced`.
