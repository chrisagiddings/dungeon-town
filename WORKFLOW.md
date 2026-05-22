# Dungeon Town — Development Workflow Protocol

**Status:** Active
**Established:** 2026-05-22
**Authority:** Giddy

---

## Rules (Strict — No Exceptions)

### 1. One Issue at a Time
- Work on exactly one GitHub issue per session
- If a request touches or implies more than one issue, **stop and ask for clarification before proceeding**
- No bundling unrelated work into a single session

### 2. Clean Commit History
- Each commit must correspond to exactly one issue
- Commit message format: `[#N] Short description of what was done`
- No mixed commits (multiple unrelated changes in one commit)
- Squash messy intermediate commits before opening a PR

### 3. Record What Works and Doesn't Work
- All findings — what functioned, what failed, edge cases, blockers — are recorded as comments on the relevant GitHub issue
- Do not leave issues with silent closures; document the outcome

### 4. Unit Tests Required on All PRs
- Every PR must include unit tests that validate the functionality introduced or changed
- Tests must pass before the PR is opened
- Test coverage for the changed code is non-negotiable

### 5. PR Standards
- One PR per issue
- PR title: `[#N] Issue title`
- PR body: links to issue, summary of changes, test coverage notes
- No PR without passing tests

---

## Workflow Order

1. Confirm which single issue we're working on
2. Create a feature branch: `git checkout -b issue-N-short-description`
3. Implement the change
4. Write and run unit tests
5. Commit: `git commit -m "[#N] Description"`
6. Open PR referencing the issue
7. Record outcome (pass/fail/notes) on the issue
8. Merge after review

---

*This protocol applies to all contributors including AI agents.*
