# 08 — API

**Purpose:** Capture API contracts and route conventions when implementation evidence is available.

**Confidence note:** Verified against the available API repository files on 2026-11-12. The code wins (see 16).

## Current evidence

The API repository contains only its `AGENTS.md`, which describes a backend between Supabase and web/Android clients. No routes, middleware, validators, response envelope, authentication rules, API versioning, or tests are available.

## Adding or changing an endpoint

No endpoint recipe can be verified. Before implementation, inspect the restored route tree and existing handlers; identify authorization, validation, error serialization, and client mirrors; then add endpoint-specific tests and update this document. Do not invent an envelope or assume the clients call only this service. Missing evidence is a blocker for claiming contract compatibility, not a reason to silently default.
