# Personal Assistant AI Agent - n8n Architecture

## Overview

This document describes the n8n workflow architecture for a Personal Assistant AI with persistent memory, learning capabilities, and context awareness.

## Architecture Principles

1. **Modular Design**: Separate workflows for different functions
2. **Persistent Memory**: All interactions stored in Supabase
3. **Semantic Search**: Vector embeddings for intelligent recall
4. **Pattern Learning**: Automated detection of work patterns
5. **Migration-Ready**: Data and workflows are portable

---

## Core Workflows

### 1. **Main Agent Orchestrator**
**Workflow Name**: `Personal Assistant - Main`
**Trigger**: Webhook or Chat Interface
**Purpose**: Central hub that routes requests to specialized sub-workflows

#### Flow:
```
User Input → Extract Intent → Route to Handler → Generate Response → Store Interaction
```

#### Nodes:
1. **Webhook/Chat Trigger** - Receives user messages
2. **Context Loader** - Fetches current context from Supabase
3. **Intent Classifier** - Determines what type of request this is:
   - Task management
   - Decision query
   - Pattern insight
   - General conversation
   - Memory recall
4. **Router (Switch)** - Routes to appropriate sub-workflow
5. **Response Generator** - AI node with context-aware prompt
6. **Memory Saver** - Stores conversation to Supabase
7. **Pattern Detector** - Checks for behavioral patterns

#### System Prompt Template:
```
You are a personal assistant AI with persistent memory. You help the user manage their 4-week launch timeline, remember past decisions, and provide insights about their work patterns.

Current Context:
{{$json.context}}

Recent Conversations:
{{$json.recent_history}}

Active Tasks:
{{$json.active_tasks}}

Your capabilities:
- Remember all past conversations and decisions
- Track tasks and deadlines
- Identify work patterns and procrastination
- Answer questions about past decisions
- Provide insights about productivity

User's 4-Week Launch Plan:
{{$json.launch_timeline}}

Current Time: {{$now}}

Respond naturally and proactively remind the user of:
- Approaching deadlines
- Patterns you've noticed
- Decisions that might be relevant
```

---

### 2. **Memory Storage Workflow**
**Workflow Name**: `Memory - Store`
**Trigger**: Called by other workflows
**Purpose**: Save conversations, tasks, decisions to Supabase with embeddings

#### Flow:
```
Input Data → Generate Embedding → Store in Supabase → Return Success
```

#### Nodes:
1. **Receive Data** (Execute Workflow Trigger)
2. **Determine Type** (Switch: conversation/task/decision)
3. **Generate Embedding** (OpenAI Embeddings API)
4. **Store in Supabase** (Postgres node)
   - For conversations: INSERT into `conversations`
   - For tasks: INSERT into `tasks`
   - For decisions: INSERT into `decisions`
5. **Return Confirmation**

#### Example Supabase Queries:

**Store Conversation:**
```sql
INSERT INTO conversations (session_id, message, role, embedding, metadata)
VALUES (
    '{{$json.session_id}}',
    '{{$json.message}}'::jsonb,
    '{{$json.role}}',
    '{{$json.embedding}}',
    '{{$json.metadata}}'::jsonb
)
RETURNING id;
```

**Store Task:**
```sql
INSERT INTO tasks (title, description, status, priority, deadline, embedding, tags)
VALUES (
    '{{$json.title}}',
    '{{$json.description}}',
    '{{$json.status}}',
    '{{$json.priority}}',
    '{{$json.deadline}}'::timestamptz,
    '{{$json.embedding}}',
    '{{$json.tags}}'::text[]
)
RETURNING id;
```

**Store Decision:**
```sql
INSERT INTO decisions (title, description, decision, rationale, embedding, category)
VALUES (
    '{{$json.title}}',
    '{{$json.description}}',
    '{{$json.decision}}',
    '{{$json.rationale}}',
    '{{$json.embedding}}',
    '{{$json.category}}'
)
RETURNING id;
```

---

### 3. **Memory Retrieval Workflow**
**Workflow Name**: `Memory - Retrieve`
**Trigger**: Called by other workflows
**Purpose**: Fetch relevant context using semantic search

#### Flow:
```
Query → Generate Embedding → Vector Search → Rank Results → Return
```

#### Nodes:
1. **Receive Query** (Execute Workflow Trigger)
2. **Generate Query Embedding** (OpenAI Embeddings API)
3. **Semantic Search** (Postgres node - calls search functions)
4. **Fetch Related Context** (Get tasks, decisions, patterns)
5. **Rank and Filter**
6. **Format for LLM**
7. **Return Results**

#### Supabase Queries:

**Search Similar Conversations:**
```sql
SELECT * FROM search_similar_conversations(
    '{{$json.query_embedding}}',
    0.7,  -- similarity threshold
    10    -- max results
);
```

**Get Active Tasks:**
```sql
SELECT * FROM tasks
WHERE status IN ('pending', 'in_progress')
ORDER BY
    CASE priority
        WHEN 'urgent' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END,
    deadline NULLS LAST
LIMIT 20;
```

**Get Recent Decisions:**
```sql
SELECT * FROM recent_decisions;
```

**Get Current Context:**
```sql
SELECT get_current_context();
```

---

### 4. **Task Manager Workflow**
**Workflow Name**: `Tasks - Manager`
**Trigger**: Called by main agent or standalone
**Purpose**: CRUD operations for tasks

#### Supported Operations:
- **Create Task**: Parse user input, extract task details, store
- **Update Task**: Change status, deadline, priority
- **Complete Task**: Mark as done, update timestamp
- **List Tasks**: Filter by status, deadline, priority
- **Task Reminder**: Check for upcoming deadlines

#### Flow for Task Creation:
```
User Input → Extract Task Info (AI) → Validate → Store in DB → Confirm
```

#### AI Task Parser Node:
```
Extract task information from this message:
"{{$json.user_message}}"

Return JSON:
{
  "title": "brief title",
  "description": "detailed description",
  "priority": "low|medium|high|urgent",
  "deadline": "ISO 8601 date or null",
  "tags": ["tag1", "tag2"]
}
```

---

### 5. **Pattern Detection Workflow**
**Workflow Name**: `Patterns - Detector`
**Trigger**: Schedule (runs daily) or on-demand
**Purpose**: Analyze behavior and identify patterns

#### Detected Patterns:
- **Procrastination**: Tasks created but not started
- **Peak Hours**: When most productive
- **Task Completion Rate**: How often tasks are finished on time
- **Topic Clusters**: Common themes in conversations
- **Decision Velocity**: How quickly decisions are made

#### Flow:
```
Fetch Recent Data → Analyze → Update Pattern Records → Generate Insights
```

#### Nodes:
1. **Fetch Last 7 Days** (Conversations, tasks, decisions)
2. **Analyze Timestamps** (Code node)
3. **Detect Procrastination**
   - Tasks with status 'pending' > 3 days
4. **Peak Productivity Hours**
   - Group tasks completed by hour
5. **Store Patterns** (Call record_pattern_occurrence function)
6. **Generate Insight Report**

#### Example Code Node (Peak Hours):
```javascript
const tasks = $input.all();

const hourCounts = {};
tasks.forEach(task => {
  if (task.json.completed_at) {
    const hour = new Date(task.json.completed_at).getHours();
    hourCounts[hour] = (hourCounts[hour] || 0) + 1;
  }
});

const peakHour = Object.keys(hourCounts)
  .reduce((a, b) => hourCounts[a] > hourCounts[b] ? a : b);

return [{
  json: {
    pattern_type: 'productivity',
    pattern_name: 'peak_hours',
    description: `Most productive at ${peakHour}:00`,
    evidence: hourCounts
  }
}];
```

---

### 6. **Decision Tracker Workflow**
**Workflow Name**: `Decisions - Tracker`
**Trigger**: Called when user makes a decision
**Purpose**: Capture and store important decisions

#### Flow:
```
Decision Input → Extract Components → Store with Embedding → Link to Tasks
```

#### AI Decision Extractor:
```
The user has made a decision. Extract:
- Title (brief summary)
- Decision (what was decided)
- Rationale (why this decision was made)
- Category (technical/business/personal/strategic)

User message: "{{$json.message}}"

Return JSON format.
```

---

### 7. **Launch Timeline Manager**
**Workflow Name**: `Launch - Timeline Manager`
**Trigger**: Webhook or scheduled daily check
**Purpose**: Track 4-week launch progress

#### Features:
- Update milestone status
- Check for at-risk milestones
- Daily progress reports
- Link tasks to milestones

#### Daily Check Flow:
```
Fetch Timeline → Check Deadlines → Flag At-Risk → Notify User
```

#### Supabase Query - Get Week Status:
```sql
SELECT * FROM launch_progress
WHERE week_number = {{$json.current_week}};
```

#### Supabase Query - Update Milestone:
```sql
UPDATE launch_timeline
SET status = '{{$json.status}}',
    completed_date = CASE WHEN '{{$json.status}}' = 'completed' THEN CURRENT_DATE ELSE NULL END
WHERE id = '{{$json.milestone_id}}';
```

---

### 8. **Context Manager Workflow**
**Workflow Name**: `Context - Manager`
**Trigger**: On-demand or scheduled
**Purpose**: Maintain current working context

#### Operations:
- **Set Context**: Update current focus, goals, blockers
- **Get Context**: Retrieve all active context
- **Archive Context**: Move old context to history

#### Flow:
```
Context Operation → UPSERT to DB → Return Current State
```

#### Supabase Query - Set Context:
```sql
INSERT INTO context (context_key, context_value, context_type)
VALUES ('{{$json.key}}', '{{$json.value}}'::jsonb, '{{$json.type}}')
ON CONFLICT (context_key)
DO UPDATE SET
    context_value = EXCLUDED.context_value,
    updated_at = NOW();
```

---

## Integration Points

### Supabase Connection
In n8n, create a Postgres credential:
- **Host**: `supabase-db` (if using docker network) or external IP
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: Your Supabase password
- **Port**: `5432`
- **SSL**: Disable for local, require for production

### OpenAI API
For embeddings and AI responses:
- **Model**: `text-embedding-3-small` for embeddings
- **Model**: `gpt-4o` or `gpt-4o-mini` for responses
- **Embedding Dimensions**: 1536

---

## ARIA Unified Schema Integration

The Personal Assistant has been consolidated with ARIA (Adaptive Responsive Intelligent Assistant) to share a unified database schema. This enables multi-interface access while preserving all PA functionality.

### Unified Tables

| Original PA Table | ARIA Table | Purpose |
|-------------------|------------|---------|
| `conversations` | `aria_conversations` + `aria_messages` | Conversation threads and messages |
| `tasks` | `tasks` (unchanged) | Task management |
| `decisions` | `decisions` (unchanged) | Decision tracking |
| `patterns` | `patterns` (unchanged) | Behavior patterns |
| `context` | `context` (unchanged) | Working context |

### New ARIA-Specific Tables

| Table | Purpose |
|-------|---------|
| `aria_conversations` | Conversation threads (grouped by session) |
| `aria_messages` | Individual messages with `interface_source` |
| `aria_attachments` | File attachments with OCR/vision support |
| `aria_unified_memory` | Cross-conversation persistent memory |
| `aria_sessions` | User session tracking |
| `aria_interface_sync` | Multi-interface synchronization |

### Interface Source Tracking

All messages now track their origin:
- `'cli'` - Personal Assistant CLI
- `'web'` - ARIA web frontend
- `'telegram'` - Future Telegram bot

### Backwards Compatibility

A `conversations` **view** is provided for backwards compatibility:
- Old workflows continue to work unchanged
- Queries to `conversations` automatically map to `aria_messages`
- `search_similar_conversations()` function updated to search ARIA tables

### Migration Documentation

See [MIGRATION_PLAN.md](/home/damon/aria-assistant/MIGRATION_PLAN.md) for:
- Complete migration steps
- Workflow update instructions
- Rollback procedures
- Testing checklist

---

## Interface Options

### Option 1: Slack Integration
- Create Slack app
- Use Slack trigger in n8n
- Respond via Slack message node

### Option 2: Web Interface
- Simple webhook endpoint
- HTML form for input
- Return JSON responses

### Option 3: Chat Widget
- Embed n8n chat widget
- Custom branding
- Real-time updates

### Option 4: CLI Tool
- Curl to webhook
- Bash aliases for common commands
- JSON output

---

## Example Usage Scenarios

### 1. Adding a Task
**User**: "Add a task to finish the database schema by Friday, high priority"

**Agent Flow**:
1. Main agent receives message
2. Intent: task_creation
3. Calls Task Manager workflow
4. AI extracts: `{title: "Finish database schema", deadline: "2024-01-19", priority: "high"}`
5. Stores in tasks table
6. Generates embedding
7. Responds: "Task added: 'Finish database schema' - Due Friday, high priority"

### 2. Asking About Past Decision
**User**: "What did I decide about the API architecture?"

**Agent Flow**:
1. Main agent receives message
2. Intent: decision_query
3. Calls Memory Retrieval with query
4. Generates embedding for "API architecture"
5. Searches decisions table
6. Finds relevant decision(s)
7. Responds with decision + rationale

### 3. Pattern Insight
**User**: "What patterns have you noticed?"

**Agent Flow**:
1. Fetches active_patterns view
2. Formats patterns
3. Responds: "I've noticed you're most productive between 9-11am. You tend to create tasks in the evening but start them in the morning."

---

## System Prompt Variations

### For Task Management:
```
You are focused on helping track tasks. When the user mentions work, deadlines, or actions:
- Ask clarifying questions
- Extract clear task details
- Set realistic priorities
- Check for dependencies
```

### For Decision Support:
```
When the user is deciding something important:
- Recall similar past decisions
- Present options clearly
- Ask about criteria
- Document the final choice with rationale
```

### For Pattern Insights:
```
You analyze work patterns. When reporting:
- Be specific with data
- Avoid judgment
- Suggest experiments
- Track pattern changes over time
```

---

## Backup Strategy

### Automated Backups (n8n workflow)
**Workflow Name**: `Backup - Automated`
**Schedule**: Daily at 2 AM

#### Steps:
1. **Export Supabase Data**
   ```sql
   COPY (SELECT * FROM conversations) TO STDOUT CSV HEADER;
   COPY (SELECT * FROM tasks) TO STDOUT CSV HEADER;
   COPY (SELECT * FROM decisions) TO STDOUT CSV HEADER;
   COPY (SELECT * FROM patterns) TO STDOUT CSV HEADER;
   COPY (SELECT * FROM context) TO STDOUT CSV HEADER;
   ```

2. **Save to Cloud Storage** (S3, Google Drive, etc.)

3. **Export n8n Workflows**
   - n8n API: GET `/workflows`
   - Save JSON to storage

4. **Verify Backup**
   - Check file sizes
   - Test restore on staging

### Manual Backup Script:
```bash
#!/bin/bash
DATE=$(date +%Y-%m-%d)
BACKUP_DIR="/home/damon/backups/$DATE"

mkdir -p $BACKUP_DIR

# Backup Supabase
docker exec supabase-db pg_dump -U postgres postgres > $BACKUP_DIR/supabase.sql

# Backup n8n workflows (via API or file export)
curl -H "X-N8N-API-KEY: $N8N_API_KEY" \
  https://n8n.leveredgeai.com/api/v1/workflows \
  > $BACKUP_DIR/n8n_workflows.json

# Compress
tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
```

---

## Migration Path

### To Export Everything:
1. **Database**: `pg_dump` creates portable SQL
2. **Workflows**: JSON export from n8n
3. **Embeddings**: Stored as arrays, work with any vector DB
4. **Context**: All in JSON, easy to transform

### To Import to New System:
1. Restore Supabase dump to new Postgres
2. Import n8n workflows or rewrite in new tool
3. Point new agent at Supabase
4. Embeddings remain compatible

---

## Next Steps to Implement

1. **Apply the schema** (run `./apply-schema.sh`)
2. **Create the 8 core workflows** in n8n
3. **Set up OpenAI credentials** in n8n
4. **Configure Supabase connection**
5. **Choose your interface** (Slack, web, CLI)
6. **Test with sample interactions**
7. **Set up automated backups**
8. **Start using tomorrow!**

---

## Testing Checklist

- [ ] Can create a task via conversation
- [ ] Can update task status
- [ ] Can ask about past decisions
- [ ] Memory retrieval finds relevant conversations
- [ ] Patterns are being detected
- [ ] Launch timeline is tracked
- [ ] Context updates work
- [ ] Backup runs successfully
- [ ] Restore from backup works
- [ ] Interface is responsive

---

## Performance Considerations

- **Vector Search**: IVFFlat index requires ~1000 rows to be effective
- **Embedding API**: Cache common queries
- **Database Queries**: Use prepared statements
- **Large Conversations**: Summarize after N messages
- **Pattern Detection**: Run off-peak hours

---

## Troubleshooting

### Issue: Slow vector search
**Solution**: Wait until you have 1000+ vectors, or use simpler keyword search initially

### Issue: Embeddings are expensive
**Solution**: Use `text-embedding-3-small` model, batch requests

### Issue: Agent forgets context
**Solution**: Check context expiration dates, increase TTL

### Issue: Too many tasks
**Solution**: Implement auto-archiving for completed tasks > 30 days old

---

This architecture provides a solid foundation for your Personal Assistant AI. Start with the core workflows and expand based on your needs!
