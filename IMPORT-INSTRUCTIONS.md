# Personal Assistant AI - Import Instructions

## Overview

You have a complete **Personal Assistant AI system** with 16 production-ready workflows:
- **1 Main AI Agent** - Orchestrator with Postgres Chat Memory
- **7 Core Tools** - Essential capabilities the AI Agent can call
- **8 Advanced Workflows** - Automation, analytics, and maintenance

This guide will walk you through importing, configuring, and deploying the entire system.

---

## Architecture Summary

```
/home/damon/personal-assistant-ai/
├── ai-agent-main.json           Main AI Agent orchestrator
├── tools/                          Core AI Agent Tools (7)
│   ├── 04-store-memory.json
│   ├── 05-search-memory.json
│   ├── 02-manage-tasks.json
│   ├── 06-calendar-read.json
│   ├── 07-calendar-write.json
│   ├── 01-get-launch-status.json
│   └── 03-context-manager.json
└── advanced/                       Advanced Automation (8)
    ├── 08-pattern-detection-agent.json
    ├── 09-proactive-reminder-agent.json
    ├── 10-decision-tracker.json
    ├── 11-task-analytics.json
    ├── 12-context-summarizer.json
    ├── 13-launch-timeline-manager.json
    ├── 14-memory-consolidation.json
    └── 15-backup-export.json
```

---

## Phase 1: Import Core System (Required)

### Step 1: Import Tool Workflows First

**IMPORTANT**: Import all tool workflows BEFORE importing the main AI Agent workflow, as the main workflow references them.

#### Tool Workflows to Import (in this order):

1. [/home/damon/personal-assistant-ai/tools/01-get-launch-status.json](/home/damon/personal-assistant-ai/tools/01-get-launch-status.json) - Get Launch Status
2. [/home/damon/personal-assistant-ai/tools/02-manage-tasks.json](/home/damon/personal-assistant-ai/tools/02-manage-tasks.json) - Manage Tasks
3. [/home/damon/personal-assistant-ai/tools/03-context-manager.json](/home/damon/personal-assistant-ai/tools/03-context-manager.json) - Context Manager
4. [/home/damon/personal-assistant-ai/tools/04-store-memory.json](/home/damon/personal-assistant-ai/tools/04-store-memory.json) - Store Memory
5. [/home/damon/personal-assistant-ai/tools/05-search-memory.json](/home/damon/personal-assistant-ai/tools/05-search-memory.json) - Search Memory
6. [/home/damon/personal-assistant-ai/tools/06-calendar-read.json](/home/damon/personal-assistant-ai/tools/06-calendar-read.json) - Calendar Read (optional)
7. [/home/damon/personal-assistant-ai/tools/07-calendar-write.json](/home/damon/personal-assistant-ai/tools/07-calendar-write.json) - Calendar Write (optional)

#### Import Process:

For each tool workflow:

1. Open n8n in your browser (https://n8n.leveredgeai.com)
2. Click **Workflows** in the left sidebar
3. Click the **+** button or **Add Workflow**
4. Click the **⋮** menu in the top right
5. Select **Import from File**
6. Select the workflow JSON file
7. Click **Import**
8. **Activate** the workflow (toggle in top right)
9. **Save** the workflow

Repeat for all 7 tool workflows.

---

### Step 2: Import Main AI Agent Workflow

Once all tool workflows are imported and activated:

1. Import [/home/damon/personal-assistant-ai/ai-agent-main.json](/home/damon/personal-assistant-ai/ai-agent-main.json)
2. Follow the same import process as above
3. **DO NOT activate yet** - we need to configure credentials first

---

### Step 3: Configure Credentials

The workflows expect these credentials to already exist in your n8n instance:

#### Required Credentials:

- **supabase-credential** (Postgres)
  - Used by: All tool workflows and Postgres Chat Memory
  - Should already be configured from your existing setup

- **openai-credential** (OpenAI API)
  - Used by: AI Agent, embedding generation in tools
  - Should already be configured from your existing setup

#### Optional Credentials:

- **google-calendar-credential** (Google Calendar OAuth2)
  - Used by: Calendar Read and Calendar Write tools
  - Only needed if you want calendar integration
  - To configure:
    1. Go to **Settings** → **Credentials**
    2. Click **Add Credential**
    3. Search for "Google Calendar"
    4. Follow OAuth2 setup wizard

#### Verify Credentials:

1. Open the Main AI Agent workflow
2. Click on the **AI Agent** node
3. Check that **OpenAI** credential is selected
4. Click on **Postgres Chat Memory** section (within AI Agent node)
5. Check that **Supabase** credential is selected
6. Open each tool workflow and verify credentials are assigned

---

### Step 4: Test the AI Agent

#### Basic Conversation Test:

```bash
curl -X POST "https://n8n.leveredgeai.com/webhook/assistant" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello! Can you tell me about my launch timeline?",
    "session_id": "test-session"
  }'
```

**Expected Response**:
```json
{
  "response": "AI response about launch timeline...",
  "session_id": "test-session",
  "timestamp": "2026-01-05T...",
  "tools_used": ["get_launch_status"]
}
```

#### Task Creation Test:

```bash
curl -X POST "https://n8n.leveredgeai.com/webhook/assistant" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Create a task to test the new AI agent by tomorrow, high priority",
    "session_id": "test-session"
  }'
```

**Expected**: AI creates task using `manage_tasks` tool

#### Memory Test:

```bash
# First message
curl -X POST "https://n8n.leveredgeai.com/webhook/assistant" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I am working on deploying the AI assistant today",
    "session_id": "test-session"
  }'

# Second message (should remember context)
curl -X POST "https://n8n.leveredgeai.com/webhook/assistant" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What was I just working on?",
    "session_id": "test-session"
  }'
```

**Expected**: AI remembers you're deploying the AI assistant

---

### Step 5: Activate Main AI Agent

1. Open [ai-agent-main.json](/home/damon/personal-assistant-ai/ai-agent-main.json) in n8n
2. Verify all 7 tool nodes show connections
3. Click **Activate** toggle in top right
4. Copy the **Webhook URL** from the Webhook node

The webhook URL should be: `https://n8n.leveredgeai.com/webhook/assistant`

---

## Phase 2: Import Advanced Workflows (Recommended)

These workflows add automation, analytics, and maintenance to your system.

### Step 6: Import Automated Workflows

Import these workflows for automatic background operation:

1. [/home/damon/personal-assistant-ai/advanced/08-pattern-detection-agent.json](/home/damon/personal-assistant-ai/advanced/08-pattern-detection-agent.json)
   - **Schedule**: Every 6 hours
   - **Purpose**: Analyze work patterns and productivity trends
   - **Action**: Import → Activate

2. [/home/damon/personal-assistant-ai/advanced/09-proactive-reminder-agent.json](/home/damon/personal-assistant-ai/advanced/09-proactive-reminder-agent.json)
   - **Schedule**: Every 2 hours
   - **Purpose**: Monitor deadlines and send proactive alerts
   - **Action**: Import → Activate

3. [/home/damon/personal-assistant-ai/advanced/12-context-summarizer.json](/home/damon/personal-assistant-ai/advanced/12-context-summarizer.json)
   - **Schedule**: Every 12 hours
   - **Purpose**: Summarize long conversations to reduce token usage
   - **Action**: Import → Activate

4. [/home/damon/personal-assistant-ai/advanced/14-memory-consolidation.json](/home/damon/personal-assistant-ai/advanced/14-memory-consolidation.json)
   - **Schedule**: Weekly
   - **Purpose**: Archive old data and maintain database performance
   - **Action**: Import → Activate

5. [/home/damon/personal-assistant-ai/advanced/15-backup-export.json](/home/damon/personal-assistant-ai/advanced/15-backup-export.json)
   - **Schedule**: Daily
   - **Purpose**: Create comprehensive backups
   - **Action**: Import → Configure backup destination → Activate
   - **Note**: You'll need to add a storage node (Write to File, Google Drive, etc.)

---

### Step 7: Import Optional Tool Workflows

These are tools that can be called manually or added to the AI Agent:

1. [/home/damon/personal-assistant-ai/advanced/10-decision-tracker.json](/home/damon/personal-assistant-ai/advanced/10-decision-tracker.json)
   - **Purpose**: Advanced decision logging and analysis
   - **Action**: Import → Activate
   - **Optional**: Add as 8th tool to AI Agent

2. [/home/damon/personal-assistant-ai/advanced/11-task-analytics.json](/home/damon/personal-assistant-ai/advanced/11-task-analytics.json)
   - **Purpose**: Task performance dashboard
   - **Action**: Import → Activate
   - **Optional**: Add as 9th tool to AI Agent

3. [/home/damon/personal-assistant-ai/advanced/13-launch-timeline-manager.json](/home/damon/personal-assistant-ai/advanced/13-launch-timeline-manager.json)
   - **Purpose**: Update milestones and identify risks
   - **Action**: Import → Activate
   - **Optional**: Add as 10th tool to AI Agent

---

### Step 8: Configure Backup Destination

The Backup & Export workflow needs an output destination:

1. Open [15-backup-export.json](/home/damon/personal-assistant-ai/advanced/15-backup-export.json)
2. After the "Format for Storage" node, add one of:
   - **Write to File** node → Local storage
   - **HTTP Request** node → Cloud storage API (S3, Google Drive, etc.)
   - **Email** node → Send backup as attachment
3. Save and activate

---

## Phase 3: Update CLI and Documentation

### Step 9: Update CLI Tool

Update your CLI tool to use the new webhook:

```bash
# Edit assistant-cli.sh
nano /home/damon/assistant-cli.sh
```

Ensure the webhook URL is: `https://n8n.leveredgeai.com/webhook/assistant`

Test CLI:
```bash
./assistant-cli.sh "Hello! Test the new architecture"
```

---

### Step 10: Create Backup

```bash
./backup-strategy.sh
```

---

## Success Criteria

Your system is production-ready when:

### Core System:
- ✅ All 7 tool workflows are active in n8n
- ✅ Main AI Agent workflow is active
- ✅ Basic conversation works via `/assistant` webhook
- ✅ AI can use tools (check `tools_used` in response)
- ✅ Conversation memory persists across messages (same `session_id`)
- ✅ CLI tool works with new endpoint

### Advanced Features (Recommended):
- ✅ Pattern Detection Agent is running (check patterns table)
- ✅ Proactive Reminder Agent is running (check context table for alerts)
- ✅ Backup workflow is configured and creating backups
- ✅ Memory Consolidation is scheduled

---

## Troubleshooting

### Issue: AI Agent node shows error "No tools connected"

**Solution**: Make sure all 7 tool workflows are imported and activated BEFORE opening the main AI Agent workflow.

### Issue: Postgres Chat Memory connection fails

**Solution**:
1. Verify Supabase credential is configured correctly
2. Check that `conversations` table exists in your database
3. Verify the table has the required columns: `id`, `session_id`, `message`, `role`, `timestamp`

### Issue: Tools return "Workflow not found"

**Solution**: The tool workflow names must match exactly:
- "Tool - Store Memory"
- "Tool - Search Memory"
- "Tool - Manage Tasks"
- "Tool - Calendar Read"
- "Tool - Calendar Write"
- "Tool - Get Launch Status"
- "Tool - Context Manager"

### Issue: AI Agent uses wrong tool or doesn't use tools

**Solution**: Check the tool descriptions in the AI Agent workflow. The AI relies on these descriptions to decide when to use each tool. Make sure they're clear and accurate.

### Issue: Calendar tools fail

**Solution**: Calendar tools are optional. If you don't have Google Calendar configured:
1. The AI will still work without them
2. To disable: Remove the calendar tool nodes from the AI Agent workflow

### Issue: Response times are slow (>10s)

**Solution**:
1. Check if the AI is calling too many tools (check `tools_used` in response)
2. Reduce `maxTokens` in OpenAI Chat Model node (try 500 instead of 1000)
3. Set `temperature` lower (try 0.5 instead of 0.7) for faster responses

### Issue: Backup workflow fails

**Solution**: The backup workflow needs an output destination. Add a Write to File, HTTP Request, or Email node after "Format for Storage".

---

## Next Steps

Once deployment is complete, consider:

1. **Review Analytics**: Check Pattern Detection and Task Analytics insights weekly
2. **Monitor Backups**: Verify daily backups are being created
3. **Optimize Performance**: Review execution logs and adjust automation frequencies
4. **Extend Capabilities**: Add Decision Tracker, Task Analytics, and Launch Timeline Manager as AI Agent tools

For detailed information on each workflow, see:
- [COMPLETE-SYSTEM-OVERVIEW.md](/home/damon/personal-assistant-ai/COMPLETE-SYSTEM-OVERVIEW.md)
- [ADVANCED-WORKFLOWS-GUIDE.md](/home/damon/personal-assistant-ai/advanced/ADVANCED-WORKFLOWS-GUIDE.md)

---

## Support

If you encounter issues:
1. Check n8n execution logs (Executions tab in n8n)
2. Review workflow documentation
3. Test tools individually to isolate issues
4. Check Supabase logs for database errors

Good luck with your deployment! 🚀
