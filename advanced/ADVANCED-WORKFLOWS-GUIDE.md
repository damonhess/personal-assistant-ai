# Advanced Workflows Guide

## Overview

The advanced workflows add sophisticated automation, analytics, and management capabilities to your Personal Assistant AI system. These are **optional but highly recommended** for a production-grade implementation.

---

## Advanced Workflows (8 files)

### 🔍 1. Pattern Detection Agent
**File**: [08-pattern-detection-agent.json](/home/damon/personal-assistant-ai/advanced/08-pattern-detection-agent.json)
**Type**: Automated (runs every 6 hours)

**Purpose**: Analyzes work patterns, productivity trends, and procrastination indicators

**What It Does**:
- Analyzes task completion patterns (hourly/daily)
- Detects procrastination (tasks pending >48h)
- Identifies peak productivity hours
- Analyzes decision-making patterns
- Calculates completion rates and confidence scores

**Outputs**:
- Pattern insights stored in `patterns` table
- Actionable recommendations
- Productivity optimization suggestions

**When to Use**:
- After 2+ weeks of data collection
- For productivity optimization
- To identify work habit patterns

---

### ⏰ 2. Proactive Reminder Agent
**File**: [09-proactive-reminder-agent.json](/home/damon/personal-assistant-ai/advanced/09-proactive-reminder-agent.json)
**Type**: Automated (runs every 2 hours)

**Purpose**: Checks upcoming deadlines and sends proactive alerts

**What It Does**:
- Monitors task deadlines (next 3 days)
- Checks launch timeline milestones (next 5 days)
- Identifies stale context (>48h old)
- Generates alerts by severity (high/medium/low)
- Stores alerts in context for AI Agent access

**Alert Levels**:
- **Critical**: <2h until deadline
- **High**: Overdue tasks/milestones
- **Medium**: <24h deadlines
- **Low**: Upcoming tasks, stale context

**Integration**:
- AI Agent can check `proactive_alerts` context key
- Alerts auto-expire after 24 hours

---

### 📝 3. Decision Tracker
**File**: [10-decision-tracker.json](/home/damon/personal-assistant-ai/advanced/10-decision-tracker.json)
**Type**: Tool (callable by AI Agent)

**Purpose**: Advanced decision logging and analysis

**Operations**:

**log_decision**:
- Record decisions with automatic embedding generation
- Link to tasks and conversations
- Categorize by type (technical/business/personal/strategic)

**review_decisions**:
- Query past decisions with filters
- Filter by category, status, date range
- Includes related task information

**update_decision**:
- Change status (active/revisited/reversed/archived)
- Add update context and rationale

**analyze_patterns**:
- Decision-making analytics by category
- Reversal rate analysis
- Age trends and insights

**Use Cases**:
- Track important choices
- Review past decisions
- Identify decision patterns
- Learn from reversed decisions

---

### 📊 4. Task Analytics Dashboard
**File**: [11-task-analytics.json](/home/damon/personal-assistant-ai/advanced/11-task-analytics.json)
**Type**: Tool (callable by AI Agent or manual)

**Purpose**: Comprehensive task performance analytics

**Metrics Tracked**:
- Overall completion rate (30 days)
- Average completion time
- Overdue task count
- Priority breakdown
- Weekly trends (12 weeks)
- Velocity (tasks/day)
- Tag usage and effectiveness
- Health score (0-100)

**Insights Generated**:
- Completion rate analysis
- Velocity projections
- Priority distribution
- Tag optimization recommendations
- Weekly progress trends

**Use Cases**:
- Weekly review meetings
- Productivity reports
- Resource planning
- Process improvement identification

---

### 💬 5. Context Summarizer
**File**: [12-context-summarizer.json](/home/damon/personal-assistant-ai/advanced/12-context-summarizer.json)
**Type**: Automated (runs every 12 hours)

**Purpose**: Summarize long conversations to reduce context window usage

**What It Does**:
- Finds conversations >20 messages
- Generates AI summaries (GPT-4o-mini)
- Stores summaries as system messages
- Includes: key decisions, tasks, important context, action items

**Benefits**:
- Reduces token usage in chat memory
- Preserves conversation history
- Easier to reference past context
- Improves AI Agent efficiency

**Summary Includes**:
- Key decisions made
- Tasks mentioned
- Important context
- Action items
- Duration and message count

---

### 🚀 6. Launch Timeline Manager
**File**: [13-launch-timeline-manager.json](/home/damon/personal-assistant-ai/advanced/13-launch-timeline-manager.json)
**Type**: Tool (callable by AI Agent)

**Purpose**: Advanced management for the 4-week launch timeline

**Operations**:

**update_milestone**:
- Change week status
- Mark milestones as completed
- Update to at_risk/in_progress

**check_progress**:
- Overall completion percentage
- Per-week status breakdown
- Task completion rates
- Days remaining
- Health status (on_time/overdue/at_risk/on_track)

**identify_risks**:
- Detect overdue milestones
- Find blocked tasks
- Calculate risk levels (critical/high/medium/low)
- Provide risk factors breakdown

**Integration**:
- Linked to tasks table
- Automatic risk detection
- Progress tracking
- AI Agent tool access

---

### 🗄️ 7. Memory Consolidation
**File**: [14-memory-consolidation.json](/home/damon/personal-assistant-ai/advanced/14-memory-consolidation.json)
**Type**: Automated (runs weekly)

**Purpose**: Clean up and archive old data

**Actions Performed**:

1. **Archive Conversations**:
   - >90 days old
   - Not from active sessions (last 30 days)
   - Preserves system messages

2. **Deactivate Stale Patterns**:
   - Not observed in 60 days
   - Mark as inactive (not deleted)

3. **Archive Completed Tasks**:
   - Completed >30 days ago
   - Add `archived: true` flag to metadata
   - Keeps data for analytics

4. **Clean Expired Context**:
   - Remove entries past `expires_at`
   - Frees storage space

5. **Generate Statistics**:
   - Row counts per table
   - Storage sizes
   - Estimated space freed

**Benefits**:
- Reduced database size
- Faster queries
- Better performance
- Organized historical data

---

### 💾 8. Backup & Export System
**File**: [15-backup-export.json](/home/damon/personal-assistant-ai/advanced/15-backup-export.json)
**Type**: Automated (runs daily)

**Purpose**: Create comprehensive daily backups

**Data Exported**:

1. **Conversations** (last 7 days)
   - All messages, sessions, metadata

2. **Tasks** (all)
   - Complete history with tags

3. **Decisions** (all)
   - Full decision logs

4. **Patterns & Context**
   - Active patterns and current context

**Output Format**: JSON
- Structured and versioned
- Includes backup metadata
- Summary statistics
- Size-optimized

**Next Steps** (you'll need to add):
- Write to file system node
- Upload to cloud storage (S3, Google Drive)
- Email notification
- Retention policy (keep last 30 days)

---

## ARIA Unified Schema Workflows (NEW)

These workflows work with the unified ARIA schema for multi-interface support. Use these instead of the original versions when you want:
- Interface source tracking (`cli`, `web`, `telegram`)
- Cross-platform conversation continuity
- Unified memory storage

### 📝 9. Store Memory (ARIA)
**File**: [04-store-memory-aria.json](/home/damon/personal-assistant-ai/tools/04-store-memory-aria.json)
**Type**: Tool (callable by AI Agent)

**Changes from original**:
- Stores to `aria_conversations` + `aria_messages` instead of `conversations`
- Adds `interface_source` field (defaults to `'cli'`)
- New `memory` type for storing to `aria_unified_memory`

**New Input Types**:
- `conversation` - Messages with interface tracking
- `task` - Same as before
- `decision` - Same as before
- `memory` - **NEW**: Store to unified memory (facts, preferences, context)

---

### 🔍 10. Search Memory (ARIA)
**File**: [05-search-memory-aria.json](/home/damon/personal-assistant-ai/tools/05-search-memory-aria.json)
**Type**: Tool (callable by AI Agent)

**Changes from original**:
- Uses `search_aria_messages()` function
- Searches `aria_unified_memory` table
- Can filter by `interface_source`

**New Parameters**:
- `interface_source` (optional): Filter by `'cli'`, `'web'`, or `'telegram'`
- `types`: Now includes `'memory'` for unified memory search

---

### 🗄️ 11. Memory Consolidation (ARIA)
**File**: [14-memory-consolidation-aria.json](/home/damon/personal-assistant-ai/advanced/14-memory-consolidation-aria.json)
**Type**: Automated (runs weekly)

**Changes from original**:
- Archives `aria_conversations` (sets `is_archived = true`)
- Deactivates stale `aria_unified_memory`
- Expires old `aria_sessions`
- Enhanced statistics for all ARIA tables

---

## Import Order

**Important**: Import advanced workflows AFTER core tools and main AI Agent workflow.

### Recommended Import Sequence:

1. Import all core tools (01-07)
2. Import main AI Agent (04)
3. **Then import advanced workflows**:
   - 08-pattern-detection-agent.json
   - 09-proactive-reminder-agent.json
   - 10-decision-tracker.json (if using as AI tool)
   - 11-task-analytics.json (if using as AI tool)
   - 12-context-summarizer.json
   - 13-launch-timeline-manager.json (if using as AI tool)
   - 14-memory-consolidation.json
   - 15-backup-export.json

---

## Configuration Notes

### 1. Pattern Detection Agent
- **No configuration needed** - activate and it runs automatically
- Stores results in `patterns` table
- First run may show limited data (needs 1+ week of history)

### 2. Proactive Reminder Agent
- **No configuration needed** - activate and it runs automatically
- Checks `proactive_alerts` context key for AI Agent integration
- To get alerts in AI responses, AI Agent will automatically check context

### 3. Decision Tracker (Tool)
- **Option A**: Use as standalone (manual calls)
- **Option B**: Add to AI Agent as 8th tool:
  ```
  Tool Name: decision_tracker
  Description: Log, review, and analyze important decisions. Operations: log_decision, review_decisions, update_decision, analyze_patterns.
  ```

### 4. Task Analytics (Tool)
- **Option A**: Run manually for weekly reports
- **Option B**: Add to AI Agent as 9th tool:
  ```
  Tool Name: task_analytics
  Description: Get comprehensive task performance analytics including completion rates, velocity, trends, and health score.
  ```

### 5. Context Summarizer
- **No configuration needed** - activate and it runs automatically
- Requires OpenAI credential (already configured)

### 6. Launch Timeline Manager (Tool)
- **Option A**: Use as standalone
- **Option B**: Add to AI Agent as 10th tool:
  ```
  Tool Name: launch_timeline_manager
  Description: Manage 4-week launch timeline: update milestones, check progress, identify risks.
  ```

### 7. Memory Consolidation
- **No configuration needed** - activate and it runs automatically
- Runs weekly at midnight
- Review first execution to ensure data retention is acceptable

### 8. Backup & Export
- **Configuration needed**: Add output destination
  - Option 1: Write to File node → Local storage
  - Option 2: HTTP Request → Cloud storage API
  - Option 3: Email node → Send backup as attachment
  - Option 4: Google Drive/Dropbox node

---

## Integration with Main AI Agent

To add advanced tools to your AI Agent:

1. Open [ai-agent-main.json](/home/damon/personal-assistant-ai/ai-agent-main.json)
2. Add new "Call n8n Workflow Tool" nodes
3. Connect to AI Agent node's `ai_tool` input
4. Configure each tool:
   - Workflow: Select by name (e.g., "Advanced - Decision Tracker")
   - Name: `decision_tracker`
   - Description: (copy from tool documentation)

**Recommended Tools to Add**:
- decision_tracker (for tracking important choices)
- task_analytics (for weekly reviews)
- launch_timeline_manager (already tracked by get_launch_status, but this adds update capability)

---

## Testing Advanced Workflows

### Test Pattern Detection:
```bash
# Trigger manually (if using webhook trigger)
# Or wait for first scheduled run (6 hours)
# Check patterns table:
# SELECT * FROM patterns ORDER BY last_observed DESC LIMIT 5;
```

### Test Proactive Reminders:
```bash
# Trigger manually or wait 2 hours
# Check context table:
# SELECT * FROM context WHERE context_key = 'proactive_alerts';
```

### Test Decision Tracker:
```bash
curl -X POST "WORKFLOW_WEBHOOK_URL" \
  -d '{
    "operation": "log_decision",
    "title": "Test Decision",
    "decision": "Use advanced workflows",
    "rationale": "Better automation and insights",
    "category": "technical"
  }'
```

### Test Task Analytics:
```bash
# Call workflow or check output in execution log
# Should return JSON with metrics, trends, insights
```

---

## Performance Considerations

### Resource Usage:

| Workflow | Frequency | DB Queries | API Calls | Impact |
|----------|-----------|------------|-----------|--------|
| Pattern Detection | 6h | 3 | 0 | Low |
| Proactive Reminders | 2h | 3 | 0 | Low |
| Context Summarizer | 12h | 1 | 1 (OpenAI) | Medium |
| Memory Consolidation | Weekly | 5 | 0 | Medium |
| Backup & Export | Daily | 5 | 0 | Medium |

**Total Additional Cost**: ~$1-2/month (mostly from Context Summarizer)

### Optimization Tips:
- Disable Context Summarizer if cost is a concern (saves ~$1/month)
- Increase Proactive Reminder interval to 4h if too frequent
- Adjust Memory Consolidation retention periods as needed
- Backup & Export can run less frequently (weekly instead of daily)

---

## Monitoring & Maintenance

### Weekly Checks:
- Review Pattern Detection insights
- Check Proactive Reminder effectiveness
- Verify Memory Consolidation is running
- Ensure Backups are being created

### Monthly Review:
- Analyze Task Analytics trends
- Review Decision Tracker patterns
- Adjust automation frequencies if needed
- Check database size trends

### Quarterly Optimization:
- Fine-tune pattern detection thresholds
- Adjust retention policies
- Review and archive old backups
- Optimize query performance

---

## Troubleshooting

### Pattern Detection shows no insights:
- **Cause**: Not enough historical data
- **Solution**: Wait 1-2 weeks for data accumulation

### Proactive Reminders not appearing:
- **Cause**: No upcoming deadlines or context expires
- **Solution**: Create test tasks with near deadlines

### Context Summarizer not running:
- **Cause**: No conversations >20 messages
- **Solution**: Normal - will run when threshold met

### Memory Consolidation deleting too much:
- **Cause**: Retention periods too aggressive
- **Solution**: Adjust time intervals in queries (90d → 180d, etc.)

### Backup & Export failing:
- **Cause**: Missing output node
- **Solution**: Add Write to File or cloud storage node

---

## Future Enhancements

### Planned Features:
1. **Multi-Agent Orchestration**: Specialist agents for tasks, calendar, etc.
2. **Advanced Pattern ML**: Machine learning for pattern prediction
3. **Workflow Recommendations**: AI-suggested workflow optimizations
4. **Integration Hub**: Slack, Teams, Email notifications
5. **Advanced Analytics Dashboard**: Web UI for visualizations

### Community Contributions:
- Report issues or suggestions
- Share custom analytics queries
- Propose new advanced workflows

---

## Summary

The advanced workflows transform your Personal Assistant from a basic AI chatbot into a **sophisticated, self-maintaining productivity system** with:

✅ Automatic pattern detection and insights
✅ Proactive deadline monitoring
✅ Comprehensive decision tracking
✅ Task performance analytics
✅ Intelligent conversation summarization
✅ Advanced timeline management
✅ Automated data maintenance
✅ Daily backups

**Recommended for**: Production use, long-term productivity tracking, team environments, serious personal productivity systems.

---

Start with: Import and activate Pattern Detection + Proactive Reminders for immediate value!
