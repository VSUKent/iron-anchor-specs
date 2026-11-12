# 02 — Project Structure

**Purpose:** Show where project files currently live and avoid prescribing code locations without source evidence.

**Confidence note:** Verified against recursive file listings of all four repositories on 2026-11-12. The code wins (see 16).

## Observed tree

```text
iron-anchor-ecosystem/
  handoff.md
  iron-anchor-api/
    AGENTS.md
  iron-anchor-android/
    AGENTS.md
  iron-anchor-web/
    AGENTS.md
  iron-anchor-specs/
    AGENTS.md
    git-guidelines.md
    skills/                 # this knowledge set
```

Git internals are omitted. No application manifests, source directories, tests, migrations, build files, or CI definitions were present.

## Placement guidance

- Keep ecosystem guidance in `iron-anchor-specs/skills/`.
- `AGENTS.md` files identify the intended product areas, but do not define source layout or naming conventions.
- Do not create a speculative application tree or place production code based on this document. Follow the established layout when source is restored and update this inventory with evidence.
