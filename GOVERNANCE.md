# Governance

Tagward is an independent open-source project. It is not a company and is not
affiliated with any vendor. This document says how decisions are made.

## Roles

- **Contributor.** Anyone who has a merged pull request, an accepted ADR, or a
  reproduced bug report.
- **Maintainer.** Listed in [MAINTAINERS.md](MAINTAINERS.md). Reviews and merges,
  cuts releases, holds write access to the organisation's repositories.
- **Founding maintainer.** The initial maintainer, with the tie-breaking vote until
  there are at least three maintainers.

Maintainers are added by consensus of the existing maintainers after sustained
contribution, typically six months. A maintainer inactive for a year moves to
emeritus and can return on request.

## Decisions

- **Day to day.** Pull request review. One maintainer approval for documentation,
  two for ADRs and for anything under `charts/` or `images/` in this repository,
  or under `compiler/`, `applier/` and `bootstrap/` in the controller.
- **Design.** An architecture decision record in `docs/adr/`. Open for comment for
  at least five working days. Lazy consensus: accepted when no maintainer objects.
  An objection is resolved by discussion, then by a simple majority of maintainers.
- **Roadmap.** `ROADMAP.md` is changed by pull request under the same rule as an ADR.

## Releases

A release is a tag on this repository after `versions.yaml` entries are marked
`verified` by CI. Any maintainer can propose a release; two approve it.

## Name, trademark and assets

The name Tagward, the GitHub organisation and the domains are held in trust for the
project by the founding maintainer until a foundation or a legal entity is created
for that purpose. Moving them requires the consent of all maintainers.

## Changes to this document

Same process as an ADR.
