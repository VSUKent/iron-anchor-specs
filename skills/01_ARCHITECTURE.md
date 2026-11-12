# 01 — Architecture

**Purpose:** Describe product ownership, boundaries, and data flow; read this before making cross-product changes.

**Confidence note:** Verified against the uncommitted repository snapshot and four `AGENTS.md` files on 2026-11-12. The code wins (see 16).

## Current model

The checkout names three products: an API, an Android application, and a web front end. The API's `AGENTS.md` describes it as communicating between a Supabase database API and web/Android clients; the Android description only identifies it as the Iron Anchor Android application; the web description says it contains regulatory compliance for Iron Anchor. These are repository descriptions, not behavior verified from implementation.

| Component | Stated ownership | Verified implementation |
|---|---|---|
| `iron-anchor-api` | Communication between Supabase database API and clients | None present |
| `iron-anchor-android` | Android application | None present |
| `iron-anchor-web` | Regulatory compliance front end | None present |
| `iron-anchor-specs` | Ecosystem specifications | Only `git-guidelines.md` present |

## Data flow and boundaries

The API description implies client-to-API-to-Supabase communication. It does not specify protocols, data ownership, authentication, synchronization, or whether clients also contact Supabase directly. Do not build on those assumptions until routes, configuration, and database contracts are available.

## Decisions and inherited tradeoffs

No implementation decision records, diagrams, migrations, or commit history are available. No tradeoff can be reconstructed safely.

## Debt register

1. **Critical evidence gap:** source trees and history are absent, so component responsibilities and cross-product contracts cannot be validated. Restore/populate the project repositories before documenting architecture as fact.
2. **Policy customization gap:** `../git-guidelines.md` still uses `code-name` and `CN` placeholders despite the `iron-anchor-*` directory names. Confirm the canonical product code and prefixes before creating tags or relying on example scopes (see 10 and 15).
