# Contributing to Tagward

Thank you for considering a contribution. This page covers the master repository.
The controller and the policy template have their own short guides that point back here.

## Ways to contribute

- **Discuss.** Open a discussion or an issue. Design questions become ADRs.
- **Specify.** Improve a specification in `docs/spec/`. A specification change that
  alters behavior needs an ADR or an update to an existing one.
- **Build.** Charts, images and compose files live here. Code lives in
  [tagward-controller](https://github.com/tagward/tagward-controller).
- **Verify.** Run the compose stack against a pinned version bump and report.

## Ground rules

- **License.** Contributions are under Apache 2.0. Copyright stays with you; the
  project's copyright line is "The Tagward Authors". No copyright assignment, ever.
- **Developer Certificate of Origin.** Every commit is signed off:
  `git commit -s`. The sign-off certifies the [DCO](https://developercertificate.org/).
  A bot checks it on every pull request.
- **No commercial dependencies.** A new component must be permissively licensed
  and listed in `docs/03-bill-of-materials.md`. The CI license gate is not optional.
- **Versions live in one place.** `versions.yaml`. A chart, compose file or
  document that hardcodes a version is a bug.

## Workflow

1. Fork, branch from `main`, name the branch `topic/short-description`.
2. Make the change. Keep pull requests focused: one ADR, one spec change, one chart change.
3. Run the local checks: `make lint` (markdownlint, yamllint, link check, versions check).
4. Open a pull request using the template. Link the issue or the ADR.
5. One maintainer review is required. Lazy consensus after 72 hours for
   documentation; two approvals for ADRs and for anything under `charts/` or `images/`.

## Architecture decision records

A decision that changes the shape of the system gets an ADR in `docs/adr/`,
numbered, with context, decision, consequences and rejected alternatives. Accepted
ADRs are never edited; they are superseded by a new one.

## Commit messages

Conventional style, imperative mood, one line under 72 characters, a body that
explains why. Examples: `docs: clarify quarantine precedence in ADR-009`,
`chart(ranger): add readiness probe on admin`.

## Style

- Markdown: one sentence per line is not required, but keep lines readable.
  `markdownlint` configuration is in `.markdownlint-cli2.yaml`.
- YAML: two spaces, no tabs, `yamllint` configuration in `.yamllint.yaml`.
- Diagrams: Mermaid in Markdown, so they render on GitHub and are diffable.

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
