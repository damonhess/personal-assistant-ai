# Personal Development Environment

Home directory for Damon's development projects and automation systems.

---

## 🤖 Personal Assistant AI

**Location**: [personal-assistant-ai/](personal-assistant-ai/)

Enterprise-grade AI Agent platform with persistent memory, task management, and advanced automation.

**Quick Start**: [personal-assistant-ai/IMPORT-INSTRUCTIONS.md](personal-assistant-ai/IMPORT-INSTRUCTIONS.md)

**Features**:
- ✅ Native conversation memory (Postgres Chat Memory)
- ✅ Tool-calling architecture (8 tools)
- ✅ Coach Mode (cognitive distortion detection)
- ✅ CBT Therapist Agent (DSM-IV framework)
- ✅ Automated pattern detection and analytics
- ✅ Proactive deadline monitoring
- ✅ Daily backups and maintenance
- ✅ Cost: ~$0.14/month

**System**: 17 n8n workflows (8 core + 9 advanced)

---

## 📁 Project Structure

```
/home/damon/
├── personal-assistant-ai/       AI Agent system (16 workflows)
│   ├── tools/                   7 core AI tools
│   ├── advanced/                8 automation workflows
│   ├── ai-agent-main.json    Main orchestrator
│   ├── personal-assistant-schema.sql
│   ├── apply-schema.sh
│   └── *.md                     Documentation
│
├── supabase/                    Local Supabase instance (Docker)
├── assistant-cli.sh             AI assistant CLI tool
├── backup-strategy.sh           Backup automation
└── restore-backup.sh            Restore from backup
```

---

## 🚀 Quick Commands

### Personal Assistant

```bash
# Talk to your AI assistant
assistant "What's on my schedule today?"

# Create tasks
assistant "Add a task to review the deployment logs by 5pm."

# Get status
assistant "Show me my 4-week launch timeline."
```

### Database Access

```bash
# Connect to Supabase
docker exec -it supabase-db psql -U postgres -d postgres

# View active tasks
docker exec supabase-db psql -U postgres -d postgres -c "
  SELECT * FROM tasks WHERE status = 'pending';
"
```

### Backups

```bash
# Create backup
./backup-strategy.sh

# Restore backup
./restore-backup.sh 2026-01-05_03-00-00
```

---

## 🔧 Services

### Supabase (PostgreSQL + Vector Search)
- **Location**: `/home/damon/supabase/`
- **Access**: `docker exec -it supabase-db psql -U postgres`
- **Used by**: Personal Assistant AI for data storage

### n8n (Workflow Automation)
- **URL**: https://n8n.leveredgeai.com
- **Workflows**: Personal Assistant AI (16 workflows)
- **Webhook**: https://n8n.leveredgeai.com/webhook/assistant

---

## 📚 Documentation

### Personal Assistant AI
- [IMPORT-INSTRUCTIONS.md](personal-assistant-ai/IMPORT-INSTRUCTIONS.md) - Deployment guide
- [COMPLETE-SYSTEM-OVERVIEW.md](personal-assistant-ai/COMPLETE-SYSTEM-OVERVIEW.md) - Full documentation
- [SETUP-GUIDE.md](personal-assistant-ai/SETUP-GUIDE.md) - Setup instructions
- [QUICK-REFERENCE.md](personal-assistant-ai/QUICK-REFERENCE.md) - Command reference
- [ADVANCED-WORKFLOWS-GUIDE.md](personal-assistant-ai/advanced/ADVANCED-WORKFLOWS-GUIDE.md) - Advanced features

### General
- [FULL_STACK_DEPLOYMENT.md](FULL_STACK_DEPLOYMENT.md) - Full stack setup
- [SERVER_HARDENING.md](SERVER_HARDENING.md) - Security configuration

---

## 🔒 Security

All services run locally with Cloudflare Access protection:
- n8n accessible via Cloudflare Zero Trust
- Supabase runs in Docker (local only)
- API keys stored in n8n credentials (encrypted)

---

## 💾 Backups

Automated backups configured for:
- Personal Assistant AI database (daily via n8n workflow)
- Manual backup script: `./backup-strategy.sh`
- Backup location: `~/backups/personal-assistant/`

---

## 🆘 Quick Troubleshooting

### Supabase Not Running
```bash
cd /home/damon/supabase
docker compose up -d
```

### n8n Access Issues
- Check Cloudflare Access configuration
- Verify authentication token

### Assistant CLI Not Working
```bash
# Reinstall
sudo ln -sf /home/damon/assistant-cli.sh /usr/local/bin/assistant
sudo chmod +x /usr/local/bin/assistant

# Test
assistant "Hello"
```

---

## 📊 System Stats

**Personal Assistant AI**:
- 17 workflows (8 core + 9 advanced)
- ~130 n8n nodes total
- 7 database tables (includes mental_health_patterns)
- Cost: ~$0.14/month (OpenAI API only)

**Infrastructure**:
- Supabase: Self-hosted (Docker)
- n8n: Self-hosted with Cloudflare Access
- Storage: ~100MB for AI assistant data

---

## 🎯 Next Steps

1. **If setting up Personal Assistant AI**: Follow [personal-assistant-ai/IMPORT-INSTRUCTIONS.md](personal-assistant-ai/IMPORT-INSTRUCTIONS.md)
2. **If system is already running**: Use `assistant` CLI or check [personal-assistant-ai/QUICK-REFERENCE.md](personal-assistant-ai/QUICK-REFERENCE.md)

---

**Current Environment**: Production-ready AI assistant system with enterprise-grade automation.
