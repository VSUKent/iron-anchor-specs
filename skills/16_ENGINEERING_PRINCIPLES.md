# 16 — Engineering Principles

**Purpose:** State only principles supported by the handoff or repository evidence; use them to evaluate this document set.

**Confidence note:** Verified against `../handoff.md` and the current repository snapshot on 2026-11-12. The code wins (see this document).

## 1. Treat evidence as stronger than a plausible story

**Rule:** Record implementation behavior only when a file, test, commit, or operational artifact verifies it; label inference and suspicion separately.

**Reason:** A fabricated architecture or incident teaches the next engineer to change the wrong boundary, and can conceal the real failure.

**Evidence:** `../handoff.md` requires concrete, code-checked statements, confidence labels, and says the code wins. The current checkout has no application commits or source.

trust the code over any document, including this one
