# 15 — Known Limitations

**Purpose:** Rank the gaps most likely to mislead contributors using this checkout.

**Confidence note:** Verified against all four repository states and available files on 2026-11-12. The code wins (see 16).

## Ranked limitations

1. **Application source and history are absent.** All four local repositories have zero commits; the API, Android, and web contain only untracked `AGENTS.md` files, while specs also contains an untracked `git-guidelines.md`. Runtime behavior, ownership, incidents, and prior fixes cannot be verified. This is an environment/repository-state finding, not a claim that remote repositories are empty.
2. **No build, test, CI, schema, or deployment artifacts are present.** Setup, testing, migrations, monitoring, and shipping instructions cannot be validated. Treat them as unknown.
3. **Release guidance is not customized.** `git-guidelines.md` uses `code-name` and `CN`, has blank historical tag tables, and includes a next-release example. Repository names do not establish canonical scope spelling or tag prefixes. Verify with maintainers before using it operationally.
4. **No product security or performance assessment exists in this snapshot.** These domains are unassessed; this is neither evidence of safety nor evidence of a concrete vulnerability or bottleneck.
5. **Current skills are necessarily provisional.** They describe observable files and policy only. Recheck them against the first populated source snapshot and preserve useful corrections with evidence.

## Redesign candidates

No architecture is available to rank for redesign. First restore and inspect the implementation; then rank candidates by measured user impact, operational risk, and migration cost rather than speculation.
