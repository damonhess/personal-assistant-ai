# Personal Assistant AI - Setup Guide

Complete guide to setting up your enterprise-grade AI assistant system.

---

## Prerequisites

- ✅ Supabase running locally (Docker)
- ✅ n8n running at https://n8n.leveredgeai.com
- ✅ OpenAI API key
- ✅ (Optional) Google Calendar API credentials

---

## Phase 1: Database Setup (5 minutes)

### Step 1: Apply Database Schema

```bash
cd /home/damon/personal-assistant-ai
./apply-schema.sh
```

This creates:
- 6 core tables (conversations, tasks, decisions, patterns, context, launch_timeline)
- Vector search functions
- Automated triggers
- Analytics views

### Step 2: Verify Schema

```bash
docker exec supabase-db psql -U postgres -d postgres -c "\dt" | grep -E "conversations|tasks|decisions|patterns|context|launch_timeline"
```

You should see all 6 tables.

### Step 3: Initialize Launch Timeline

```bash
docker exec -i supabase-db psql -U postgres -d postgres << 'EOF'
-- Set launch start date
INSERT INTO context (context_key, context_type, context_value) VALUES
('launch_start_date', 'launch', to_jsonb(CURRENT_DATE::text))
ON CONFLICT (context_key) DO UPDATE
SET context_value = to_jsonb(CURRENT_DATE::text);

-- Add sample milestones
INSERT INTO launch_timeline (week_number, milestone, description, target_date, status) VALUES
(1, 'System Setup', 'Database and core workflows deployed', CURRENT_DATE + INTERVAL '7 days', 'in_progress'),
(2, 'Core Features', 'All 7 tools operational', CURRENT_DATE + INTERVAL '14 days', 'pending'),
(3, 'Advanced Features', 'Automation and analytics running', CURRENT_DATE + INTERVAL '21 days', 'pending'),
(4, 'Production Ready', 'Full deployment and testing complete', CURRENT_DATE + INTERVAL '28 days', 'pending')
ON CONFLICT (week_number, milestone) DO NOTHING;
EOF
```

---

## Phase 2: Import Workflows (15 minutes)

Follow the detailed instructions in [IMPORT-INSTRUCTIONS.md](IMPORT-INSTRUCTIONS.md).

**Quick summary:**
1. Import 7 tool workflows first
2. Import main AI Agent workflow
3. Configure credentials (Supabase, OpenAI)
4. Activate all workflows
5. (Optional) Import 8 advanced workflows

---

## Phase 3: Configure CLI (2 minutes)

### Update CLI Script

The assistant CLI should already exist at `/home/damon/assistant-cli.sh`.

Verify the webhook URL:
```bash
grep "WEBHOOK_URL=" /home/damon/assistant-cli.sh
```

Should be: `https://n8n.leveredgeai.com/webhook/assistant`

### Install CLI

```bash
sudo ln -sf /home/damon/assistant-cli.sh /usr/local/bin/assistant
sudo chmod +x /usr/local/bin/assistant
```

---

## Phase 4: Test the System (5 minutes)

### Test 1: Basic Conversation

```bash
assistant "Hello! I'm setting up my Personal Assistant AI today."
```

Expected: Friendly response acknowledging the setup.

### Test 2: Task Creation

```bash
assistant "Create a high-priority task to complete the system setup by end of today."
```

Expected: Confirms task creation and shows task details.

### Test 3: Memory Persistence

```bash
# First message
assistant "My current project is deploying the Personal Assistant AI."

# Second message (new session)
assistant "What project am I working on?"
```

Expected: Remembers the project from the first message.

### Test 4: Launch Timeline

```bash
assistant "Show me my 4-week launch timeline."
```

Expected: Displays the milestones you created.

---

## Phase 5: Advanced Configuration (Optional)

### Enable Automated Backups

Edit the Backup workflow to add output destination:

1. Open [15-backup-export.json](advanced/15-backup-export.json) in n8n
2. After "Format for Storage" node, add:
   - **Write to File** node for local storage, OR
   - **HTTP Request** node for cloud storage (S3, Google Drive), OR
   - **Email** node to send backups via email
3. Save and activate

Configure cron for additional backup:
```bash
crontab -e
# Add daily backup at 3 AM
0 3 * * * /home/damon/backup-strategy.sh >> /var/log/assistant-backup.log 2>&1
```

### Add Optional Tools to AI Agent

To add Decision Tracker, Task Analytics, or Launch Timeline Manager to the AI Agent:

1. Open [ai-agent-main.json](ai-agent-main.json) in n8n
2. Add a new "Call n8n Workflow Tool" node
3. Configure:
   - **Workflow**: Select the advanced workflow by name
   - **Tool Name**: `decision_tracker`, `task_analytics`, or `launch_timeline_manager`
   - **Description**: Copy from [ADVANCED-WORKFLOWS-GUIDE.md](advanced/ADVANCED-WORKFLOWS-GUIDE.md)
4. Connect to AI Agent node's `ai_tool` input
5. Save

---

## Understanding the Architecture

### Core System (8 workflows)

**Main AI Agent** ([ai-agent-main.json](ai-agent-main.json))
- Orchestrates all interactions
- Uses Postgres Chat Memory for conversation persistence
- Calls 7 tools as needed
- Webhook: `/assistant`

**7 Core Tools:**
1. **Store Memory** - Save conversations, tasks, decisions with embeddings
2. **Search Memory** - Semantic search across all stored data
3. **Manage Tasks** - Full CRUD operations for tasks
4. **Calendar Read** - Fetch Google Calendar events
5. **Calendar Write** - Create/update/delete calendar events
6. **Get Launch Status** - Check 4-week timeline progress
7. **Context Manager** - Manage working context and focus

### Advanced System (8 workflows)

**Automated Workflows:**
- **Pattern Detection** - Analyzes productivity trends (every 6h)
- **Proactive Reminders** - Monitors deadlines (every 2h)
- **Context Summarizer** - Reduces token usage (every 12h)
- **Memory Consolidation** - Archives old data (weekly)
- **Backup & Export** - Daily backups

**Optional Tools:**
- **Decision Tracker** - Advanced decision logging
- **Task Analytics** - Performance dashboard
- **Launch Timeline Manager** - Milestone management

---

## Customization

### Adjust AI Agent Personality

Edit the System Prompt in the AI Agent node:

```
You are a highly capable personal assistant helping manage a 4-week product launch timeline.

Current Date: {{ $now.format('yyyy-MM-dd') }}
Session ID: {{ $json.session_id }}

Your personality:
- Professional but friendly
- Proactive and anticipatory
- Detail-oriented
- Focus on productivity and outcomes

[Rest of system prompt...]
```

### Modify Automation Frequencies

**Pattern Detection**: Change from 6h to 12h
- Open [08-pattern-detection-agent.json](advanced/08-pattern-detection-agent.json)
- Edit Schedule Trigger node
- Change `daysInterval` or add `hoursInterval`

**Proactive Reminders**: Change from 2h to 4h
- Open [09-proactive-reminder-agent.json](advanced/09-proactive-reminder-agent.json)
- Edit Schedule Trigger node

### Adjust Memory Retention

**Memory Consolidation**: Change retention periods
- Open [14-memory-consolidation.json](advanced/14-memory-consolidation.json)
- Edit SQL queries:
  - Change `90 days` (conversations) to desired retention
  - Change `60 days` (patterns) to desired retention
  - Change `30 days` (tasks) to desired retention

---

## Troubleshooting

### Database Connection Issues

```bash
# Check Supabase is running
docker ps | grep supabase-db

# If not running
cd /home/damon/supabase
docker compose up -d

# Test connection
docker exec supabase-db psql -U postgres -d postgres -c "SELECT 1;"
```

### n8n Workflows Not Activating

- Check n8n execution logs (Executions tab)
- Verify all credentials are configured
- Ensure tool workflows are activated before main AI Agent
- Check for missing dependencies

### OpenAI API Errors

```bash
# Test API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"

# Check quota
# Visit: https://platform.openai.com/account/usage
```

### Vector Search Returns No Results

- Need minimum ~10-20 entries for meaningful results
- Lower similarity threshold in search queries (try 0.5 instead of 0.7)
- Verify embeddings are being generated (check conversations.embedding column)

### Slow Response Times

- Use `gpt-4o-mini` instead of `gpt-4o` (20x faster, 10x cheaper)
- Reduce `maxTokens` in AI Agent (try 500 instead of 1000)
- Reduce context window size in Postgres Chat Memory (try 5 instead of 10)
- Lower similarity search limits

---

## Cost Estimation

### Monthly Costs (Moderate Usage)

**OpenAI API** (~500 messages/month):
- Embeddings: ~$0.02
- Chat completions (gpt-4o-mini): ~$0.24
- Context Summarizer: ~$0.01
- **Total: ~$0.27/month**

**Infrastructure** (Self-hosted):
- Supabase: $0 (self-hosted via Docker)
- n8n: $0 (self-hosted)
- Storage: ~100MB/month
- **Total: $0**

**Grand Total: ~$0.27/month**

Compare to commercial alternatives:
- Motion: $34/month
- Reclaim: $25/month
- Notion AI: $10/month

**Savings: $10-34/month** (99% cost reduction)

---

## Scaling Considerations

### At 1,000+ Conversations

1. **Enable Context Summarizer** (if not already)
   - Reduces token usage by 60-80%
   - Keeps response times fast

2. **Optimize Vector Indexes**
   ```sql
   -- Recreate indexes with better parameters
   DROP INDEX IF EXISTS idx_conversations_embedding;
   CREATE INDEX idx_conversations_embedding ON conversations
   USING ivfflat (embedding vector_cosine_ops)
   WITH (lists = 100);
   ```

3. **Run Memory Consolidation More Frequently**
   - Change from weekly to daily
   - Adjust retention periods if needed

### At 10,000+ Conversations

1. **Implement Conversation Archiving**
   - Move conversations >6 months to archive table
   - Keep recent data in main table for speed

2. **Add Read Replicas** (if needed)
   - Supabase supports read replicas
   - Route heavy analytics to replicas

3. **Consider Database Partitioning**
   - Partition conversations by month
   - Improves query performance

---

## Migration & Portability

### Export Everything

```bash
# Full backup
./backup-strategy.sh

# Creates:
# - SQL dump (complete database)
# - CSV exports (portable format)
# - Workflow JSON files
# - Compressed archive
```

### Migrate to Different Platform

Your data is platform-agnostic:

**Database**: Standard PostgreSQL + pgvector
- Works with any Postgres provider
- Migrate with standard pg_dump/pg_restore

**Workflows**: Exportable JSON
- Can be recreated in other automation tools
- Logic is straightforward and well-documented

**Embeddings**: OpenAI format (1536 dimensions)
- Compatible with any vector database
- Can be reused with other LLM tools

---

## Next Steps

### Week 1: Basic Usage
- Use the assistant daily for conversations
- Create tasks as they come up
- Review what the AI remembers

### Week 2: Pattern Discovery
- Review Pattern Detection insights
- Check Task Analytics dashboard
- Identify productivity trends

### Week 3: Optimization
- Adjust AI personality based on usage
- Fine-tune automation frequencies
- Add custom workflows for specific needs

### Week 4: Production Hardening
- Verify backups are working
- Review all analytics
- Document any customizations
- Consider adding additional interfaces (Slack, web)

---

## Additional Resources

- **[IMPORT-INSTRUCTIONS.md](IMPORT-INSTRUCTIONS.md)** - Detailed import steps
- **[COMPLETE-SYSTEM-OVERVIEW.md](COMPLETE-SYSTEM-OVERVIEW.md)** - Full architecture documentation
- **[ADVANCED-WORKFLOWS-GUIDE.md](advanced/ADVANCED-WORKFLOWS-GUIDE.md)** - Advanced features guide
- **[personal-assistant-schema.sql](personal-assistant-schema.sql)** - Database schema reference

---

## Success Checklist

- [ ] Database schema applied
- [ ] All 7 tool workflows imported and active
- [ ] Main AI Agent workflow active
- [ ] Credentials configured (Supabase, OpenAI)
- [ ] CLI installed and working
- [ ] Basic conversation test passed
- [ ] Task creation test passed
- [ ] Memory persistence verified
- [ ] Launch timeline initialized
- [ ] At least 3 advanced workflows active
- [ ] Backup system configured
- [ ] First backup completed

---

**Ready to launch!** 🚀

For support, check execution logs in n8n and review the documentation files.
