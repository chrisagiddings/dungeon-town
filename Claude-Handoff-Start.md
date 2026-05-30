# Dungeon Town — Claude Code Development Handoff

Welcome to the Dungeon Town project. This document establishes the development workflow, commit standards, and project context for continuing development.

---

## Project Overview

**Dungeon Town** is a dungeon-themed colony sim built in Godot 4.
- **Engine:** Godot 4.x, GDScript (C# for performance-critical systems later)
- **Platform:** Steam (Windows/Mac/Linux), future iOS/tvOS
- **Visual Style:** Isometric 3D town view, cross-section 2.5D dungeon view
- **Repository:** https://github.com/chrisagiddings/dungeon-town
- **Local Path:** `/Users/giddy/clawd/projects/dungeon-town/game/`

---

## 🚨 Strict Development Protocol

### 1. One Issue at a Time

**Never work on multiple issues simultaneously.**

- Pick ONE GitHub issue
- Complete it fully (code, tests, docs, commit)
- Close it with a comment documenting the outcome
- Only then move to the next issue

If a request implies multiple issues, **stop and ask which single issue to work on first**.

### 2. Clean Commit History

**One issue = one commit** (or a small, logical series if needed).

Commit message format:
```
[#N] Short description of what was done

Optional longer description with:
- What was added/changed
- Why it was done this way
- Any notable decisions
```

Examples:
- `[#99] Add building definitions registry (Markdown + JSON + .tres)`
- `[#100] Add expanded housing building types`

**Never mix unrelated changes in a single commit.**

### 3. Document Outcomes on Tickets

Every closed issue must have a comment documenting:
- What was done (commit hash)
- What worked
- What didn't work (if applicable)
- Any blockers or follow-up needed

Example closing comment:
```markdown
## Complete

**Commit:** abc1234

**What was done:**
- Added X feature
- Updated Y file
- Created Z tests

**Status:** ✅ Complete
```

### 4. Unit Tests Required

**Every PR must include tests validating the functionality.**

- Tests must pass before committing
- Test coverage for changed code is non-negotiable
- If a feature can't be easily tested, document why

### 5. PR Standards

- One PR per issue
- PR title: `[#N] Issue title`
- PR body: links to issue, summary of changes, test notes

---

## Project Structure

```
game/
├── autoload/           # Singletons (GameState, EconomyState, DataRegistry, EventBus)
├── assets/
│   ├── ASSET_REGISTRY.md  # All planned assets with status
│   ├── audio/
│   ├── placeholder/
│   └── ui/
├── data/
│   └── buildings.json     # Machine-readable building definitions (source of truth)
├── docs/
│   └── BUILDING_REFERENCE.md  # Human-readable building docs
├── resources/
│   ├── BuildingData.gd    # Building resource schema
│   ├── AdventurerData.gd  # Adventurer resource schema
│   ├── MobData.gd         # Mob resource schema
│   └── buildings/         # .tres files per building
├── scenes/
│   ├── Main.tscn
│   ├── dungeon/
│   ├── shared/
│   │   └── PlaceholderMesh.gd/.tscn
│   ├── town/
│   └── ui/
├── scripts/
│   ├── systems/
│   │   └── PlaceholderColors.gd
│   ├── entities/
│   ├── buildings/
│   └── dungeon/
└── addons/
```

---

## Key Files

| File | Purpose |
|------|---------|
| `GDD.md` | Game Design Document (source of truth for game design) |
| `MILESTONES.md` | Milestone breakdown with exit criteria |
| `WORKFLOW.md` | Development protocol (this is the short version) |
| `data/buildings.json` | All building data (79 buildings) |
| `docs/BUILDING_REFERENCE.md` | Human-readable building reference |
| `assets/ASSET_REGISTRY.md` | Asset tracking with status |

---

## Milestones

| Milestone | Status | Focus |
|-----------|--------|-------|
| M0 | ✅ Complete | Project scaffolding, autoloads, camera, day/night |
| M1 | In Progress | Core town building loop, placement, upgrades |
| M2 | Not Started | Resources, economy, worker NPCs |
| M3 | Not Started | Adventurer system, parties, guild |
| M4 | Not Started | Dungeon view, Zone 1, combat |
| M5-M10 | Not Started | See MILESTONES.md |

---

## Current State (as of 2026-05-30)

### M1 Progress
- ✅ #99 — Building definitions registry (JSON + Markdown + .tres)
- ✅ #100 — Expanded housing building types
- Remaining M1 issues: #10-16 (building placement, T1 buildings, UI, upgrades, roads, construction, save/load)

### Key Decisions Made
- **Population types:** Townsfolk (generic workers), Specialists (skilled), Adventurers
- **Housing:** Supports mixed occupancy with `capacity_by_type` field
- **Building data:** JSON is source of truth, .tres files generated for Godot runtime

### Pending Issues Created
- #101 — Townsfolk NPC system (M2)

---

## Development Commands

```bash
# Navigate to project
cd /Users/giddy/clawd/projects/dungeon-town/game

# Check issue list for a milestone
gh issue list --repo chrisagiddings/dungeon-town --milestone "M1: Core Town Building Loop"

# Create a branch for an issue
git checkout -b issue-N-short-description

# Commit with issue reference
git commit -m "[#N] Description"

# Push and close issue
git push
gh issue close N --repo chrisagiddings/dungeon-town --reason completed
```

---

## Godot-Specific Notes

- **Autoloads:** GameState, EconomyState, DataRegistry, EventBus (registered in project.godot)
- **Resources:** Use `.tres` files for data (BuildingData, AdventurerData, etc.)
- **Placeholders:** Use `PlaceholderMesh` scene with `PlaceholderColors` for visual placeholders
- **Signals:** Route through `EventBus` — no direct references between systems

---

## Contact

For design questions, cross-system decisions, or clarification on GDD intent, check back with Navi (the orchestrator) or the relevant team lead:
- **Kintaro** — Software & Product
- **Rei** — Creative & Design

---

## Quick Reference: Workflow Checklist

- [ ] Pick ONE issue from the milestone
- [ ] Create feature branch: `git checkout -b issue-N-desc`
- [ ] Implement the change
- [ ] Write and run tests
- [ ] Commit: `git commit -m "[#N] Description"`
- [ ] Push: `git push`
- [ ] Add closing comment to issue with commit hash and outcome
- [ ] Close issue: `gh issue close N --reason completed`
- [ ] Move to next issue

---

*Last updated: 2026-05-30*
*Handoff from: Navi (Chief Orchestrator)*
