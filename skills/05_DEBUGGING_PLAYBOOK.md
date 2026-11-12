# 05 — Debugging Playbook

**Purpose:** Point investigators to known diagnostic evidence and prevent guesses from being recorded as incidents.

**Confidence note:** Verified against all available files and git history on 2026-11-12. The code wins (see 16).

## Where evidence lives

No application logs, telemetry configuration, CI output, test output, deployment records, or application source are present. Git repositories have no commits in this checkout, so no known-good revision exists.

## Known symptoms

There are no verified application error messages or reproducible failure reports. Do not add a symptom/cause mapping until the exact message and evidence are captured.

## Initial local checks

From the ecosystem directory, inspect the repository state with:

```powershell
git -C .\iron-anchor-api status --short --branch
git -C .\iron-anchor-android status --short --branch
git -C .\iron-anchor-web status --short --branch
git -C .\iron-anchor-specs status --short --branch
```

In the current checkout each reports an unborn `main` branch tracking a missing `origin/main`; this only describes this local checkout. Once code is available, add exact log locations, known error strings, and commands verified against actual tooling. When a silent failure is verified, record the missed guard and its consequence as `Miss → ...`, as required by the handoff.
