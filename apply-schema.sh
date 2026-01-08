#!/bin/bash
# Apply Personal Assistant schema to Supabase

set -e

echo "=== Applying Personal Assistant Schema to Supabase ==="

# Apply the schema
docker exec -i supabase-db psql -U postgres -d postgres < /home/damon/personal-assistant-schema.sql

echo "✓ Schema applied successfully!"

# Verify tables were created
echo ""
echo "=== Verifying tables ==="
docker exec supabase-db psql -U postgres -d postgres -c "\dt public.*" | grep -E "conversations|tasks|decisions|patterns|context|launch_timeline"

echo ""
echo "=== Testing functions ==="
docker exec supabase-db psql -U postgres -d postgres -c "SELECT proname FROM pg_proc WHERE proname LIKE 'search_similar%' OR proname LIKE 'get_current%' OR proname LIKE 'record_pattern%';"

echo ""
echo "✓ Personal Assistant schema ready!"
echo ""
echo "Next steps:"
echo "  1. Import the n8n workflows"
echo "  2. Configure the Personal Assistant agent"
echo "  3. Set up your interface (Slack, web, etc.)"
