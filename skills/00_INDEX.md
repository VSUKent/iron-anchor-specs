# 00 — Index

**Purpose:** Choose the project knowledge document to read for a task and keep this set current.

**Confidence note:** Verified against the uncommitted repository snapshot (all four repositories have zero commits) on 2026-11-12. The code wins (see 16).

## Read by task

| Task | Start here |
|---|---|
| Understand the product boundaries | 01, then 02 |
| Change application code | 02, 03, 04, and the relevant product docs (07–13) |
| Investigate a failure | 05, then 06 and the relevant product doc |
| Release or change branches/tags | 10 and `../git-guidelines.md` |
| Set up, test, or contribute | 11, 14, then 04 |
| Assess known gaps | 15; do not treat unassessed areas as safe |
| Add or correct project knowledge | `INBOX.md`, then 00 and the destination document |

## Documents

All entries below were last checked on 2026-11-12. Application behavior is not verified because application source and history are absent from this checkout.

| File | Subject | Last verified |
|---|---|---|
| `00_INDEX.md` | Reading order and document history | 2026-11-12 |
| `INBOX.md` | Contribution queue and template | 2026-11-12 |
| `01_ARCHITECTURE.md` | Observable product boundaries and unknowns | 2026-11-12 |
| `02_PROJECT_STRUCTURE.md` | Current checkout inventory | 2026-11-12 |
| `03_CODE_STYLE.md` | Available coding and commit guidance | 2026-11-12 |
| `04_CHANGE_RULES.md` | Verified lockstep sets and retest policy | 2026-11-12 |
| `05_DEBUGGING_PLAYBOOK.md` | Available diagnostics | 2026-11-12 |
| `06_FAILURE_STORIES.md` | Evidence-backed incident record | 2026-11-12 |
| `07_DATABASE.md` | Database knowledge and unknowns | 2026-11-12 |
| `08_API.md` | API knowledge and unknowns | 2026-11-12 |
| `09_SECURITY.md` | Security evidence and assessment gaps | 2026-11-12 |
| `10_DEPLOYMENT.md` | Documented branch and release policy | 2026-11-12 |
| `11_TESTING.md` | Test inventory and confidence limits | 2026-11-12 |
| `12_PERFORMANCE.md` | Performance evidence and unknowns | 2026-11-12 |
| `13_DEPENDENCIES.md` | Dependency evidence and unknowns | 2026-11-12 |
| `14_DEVELOPER_WORKFLOWS.md` | Safe workflows supported by this checkout | 2026-11-12 |
| `15_KNOWN_LIMITATIONS.md` | Ranked limits of current evidence | 2026-11-12 |
| `16_ENGINEERING_PRINCIPLES.md` | Evidence-first knowledge rules | 2026-11-12 |

## Contributing

Add discoveries to `INBOX.md` when they cannot yet be verified. For a verified correction, preserve existing substance and credit, update its home document, refresh that document's confidence note and this table, and append a newest-first changelog entry. Do not invent application details to fill a section. Retire stale guidance with a dated explanation rather than deleting it. Keep document numbers stable.

## Changelog

- 2026-11-12: Created an evidence-qualified baseline. Application code, tests, migrations, CI, and commit history were unavailable; see 15.
