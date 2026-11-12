# 14 — Developer Workflows

**Purpose:** Provide safe, currently executable repository checks and identify workflows that cannot yet be documented.

**Confidence note:** Verified against the current checkout on 2026-11-12. The code wins (see 16).

## Inspect repository state

From `iron-anchor-ecosystem`, run:

```powershell
git -C .\iron-anchor-api status --short --branch
git -C .\iron-anchor-android status --short --branch
git -C .\iron-anchor-web status --short --branch
git -C .\iron-anchor-specs status --short --branch
```

These commands were run against this checkout. Each repository reports an unborn `main` with a missing `origin/main`; the API, Android, and web `AGENTS.md` files are untracked, and the specs `AGENTS.md` and `git-guidelines.md` are untracked. Do not treat this local state as the remote project's history.

## Setup, change, test, release

No install, build, run, test, migration, or deployment workflow can be verified without manifests, code, CI, and commit history. Do not invent commands or create speculative source layouts. When those inputs are restored, add one concrete, tested recipe for each common task and link its affected lockstep set in 04 or failure story in 06.

For knowledge contributions, add a verified correction directly to its numbered home, or put an explicitly unverified discovery in `INBOX.md`; update 00 afterward. Add what surprised you to `INBOX.md`.
