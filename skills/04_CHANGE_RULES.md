# 04 — Change Rules

**Purpose:** Identify verified lockstep sets and the retesting they require.

**Confidence note:** Verified against all available project files on 2026-11-12. The code wins (see 16).

## Lockstep inventory

No constants, enums, registries, schema columns, mirrored types, or error-code lists are present in the checkout. There is no verified application lockstep set to enumerate. This is an absence of evidence, not proof that the full products have none.

## Change procedure

1. Before changing a cross-product contract, locate its source of truth and all client/server/database mirrors in the restored code.
2. Record every mirror as a numbered lockstep set here. For each member, explain the failure if it is missed: **Miss →** observable breakage.
3. Retest each affected producer and consumer, including migrations and backward-compatible clients where the code indicates they exist.
4. If the set or test cannot be found, stop short of asserting compatibility and add an evidence-backed `INBOX.md` entry.

These are investigation safeguards, not claims about current runtime architecture. No change-specific test matrix can be given until source and tests exist.
