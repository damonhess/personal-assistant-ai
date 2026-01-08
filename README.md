# Personal Assistant AI System

## Overview

Enterprise-grade AI Agent platform with persistent memory, task management, and advanced automation. Now integrated with **ARIA** (Adaptive Responsive Intelligent Assistant) for unified multi-interface access.

## System Architecture

- **Core System**: 8 workflows (1 main AI Agent + 7 tools)
- **Advanced Features**: 9 automation workflows
- **ARIA Integration**: 3 unified schema workflows
- **Total**: 20 production-ready workflows

## ARIA Integration

The Personal Assistant now shares a unified database schema with ARIA, enabling:
- **Multi-interface access**: CLI, Web, Telegram (future)
- **Unified memory**: Cross-platform conversation continuity
- **Interface tracking**: Know where each message originated (`cli`, `web`, `telegram`)
- **Web frontend**: Beautiful React UI via ARIA

See [MIGRATION_PLAN.md](/home/damon/aria-assistant/MIGRATION_PLAN.md) for schema consolidation details.

## Quick Start

1. **Read Documentation**: Start with [IMPORT-INSTRUCTIONS.md](IMPORT-INSTRUCTIONS.md)
2. **Import Core System**: Import the 7 tool workflows + main AI Agent
3. **Import Advanced Features**: Add automation and analytics workflows
4. **(Optional) Import ARIA Workflows**: For unified schema support
5. **Deploy**: Activate and test

## Documentation

- **[LANGCHAIN-ARCHITECTURE.md](LANGCHAIN-ARCHITECTURE.md)** - LangChain integration & sophisticated AI architecture
- **[WORKFLOW-STATUS.md](WORKFLOW-STATUS.md)** - Complete system verification report
- **[IMPORT-INSTRUCTIONS.md](IMPORT-INSTRUCTIONS.md)** - Step-by-step deployment guide
- **[COMPLETE-SYSTEM-OVERVIEW.md](COMPLETE-SYSTEM-OVERVIEW.md)** - Full system documentation
- **[ADVANCED-WORKFLOWS-GUIDE.md](advanced/ADVANCED-WORKFLOWS-GUIDE.md)** - Advanced features guide
- **[ARIA MIGRATION_PLAN.md](/home/damon/aria-assistant/MIGRATION_PLAN.md)** - Schema consolidation guide

## Key Features

✅ Native conversation memory (Postgres Chat Memory)
✅ Tool-calling architecture (8 tools)
✅ Coach Mode (cognitive distortion detection)
✅ CBT Therapist Agent (DSM-IV framework)
✅ Automated pattern detection
✅ Proactive deadline monitoring
✅ Task performance analytics
✅ Decision tracking and analysis
✅ Automatic conversation summarization
✅ Weekly database maintenance
✅ Daily automated backups
✅ **NEW**: ARIA unified schema integration
✅ **NEW**: Multi-interface support (CLI/Web)
✅ **NEW**: Cross-platform conversation continuity  

## Cost

~$0.14/month (vs commercial alternatives at $10-34/month)

## Support

- Check n8n execution logs
- Review workflow documentation
- Test workflows individually to isolate issues

---

**Status**: ✅ Production-Ready

**Location**: `/home/damon/personal-assistant-ai/`
