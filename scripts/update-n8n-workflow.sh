#!/bin/bash
# Update ai-agent-main workflow in n8n
# Usage: ./update-n8n-workflow.sh <N8N_API_KEY>

set -e

# Configuration
N8N_BASE_URL="https://n8n.leveredgeai.com"
WORKFLOW_ID="aX8d9zWniCYaIDwc"
WORKFLOW_FILE="/home/damon/personal-assistant-ai/ai-agent-main.json"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for API key
if [ -z "$1" ] && [ -z "$N8N_API_KEY" ]; then
    echo -e "${RED}Error: N8N API key required${NC}"
    echo ""
    echo "Usage: $0 <N8N_API_KEY>"
    echo "  or: N8N_API_KEY=xxx $0"
    echo ""
    echo "To get your API key:"
    echo "  1. Open n8n: ${N8N_BASE_URL}"
    echo "  2. Go to Settings > API"
    echo "  3. Create a new API key"
    exit 1
fi

API_KEY="${1:-$N8N_API_KEY}"

echo "================================"
echo "  n8n Workflow Updater"
echo "================================"
echo ""

# Check if workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo -e "${RED}Error: Workflow file not found: $WORKFLOW_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Updating workflow ${WORKFLOW_ID}...${NC}"

# Update the workflow via API
RESPONSE=$(curl -s -X PUT "${N8N_BASE_URL}/api/v1/workflows/${WORKFLOW_ID}" \
    -H "X-N8N-API-KEY: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d @"${WORKFLOW_FILE}" \
    --max-time 30)

# Check for errors
if echo "$RESPONSE" | grep -q '"error"'; then
    echo -e "${RED}Error updating workflow:${NC}"
    echo "$RESPONSE" | jq -r '.message // .error // .' 2>/dev/null || echo "$RESPONSE"
    exit 1
fi

echo -e "${GREEN}Workflow updated successfully!${NC}"
echo ""

# Verify the update
echo -e "${YELLOW}Verifying schemas...${NC}"

VERIFY=$(curl -s -X GET "${N8N_BASE_URL}/api/v1/workflows/${WORKFLOW_ID}" \
    -H "X-N8N-API-KEY: ${API_KEY}" \
    --max-time 30)

# Count tools with schemas
SCHEMA_COUNT=$(echo "$VERIFY" | grep -o '"specifyInputSchema":true' | wc -l)

echo ""
echo "================================"
echo "  Verification Results"
echo "================================"
echo ""
echo -e "Tools with schemas: ${GREEN}${SCHEMA_COUNT}${NC}"

# Check specific tools
if echo "$VERIFY" | grep -q '"name":"store_memory".*"specifyInputSchema":true\|"specifyInputSchema":true.*"name":"store_memory"'; then
    echo -e "  store_memory:     ${GREEN}Has schema${NC}"
else
    echo -e "  store_memory:     ${RED}Missing schema${NC}"
fi

if echo "$VERIFY" | grep -q '"name":"calendar_write".*"specifyInputSchema":true\|"specifyInputSchema":true.*"name":"calendar_write"'; then
    echo -e "  calendar_write:   ${GREEN}Has schema${NC}"
else
    echo -e "  calendar_write:   ${RED}Missing schema${NC}"
fi

if echo "$VERIFY" | grep -q '"name":"manage_tasks".*"specifyInputSchema":true\|"specifyInputSchema":true.*"name":"manage_tasks"'; then
    echo -e "  manage_tasks:     ${GREEN}Has schema${NC}"
else
    echo -e "  manage_tasks:     ${RED}Missing schema${NC}"
fi

if echo "$VERIFY" | grep -q '"name":"decision_tracker".*"specifyInputSchema":true\|"specifyInputSchema":true.*"name":"decision_tracker"'; then
    echo -e "  decision_tracker: ${GREEN}Has schema${NC}"
else
    echo -e "  decision_tracker: ${RED}Missing schema${NC}"
fi

if echo "$VERIFY" | grep -q '"name":"launch_timeline_manager".*"specifyInputSchema":true\|"specifyInputSchema":true.*"name":"launch_timeline_manager"'; then
    echo -e "  launch_timeline:  ${GREEN}Has schema${NC}"
else
    echo -e "  launch_timeline:  ${RED}Missing schema${NC}"
fi

echo ""

# Check if active
if echo "$VERIFY" | grep -q '"active":true'; then
    echo -e "Workflow status: ${GREEN}ACTIVE${NC}"
else
    echo -e "Workflow status: ${YELLOW}INACTIVE${NC}"
    echo ""
    echo "Activating workflow..."

    ACTIVATE=$(curl -s -X PATCH "${N8N_BASE_URL}/api/v1/workflows/${WORKFLOW_ID}" \
        -H "X-N8N-API-KEY: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"active": true}' \
        --max-time 30)

    if echo "$ACTIVATE" | grep -q '"active":true'; then
        echo -e "Workflow status: ${GREEN}ACTIVATED${NC}"
    else
        echo -e "${RED}Failed to activate workflow${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Test the workflow:"
echo "  curl -X POST '${N8N_BASE_URL}/webhook/assistant' \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"message\": \"Hello\", \"session_id\": \"test\"}'"
