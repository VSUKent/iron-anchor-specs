# 13 — Dependencies

**Purpose:** Record why dependencies exist and which upgrades have compatibility traps.

**Confidence note:** Verified against recursive project file listings on 2026-11-12. The code wins (see 16).

There are no package manifests, lockfiles, Gradle files, build scripts, or dependency policy in this checkout. No dependency, version, runtime, license, upgrade risk, or deliberate rejection can be verified. Do not infer dependency choices from repository names or the Supabase reference in `AGENTS.md`. On restoration, inventory declared and transitive dependencies from the actual manifests and document upgrade traps with tested versions and evidence.
