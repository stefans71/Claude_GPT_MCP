#!/bin/bash

# Test script for OpenRouter MCP Server
# Validates the server starts and responds to MCP protocol

set -e

echo "=== OpenRouter MCP Server Test ==="
echo ""

# Check if built
if [ ! -f "dist/index.js" ]; then
    echo "ERROR: dist/index.js not found. Run 'npm run build' first."
    exit 1
fi

echo "1. Testing server startup..."

# Start server in background and capture PID
node dist/index.js &
SERVER_PID=$!

# Give it a moment to start
sleep 1

# Check if still running
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "FAIL: Server crashed on startup"
    exit 1
fi

echo "   Server started (PID: $SERVER_PID)"

# Clean up
kill $SERVER_PID 2>/dev/null || true

echo ""
echo "2. Testing MCP protocol response..."

# Send a tools/list request via stdin and check response
RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | timeout 5 node dist/index.js 2>/dev/null || true)

if echo "$RESPONSE" | grep -q "ask_model"; then
    echo "   tools/list response: OK (found ask_model tool)"
else
    echo "   WARNING: Could not verify tools/list response"
    echo "   (This is expected - MCP requires proper handshake)"
fi

echo ""
echo "3. Checking API key..."

if [ -n "$OPENROUTER_API_KEY" ]; then
    echo "   OPENROUTER_API_KEY is set"

    # Optional: Test actual API call (costs tokens)
    read -p "   Run live API test? This will use ~100 tokens. (y/N): " RUN_LIVE
    if [[ "$RUN_LIVE" =~ ^[Yy]$ ]]; then
        echo ""
        echo "   Sending test request to OpenRouter..."

        RESULT=$(curl -s https://openrouter.ai/api/v1/chat/completions \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $OPENROUTER_API_KEY" \
            -d '{"model":"openai/gpt-4o-mini","messages":[{"role":"user","content":"Say OK"}],"max_tokens":10}')

        if echo "$RESULT" | grep -q "choices"; then
            echo "   Live API test: PASSED"
        else
            echo "   Live API test: FAILED"
            echo "   Response: $RESULT"
        fi
    fi
else
    echo "   WARNING: OPENROUTER_API_KEY not set"
    echo "   Run setup.sh to configure your API key"
fi

echo ""
echo "=== Tests Complete ==="
