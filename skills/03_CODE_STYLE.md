# 03 — Code Style

**Purpose:** Record verified coding and commit conventions without inventing a language-specific style guide.

**Confidence note:** Verified against `../git-guidelines.md` and the current repository snapshot on 2026-11-12. The code wins (see 16).

## Coding style

No source files, language manifests, linters, formatters, or code-review rules were available. Naming, comments, error handling, logging, and language-specific patterns are therefore **unknown**, not unrestricted. Follow the conventions in the restored code and update this document once they can be checked.

## Commit messages

`../git-guidelines.md` requires `scope: Imperative summary` on the first line; the summary is sentence case, has no final period, and is at most 50 characters. Prefer product/feature scopes; the file gives `code-name-*` examples and says the product code should be customized. A body is optional and should explain why, wrapped at 72 characters. Breaking changes use `!` after the scope and a `BREAKING CHANGE:` trailer.

**Customization warning:** the guidance still uses the literal `code-name` and `CN` placeholders. Repository names suggest `iron-anchor`, but no canonical short code or customized commit scopes are verified. Do not silently substitute a prefix; confirm it with maintainers (see 15).

The same file says AI agents should not be added as commit, tag, release, or PR authors. No commit was made as part of this handoff.
