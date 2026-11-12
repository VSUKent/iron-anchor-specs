# 07 — Database

**Purpose:** Record database contracts and dangerous operations only when supported by schema or migration evidence.

**Confidence note:** Verified against the available API repository files on 2026-11-12. The code wins (see 16).

## Verified facts

The API `AGENTS.md` describes communication with a Supabase database API. No schema, migration, seed, query, generated type, or database configuration is present. The database engine details, identity strategy, tables, constraints, deletes, indexes, migration order, and integrity invariants are unknown.

## Change safety

Do not infer that a table is safe to rename or delete, or that a client owns a field, from the Supabase mention alone. Before a database change, locate the authoritative schema and migration process, identify all API and client consumers, and document each mirrored field in 04. **Miss →** an untracked consumer may fail or persisted data may become incompatible; the specific risk cannot be determined until the schema is available.
