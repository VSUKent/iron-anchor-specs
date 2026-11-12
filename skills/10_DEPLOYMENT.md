# 10 — Deployment

**Purpose:** Record the release process documented for the ecosystem and its unverified prerequisites.

**Confidence note:** Verified against `../git-guidelines.md` on 2026-11-12. The code wins (see 16).

## Documented promotion model

The guidelines prescribe `main` → `beta` → `release` → production. `main` is development, `beta` is QA/system testing, and `release` is release-bundle integration testing. A release branch is not production approval. Corrections made during stabilization should be reviewed and carried upstream when required.

Once planned development is complete, the stated sequence is alpha (`a`), beta (`b`), and release candidate (`rc`), with numeric suffixes for another candidate in a failed stage (for example `a2`). Only the exact approved RC is deployed. The guidelines also specify product tag prefixes `WCN`, `BCN`, `ACN`, and `SCN`, format `<prefix>.0X.Y.00Z`, weekly build-number rules, and no moving/reusing tags.

## Unverified and conflicting details

No branch other than the local unborn `main`, CI workflow, build command, artifact, release website, deploy target, credentials procedure, or production approval record is available here. The tag and scope names in the guidelines are explicitly template values (`code-name`, `CN`) and have not been customized to Iron Anchor. Their examples and empty historical tables are not evidence of an actual release. Confirm canonical prefixes and release ownership before tagging or deploying.

Do not create a release tag or claim a release from this checkout: there is no commit to tag. See 15.
