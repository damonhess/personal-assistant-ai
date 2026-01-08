# Personal Assistant AI - Quick Reference

Fast reference for common tasks and commands.

---

## 🚀 Quick Start Commands

```bash
# Apply database schema
cd /home/damon/personal-assistant-ai
./apply-schema.sh

# Test the assistant
assistant "Hello! Tell me about my launch timeline."

# Create a task
assistant "Add a high-priority task to finish the setup by today."

# View active tasks
assistant "What tasks do I have?"

# Get launch status
assistant "Show me the 4-week timeline progress."
```

---

## 📁 File Locations

```
/home/damon/personal-assistant-ai/
├── ai-agent-main.json              Main AI orchestrator
├── personal-assistant-schema.sql       Database schema
├── apply-schema.sh                     Apply schema script
│
├── tools/                              7 core tools
│   ├── 04-store-memory.json
│   ├── 05-search-memory.json
│   ├── 02-manage-tasks.json
│   ├── 06-calendar-read.json
│   ├── 07-calendar-write.json
│   ├── 01-get-launch-status.json
│   └── 03-context-manager.json
│
└── advanced/                           8 automation workflows
    ├── 08-pattern-detection-agent.json
    ├── 09-proactive-reminder-agent.json
    ├── 10-decision-tracker.json
    ├── 11-task-analytics.json
    ├── 12-context-summarizer.json
    ├── 13-launch-timeline-manager.json
    ├── 14-memory-consolidation.json
    └── 15-backup-export.json

/home/damon/
├── assistant-cli.sh                    CLI interface
├── backup-strategy.sh                  Backup script
└── restore-backup.sh                   Restore script
```

---

## 🔧 CLI Commands

```bash
# Basic conversation
assistant "your message here"

# Interactive mode
assistant -i

# Session-based conversation
assistant -s my-session "your message"

# Direct webhook test
curl -X POST "https://n8n.leveredgeai.com/webhook/assistant" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!", "session_id": "test"}'
```

---

## 🗄️ Database Quick Access

```bash
# Connect to database
docker exec -it supabase-db psql -U postgres -d postgres

# View tables
docker exec supabase-db psql -U postgres -d postgres -c "\dt"

# Check recent conversations
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT session_id, role, LEFT(message, 50) as message, timestamp
  FROM conversations
  ORDER BY timestamp DESC
  LIMIT 10;
"

# View active tasks
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT title, status, priority, deadline
  FROM tasks
  WHERE status IN ('pending', 'in_progress')
  ORDER BY deadline;
"

# Check launch timeline
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT * FROM launch_progress;
"

# View detected patterns
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT pattern_type, pattern_name, confidence, occurrences
  FROM active_patterns
  ORDER BY confidence DESC;
"
```

---

## 🔑 Credentials Setup

### Supabase (Postgres)
```
Name: Supabase
Host: supabase-db
Database: postgres
User: postgres
Password: [from /home/damon/supabase/.env]
Port: 5432
SSL: Disable
```

### OpenAI API
```
Name: OpenAI API
API Key: [your OpenAI API key]
```

### Google Calendar (Optional)
```
Type: OAuth2
Follow n8n wizard for Google Calendar setup
```

---

## 📊 n8n Workflow URLs

```
Main AI Agent: https://n8n.leveredgeai.com/workflow/[ID]
Webhook URL: https://n8n.leveredgeai.com/webhook/assistant
```

---

## 💾 Backup & Restore

```bash
# Create backup
cd /home/damon
./backup-strategy.sh

# List backups
ls -lh ~/backups/personal-assistant/

# Restore from backup
./restore-backup.sh [backup-date]

# Example
./restore-backup.sh 2026-01-05_03-00-00
```

---

## 🔍 Troubleshooting

### Database Not Running
```bash
cd /home/damon/supabase
docker compose up -d
docker ps | grep supabase-db
```

### n8n Workflows Failing
```bash
# Check n8n logs
docker logs n8n

# Check workflow execution logs in n8n UI
# Go to: Executions tab
```

### OpenAI API Errors
```bash
# Test API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Reset Database (⚠️ DESTRUCTIVE)
```bash
cd /home/damon/personal-assistant-ai
docker exec supabase-db psql -U postgres -d postgres -c "
  DROP TABLE IF EXISTS conversations CASCADE;
  DROP TABLE IF EXISTS tasks CASCADE;
  DROP TABLE IF EXISTS decisions CASCADE;
  DROP TABLE IF EXISTS patterns CASCADE;
  DROP TABLE IF EXISTS context CASCADE;
  DROP TABLE IF EXISTS launch_timeline CASCADE;
"
./apply-schema.sh
```

---

## 📈 Monitoring

### Check System Health
```bash
# Database size
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT pg_size_pretty(pg_database_size('postgres'));
"

# Table sizes
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
  FROM pg_tables
  WHERE tablename IN ('conversations', 'tasks', 'decisions', 'patterns', 'context', 'launch_timeline')
  ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"

# Conversation count
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT COUNT(*) FROM conversations;
"

# Task statistics
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT status, COUNT(*)
  FROM tasks
  GROUP BY status;
"
```

### View Recent Activity
```bash
# Last 10 conversations
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT timestamp, role, LEFT(message, 60)
  FROM conversations
  ORDER BY timestamp DESC
  LIMIT 10;
"

# Recent task updates
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT title, status, updated_at
  FROM tasks
  ORDER BY updated_at DESC
  LIMIT 10;
"

# Latest patterns
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT pattern_name, last_observed, occurrences
  FROM patterns
  WHERE is_active = true
  ORDER BY last_observed DESC
  LIMIT 10;
"
```

---

## ⚙️ Configuration Quick Tweaks

### Change AI Agent Model
1. Open [ai-agent-main.json](ai-agent-main.json) in n8n
2. Edit "OpenAI Chat Model" node
3. Change model: `gpt-4o-mini` → `gpt-4o` (slower, smarter) or `gpt-3.5-turbo` (faster, cheaper)

### Adjust Context Window
1. Open [ai-agent-main.json](ai-agent-main.json)
2. Edit "AI Agent" node
3. Find "Postgres Chat Memory" section
4. Change "Context Window Size": 10 → 5 (faster) or 20 (more context)

### Modify Automation Frequency

**Pattern Detection** (default: 6h)
```
File: advanced/08-pattern-detection-agent.json
Node: Schedule Trigger
Change: daysInterval or add hoursInterval
```

**Proactive Reminders** (default: 2h)
```
File: advanced/09-proactive-reminder-agent.json
Node: Schedule Trigger
Change: hoursInterval value
```

---

## 🎯 Cost Optimization

### Reduce OpenAI Costs
1. Use `gpt-4o-mini` instead of `gpt-4o` (10x cheaper)
2. Reduce max_tokens in AI Agent (1000 → 500)
3. Enable Context Summarizer to reduce conversation length
4. Lower vector search limits (10 → 5 results)

### Current Cost Estimate
- Embeddings: ~$0.02/month
- Chat: ~$0.24/month
- **Total: ~$0.26/month** (with moderate usage)

---

## 📚 Documentation Links

- [README.md](README.md) - Overview
- [IMPORT-INSTRUCTIONS.md](IMPORT-INSTRUCTIONS.md) - Deployment guide
- [SETUP-GUIDE.md](SETUP-GUIDE.md) - Complete setup instructions
- [COMPLETE-SYSTEM-OVERVIEW.md](COMPLETE-SYSTEM-OVERVIEW.md) - Full documentation
- [ADVANCED-WORKFLOWS-GUIDE.md](advanced/ADVANCED-WORKFLOWS-GUIDE.md) - Advanced features

---

## 🆘 Emergency Commands

### Stop Everything
```bash
# Stop n8n
docker stop n8n

# Stop Supabase
cd /home/damon/supabase
docker compose down
```

### Start Everything
```bash
# Start Supabase
cd /home/damon/supabase
docker compose up -d

# Start n8n (if separate container)
docker start n8n

# Verify
docker ps
```

### Full System Reset (⚠️ NUCLEAR OPTION)
```bash
# Backup first!
./backup-strategy.sh

# Reset database
cd /home/damon/supabase
docker compose down -v
docker compose up -d

# Reapply schema
cd /home/damon/personal-assistant-ai
./apply-schema.sh

# Reimport workflows in n8n UI
```

---

## ✅ Health Check Checklist

```bash
# 1. Database running
docker ps | grep supabase-db

# 2. Tables exist
docker exec supabase-db psql -U postgres -d postgres -c "\dt" | grep -E "conversations|tasks"

# 3. n8n accessible
curl -s https://n8n.leveredgeai.com/healthz

# 4. Workflows active (check n8n UI)
# Go to: Workflows → Check green toggles

# 5. CLI working
assistant "Health check test"

# 6. Backups recent
ls -lt ~/backups/personal-assistant/ | head -5
```

---

**Need more help?** Check the full documentation or n8n execution logs.
