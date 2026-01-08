# Model Configuration Guide

Complete guide to OpenAI model configurations across all workflows.

---

## 🤖 Model Selection Strategy

### Primary Models

**AI Agent (Main Workflow)**:
- **Primary**: `gpt-4o-mini`
  - Fast, cost-effective
  - $0.150 per 1M input tokens
  - $0.600 per 1M output tokens
  - Best for: Interactive conversations

- **Fallback**: `gpt-4o`
  - More capable, slower
  - $2.50 per 1M input tokens
  - $10.00 per 1M output tokens
  - Use if: Complex reasoning needed

- **Emergency Fallback**: `gpt-3.5-turbo`
  - Fastest, cheapest
  - $0.50 per 1M input tokens
  - $1.50 per 1M output tokens
  - Use if: All else fails

**Embeddings (Memory, Tasks, Decisions)**:
- **Primary**: `text-embedding-3-small`
  - $0.020 per 1M tokens
  - 1536 dimensions
  - Best for: General embeddings

- **Fallback**: `text-embedding-ada-002`
  - $0.100 per 1M tokens
  - 1536 dimensions (compatible)
  - Use if: Rate limits hit

**Summarization (Context Summarizer)**:
- **Primary**: `gpt-4o-mini`
  - Fast, good quality summaries
- **Fallback**: `gpt-3.5-turbo`
  - Faster, acceptable quality

---

## 📊 Model Configurations by Workflow

### Main AI Agent
**File**: `ai-agent-main.json`

```json
{
  "model": "gpt-4o-mini",
  "options": {
    "temperature": 0.7,
    "maxTokens": 1000,
    "fallbackModels": ["gpt-4o", "gpt-3.5-turbo"]
  }
}
```

**Configuration**:
- Temperature: 0.7 (balanced creativity/consistency)
- Max Tokens: 1000 (controls response length)
- Context Window: 10 messages (from Postgres Chat Memory)

**When to adjust**:
- Lower temperature (0.5) for more consistent responses
- Raise temperature (0.9) for more creative responses
- Increase max tokens (1500) for longer responses
- Reduce max tokens (500) for faster, cheaper responses

---

### Tool Workflows

**Store Memory (01)**:
- Uses `text-embedding-3-small` for embeddings
- Direct OpenAI API calls in Code nodes
- Automatic fallback to `text-embedding-ada-002` on error

**Search Memory (02)**:
- Uses `text-embedding-3-small` for query embedding
- Vector similarity search in Supabase
- No LLM calls (pure SQL)

**Manage Tasks (03)**:
- Uses `text-embedding-3-small` for task embeddings
- Automatic fallback to `text-embedding-ada-002` on error
- No LLM calls for retrieval

**Calendar Read/Write (04-05)**:
- No OpenAI models used
- Pure Google Calendar API

**Get Launch Status (06)**:
- No OpenAI models used
- Pure SQL queries

**Context Manager (07)**:
- No OpenAI models used
- Pure SQL operations

---

### Advanced Workflows

**Pattern Detection (08)**:
- No OpenAI models used
- Pure SQL analytics

**Proactive Reminders (09)**:
- No OpenAI models used
- Pure SQL queries

**Decision Tracker (10)**:
- Uses `text-embedding-3-small` for decision embeddings
- Automatic fallback to `text-embedding-ada-002` on error

**Task Analytics (11)**:
- No OpenAI models used
- Pure SQL analytics

**Context Summarizer (12)**:
```json
{
  "model": "gpt-4o-mini",
  "options": {
    "temperature": 0.5,
    "maxTokens": 500,
    "fallbackModels": ["gpt-3.5-turbo"]
  }
}
```
- Lower temperature for consistent summaries
- Limited tokens for concise output

**Launch Timeline Manager (13)**:
- No OpenAI models used
- Pure SQL operations

**Memory Consolidation (14)**:
- No OpenAI models used
- Pure SQL maintenance

**Backup & Export (15)**:
- No OpenAI models used
- Pure data export

---

## 🔄 Implementing Fallback Strategy

### Method 1: Error Handling in Code Nodes

For workflows using direct OpenAI API calls (embeddings):

```javascript
// In Code nodes
async function generateEmbedding(text) {
  const models = ['text-embedding-3-small', 'text-embedding-ada-002'];

  for (const model of models) {
    try {
      const response = await $http.makeRequest({
        method: 'POST',
        url: 'https://api.openai.com/v1/embeddings',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        },
        body: {
          input: text,
          model: model
        }
      });

      return response.data[0].embedding;
    } catch (error) {
      console.log(`Failed with ${model}, trying next...`);
      if (model === models[models.length - 1]) {
        throw error; // Last model failed
      }
    }
  }
}
```

### Method 2: Multiple Model Nodes (n8n LangChain)

For AI Agent workflow:
1. Primary OpenAI Chat Model node (gpt-4o-mini)
2. Error handling catches failures
3. Route to backup model node if needed

**Note**: n8n's LangChain nodes handle retries automatically. Explicit fallback requires custom error handling or multiple nodes with conditional routing.

---

## 💰 Cost Optimization

### Current Configuration (Optimal)

**Monthly cost estimate** (500 requests):
- AI Agent: 500 × 1000 tokens avg = 500K tokens
  - Input: 400K tokens @ $0.150/1M = $0.060
  - Output: 100K tokens @ $0.600/1M = $0.060
  - **Total**: $0.120

- Embeddings: 200 items × 100 tokens avg = 20K tokens
  - @ $0.020/1M = $0.0004
  - **Total**: ~$0.001

- Context Summarizer: 20 summaries × 500 tokens = 10K tokens
  - @ $0.150/1M = $0.0015
  - **Total**: ~$0.002

**Grand Total**: ~$0.123/month

### Cost Reduction Options

**Use gpt-3.5-turbo as primary**:
- 70% cost reduction
- Acceptable quality for simple tasks
- Recommended for high-volume use

**Reduce context window**:
- 10 messages → 5 messages
- 50% reduction in input tokens
- Trade-off: Less context awareness

**Batch operations**:
- Group embedding generations
- Reduce API calls overhead

---

## 🎛️ Configuration Quick Reference

### To change primary model:

**Main AI Agent**:
1. Open `ai-agent-main.json` in n8n
2. Click "OpenAI Chat Model" node
3. Change "Model" dropdown: `gpt-4o-mini` → `gpt-4o` or `gpt-3.5-turbo`
4. Save workflow

**Embeddings** (in Code nodes):
1. Open workflow in n8n
2. Find Code node with OpenAI API call
3. Edit: `model: 'text-embedding-3-small'` → `'text-embedding-ada-002'`
4. Save workflow

### To adjust temperature:

**Main AI Agent**:
1. Open `ai-agent-main.json` in n8n
2. Click "OpenAI Chat Model" node
3. Expand "Options"
4. Change "Temperature": 0.7 → desired value (0.0-2.0)
5. Save workflow

**Guidelines**:
- 0.0-0.3: Very consistent, factual
- 0.4-0.7: Balanced (recommended)
- 0.8-1.2: Creative, varied
- 1.3-2.0: Very creative, unpredictable

---

## 🔍 Monitoring Model Performance

### Track via n8n Execution Logs

1. Go to n8n → Executions tab
2. Filter by workflow
3. Check execution time and token usage
4. Monitor error rates

### Key Metrics

**Response Time**:
- Target: <3s for simple queries
- Target: <5s for tool-calling queries
- If slower: Consider using gpt-3.5-turbo

**Token Usage**:
- Monitor via OpenAI dashboard
- Alert if >expected monthly usage
- Adjust context window if needed

**Error Rate**:
- Target: <1% of requests
- If higher: Check API limits, network
- Implement fallback models

---

## 🚨 Troubleshooting

### "Rate limit exceeded"
- **Solution**: Implement exponential backoff
- **Solution**: Use fallback model
- **Solution**: Reduce request frequency

### "Model not found"
- **Solution**: Verify model name spelling
- **Solution**: Check OpenAI API access
- **Solution**: Update to supported model

### "Context length exceeded"
- **Solution**: Reduce context window (10 → 5 messages)
- **Solution**: Enable Context Summarizer
- **Solution**: Lower max_tokens

### Slow responses
- **Solution**: Switch to gpt-4o-mini (if using gpt-4o)
- **Solution**: Reduce temperature
- **Solution**: Lower max_tokens
- **Solution**: Reduce context window

---

## 📝 Best Practices

1. **Start with gpt-4o-mini** - Optimal cost/performance balance
2. **Monitor usage** - Track costs via OpenAI dashboard
3. **Test fallbacks** - Verify backup models work
4. **Adjust temperature** - Lower for consistency, higher for creativity
5. **Use context wisely** - More context = higher cost
6. **Enable summarization** - Reduces long-term token usage
7. **Batch when possible** - Group similar operations
8. **Cache results** - Store frequent query results

---

## 🔄 Version History

- **v1.0** (2026-01-05): Initial configuration
  - Primary: gpt-4o-mini
  - Embeddings: text-embedding-3-small
  - Temperature: 0.7
  - Max tokens: 1000

---

**For updates**, edit this file and update workflow configurations accordingly.

---

## 🆕 Alternative Models (2026 Pricing Update)

Based on current market analysis, here are alternative models to consider:

### Gemini 2.0 Flash (Google) - Cost Optimization
**Pricing**: $0.10/1M input, $0.40/1M output
- **33% cheaper** than GPT-4o-mini
- **Free tier available** for development
- Comparable quality to GPT-4o-mini
- Fast response times

**When to use:**
- High-volume deployments (>5,000 requests/month)
- Cost is primary concern
- Free tier valuable for testing

**Implementation:**
Requires Google AI API key and custom integration

### Claude Haiku 4.5 (Anthropic) - Quality Upgrade
**Pricing**: $1.00/1M input, $5.00/1M output
- **Better quality** than GPT-4o-mini
- **6x more expensive**
- Excellent for complex reasoning

**When to use:**
- Specialized high-quality tasks
- Complex reasoning required
- Cost less important than quality

**Implementation:**
Requires Anthropic API key and Claude-compatible node

### Cost Comparison Table

| Model | Input | Output | 500 req/mo | Savings vs Current |
|-------|-------|--------|------------|-------------------|
| Gemini 2.0 Flash | $0.10 | $0.40 | $0.08 | -33% ($0.04) ✅ |
| **GPT-4o-mini (Current)** | $0.15 | $0.60 | **$0.12** | Baseline ✅ |
| Claude Haiku 4.5 | $1.00 | $5.00 | $0.90 | +650% ($0.78) ❌ |
| GPT-4o | $2.50 | $10.00 | $3.00 | +2400% ($2.88) ❌ |

### Current Recommendation: ✅ Keep GPT-4o-mini

**Rationale:**
1. Already configured and tested
2. Excellent cost/quality balance ($0.12/month)
3. Mature OpenAI ecosystem
4. Minimal cost (savings not worth switching effort)
5. Proven performance for conversational AI

**See detailed analysis:** [PRICING-ANALYSIS.md](PRICING-ANALYSIS.md)

---

*Last Updated: 2026-01-05 - Pricing verified against official provider documentation*
