#!/bin/bash

# OpenRouter MCP Server Setup Script
# Prompts for API key and stores it securely

set -e

echo "=== OpenRouter MCP Server Setup ==="
echo ""

# Check Node.js version
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "ERROR: Node.js 18+ required. Current version: $(node -v)"
    exit 1
fi

echo "Node.js version: $(node -v)"

# Install dependencies
echo ""
echo "Installing dependencies..."
npm install

# Build
echo ""
echo "Building TypeScript..."
npm run build

echo ""
echo "Build complete!"

# --- Secure API Key Setup ---
echo ""
echo "=== API Key Configuration ==="
echo ""
echo "Your OpenRouter API key will be stored as an environment variable."
echo "Get your key at: https://openrouter.ai/keys"
echo ""

# Prompt for the API key (hidden input)
read -sp "Enter your OpenRouter API key: " API_KEY
echo ""

if [ -z "$API_KEY" ]; then
    echo "WARNING: No API key provided. You'll need to set OPENROUTER_API_KEY manually."
else
    # Determine shell config file
    SHELL_CONFIG=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    else
        SHELL_CONFIG="$HOME/.bashrc"
        touch "$SHELL_CONFIG"
    fi

    # Check if already set
    if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        echo ""
        echo "OPENROUTER_API_KEY already exists in $SHELL_CONFIG"
        read -p "Overwrite? (y/N): " OVERWRITE
        if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
            # Remove old entry
            sed -i '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"
        else
            echo "Keeping existing key."
            API_KEY=""
        fi
    fi

    if [ -n "$API_KEY" ]; then
        # Add to shell config
        echo "" >> "$SHELL_CONFIG"
        echo "# OpenRouter API Key (added by Claude_GPT_MCP setup)" >> "$SHELL_CONFIG"
        echo "export OPENROUTER_API_KEY=\"$API_KEY\"" >> "$SHELL_CONFIG"

        # Also export for current session
        export OPENROUTER_API_KEY="$API_KEY"

        echo ""
        echo "API key saved to $SHELL_CONFIG"
        echo "Key is now available in this session."
    fi
fi

# Get absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_PATH="$SCRIPT_DIR/dist/index.js"

echo ""
echo "=== Claude Code Configuration ==="
echo ""
echo "Add to ~/.claude.json:"
echo ""
cat << EOF
{
  "mcpServers": {
    "openrouter": {
      "command": "node",
      "args": ["$SERVER_PATH"]
    }
  }
}
EOF

echo ""
echo "Then restart Claude Code."
echo ""
echo "=== Setup Complete ==="
