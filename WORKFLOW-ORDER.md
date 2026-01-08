# Workflow Implementation Order

## Overview

All 16 workflows are numbered in the order they should be implemented:

---

## Phase 1: Core Tools (7 workflows)

Import these **FIRST**, in numeric order. The main AI Agent depends on these tools.

| # | Filename | Tool Name | Purpose |
|---|----------|-----------|---------|
| 01 | [01-get-launch-status.json](tools/01-get-launch-status.json) | Get Launch Status | Check 4-week launch timeline |
| 02 | [02-manage-tasks.json](tools/02-manage-tasks.json) | Manage Tasks | Create, update, list tasks |
| 03 | [03-context-manager.json](tools/03-context-manager.json) | Context Manager | Get/set working context |
| 04 | [04-store-memory.json](tools/04-store-memory.json) | Store Memory | Save conversations with embeddings |
| 05 | [05-search-memory.json](tools/05-search-memory.json) | Search Memory | Semantic search across memories |
| 06 | [06-calendar-read.json](tools/06-calendar-read.json) | Calendar Read | Fetch calendar events (optional) |
| 07 | [07-calendar-write.json](tools/07-calendar-write.json) | Calendar Write | Create/modify events (optional) |

**Import Order Rationale:**
- Independent tools first (get-launch-status, manage-tasks, context-manager)
- Memory tools next (store, search) - can work together
- Calendar tools last (optional, requires Google Calendar setup)

---

## Phase 2: Main AI Agent (1 workflow)

Import this **AFTER** all tools are imported and activated.

| # | Filename | Purpose |
|---|----------|---------|
| - | [ai-agent-main.json](ai-agent-main.json) | Main orchestrator with Postgres Chat Memory |

**Note**: No number on main agent - it orchestrates all numbered tools.

---

## Phase 3: Advanced Automation (9 workflows)

Import these **AFTER** the main agent is working. These run in the background.

| # | Filename | Purpose | Schedule |
|---|----------|---------|----------|
| 08 | [08-pattern-detection-agent.json](advanced/08-pattern-detection-agent.json) | Detect behavioral patterns | Every 6 hours |
| 09 | [09-proactive-reminder-agent.json](advanced/09-proactive-reminder-agent.json) | Proactive deadline reminders | Every 4 hours |
| 10 | [10-decision-tracker.json](advanced/10-decision-tracker.json) | Track important decisions | On-demand tool |
| 11 | [11-task-analytics.json](advanced/11-task-analytics.json) | Task completion analytics | On-demand tool |
| 12 | [12-context-summarizer.json](advanced/12-context-summarizer.json) | Summarize old conversations | Daily at 2 AM |
| 13 | [13-launch-timeline-manager.json](advanced/13-launch-timeline-manager.json) | Update launch progress | On-demand tool |
| 14 | [14-memory-consolidation.json](advanced/14-memory-consolidation.json) | Consolidate memories | Weekly (Sunday 3 AM) |
| 15 | [15-backup-export.json](advanced/15-backup-export.json) | Export data backups | Daily at 3 AM |
| 16 | [16-cbt-therapist-agent.json](advanced/16-cbt-therapist-agent.json) | CBT Therapist Agent | On-demand tool |

---

## Quick Reference

**Total Workflows**: 17
- **Core System**: 8 (7 tools + 1 main agent)
- **Advanced**: 9 (automation + analytics + mental health)

**Import Order**:
1. Tools (01-07) → 2. Main Agent → 3. Advanced (08-16)

**Documentation**: See [IMPORT-INSTRUCTIONS.md](IMPORT-INSTRUCTIONS.md) for detailed setup guide.

---

**Last Updated**: 2026-01-05
