---
name: changelog
description: Maintain the project's root CHANGELOG.md after authorized, completed work. Use when reporting finished implementation, or when the user asks to update or review the changelog. Never use it to record planned or speculative work.
---

# Changelog skill

## Purpose

Keep `CHANGELOG.md` a clear, concise and trustworthy history of meaningful project changes. Every entry must describe something that actually exists in the project.

This skill edits only `CHANGELOG.md`. It never implements functionality and grants no implementation authorization (see `CLAUDE.md`, section 1).

## When to update

Update after **authorized, completed** work that produces a meaningful change:

- New features.
- Bug fixes.
- Breaking changes.
- Security improvements.
- Significant performance improvements.
- Architectural or infrastructure changes that affect developers or operators.
- Important deprecations or removals.
- Changes to the development process or project documentation that developers need to know about.

Do **not** add entries for:

- Trivial edits, typo fixes or formatting-only changes.
- Plans, specs or proposals on their own. A spec being written is not a product change.
- Failed or reverted implementation attempts.
- Work that is partly done. Record only what is complete and verified; mention known limitations if a completed change ships with them.

## Format

Based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

```markdown
## [Unreleased]

### Added
- One line per change, written for the reader who uses or builds on it. ([spec](spec/YYYY-MM-DD_HH-mm_name/))

### Changed
### Deprecated
### Removed
### Fixed
### Security
```

- Include only the categories that have entries.
- Describe the user-visible or developer-relevant effect, not filenames. "Bookings fail with `sold_out` instead of overselling when two people take the last spot" is a good entry. "Updated booking.ts" is not.
- Link the spec directory when one exists.
- Mark breaking changes with a leading **BREAKING:**.
- Group related changes into one entry. Do not paste the spec.

## Accuracy rules

- Never claim an unimplemented feature exists.
- Never describe planned work as completed.
- Never invent release versions or release dates.
- Preserve all existing history. Do not reword, reorder or delete past entries, except to correct a factual error. If you correct one, say so in your report.
- Keep unreleased changes under `## [Unreleased]`. Move them into a versioned section only when the user says a release happened, using the version and date they give.
- Follow Semantic Versioning only once the project adopts versioned releases. It has no release strategy yet, so do not create versions.

## Procedure

1. **Inspect the actual changes:** the files changed and the diff (git is not set up yet, so compare against the spec's affected-files list).
2. **Read the spec,** especially `REQUIREMENTS.md` and Part B of `VALIDATION.md`. Only requirements verified there count as done.
3. **Identify the meaningful completed changes.** Drop anything trivial, unverified or not finished.
4. **Pick categories:** Added, Changed, Deprecated, Removed, Fixed or Security.
5. **Write concise entries** under `## [Unreleased]`, each linking its spec where useful.
6. **Check** that existing entries are intact and the file still follows the format.
7. **Report** the changelog update in the implementation report: the entries added, or why none were needed.
