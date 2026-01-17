#!/bin/bash

# OpenRouter MCP Server Setup Script
# Key management and installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine shell config file
get_shell_config() {
    if [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
    else
        echo "$HOME/.bashrc"
    fi
}

SHELL_CONFIG=$(get_shell_config)

# Show usage
show_help() {
    echo ""
    echo -e "${BLUE}OpenRouter MCP Server - Setup & Key Management${NC}"
    echo ""
    echo "Usage:"
    echo "  ./setup.sh              Fresh install (build + prompt for key)"
    echo "  ./setup.sh --set-key    Add or change API key"
    echo "  ./setup.sh --show-key   Show current key (masked)"
    echo "  ./setup.sh --remove-key Remove stored API key"
    echo "  ./setup.sh --help       Show this help"
    echo ""
}

# Show masked key
show_key() {
    echo ""
    # Check environment variable first
    if [ -n "$OPENROUTER_API_KEY" ]; then
        KEY="$OPENROUTER_API_KEY"
        PREFIX="${KEY:0:8}"
        SUFFIX="${KEY: -4}"
        echo -e "${GREEN}Current key (from env):${NC} ${PREFIX}...${SUFFIX}"
        return 0
    fi

    # Check shell config
    if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        KEY=$(grep "OPENROUTER_API_KEY" "$SHELL_CONFIG" | sed 's/.*"\(.*\)".*/\1/' | tail -1)
        if [ -n "$KEY" ]; then
            PREFIX="${KEY:0:8}"
            SUFFIX="${KEY: -4}"
            echo -e "${GREEN}Current key (from $SHELL_CONFIG):${NC} ${PREFIX}...${SUFFIX}"
            return 0
        fi
    fi

    echo -e "${YELLOW}No API key found.${NC}"
    echo "Run ./setup.sh --set-key to add one."
    return 1
}

# Set or update key
set_key() {
    echo ""
    echo -e "${BLUE}=== Set OpenRouter API Key ===${NC}"
    echo ""
    echo "Get your key at: https://openrouter.ai/keys"
    echo ""

    # Prompt for the API key (hidden input)
    read -sp "Enter your OpenRouter API key: " API_KEY
    echo ""

    if [ -z "$API_KEY" ]; then
        echo -e "${YELLOW}No key entered. Aborted.${NC}"
        return 1
    fi

    # Validate key format (basic check)
    if [[ ! "$API_KEY" =~ ^sk-or- ]]; then
        echo -e "${YELLOW}Warning: Key doesn't start with 'sk-or-'. Are you sure this is correct?${NC}"
        read -p "Continue anyway? (y/N): " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            return 1
        fi
    fi

    # Remove existing entry if present
    if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        sed -i '/# OpenRouter API Key/d' "$SHELL_CONFIG"
        sed -i '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"
        echo "Removed existing key entry."
    fi

    # Add new entry
    echo "" >> "$SHELL_CONFIG"
    echo "# OpenRouter API Key (added by Claude_GPT_MCP setup)" >> "$SHELL_CONFIG"
    echo "export OPENROUTER_API_KEY=\"$API_KEY\"" >> "$SHELL_CONFIG"

    # Export for current session
    export OPENROUTER_API_KEY="$API_KEY"

    echo ""
    echo -e "${GREEN}API key saved to $SHELL_CONFIG${NC}"
    echo "Key is now available in this session."
    echo ""
    echo -e "${YELLOW}Note:${NC} Run 'source $SHELL_CONFIG' or restart your terminal for other sessions."
}

# Remove key
remove_key() {
    echo ""
    echo -e "${BLUE}=== Remove OpenRouter API Key ===${NC}"
    echo ""

    if ! grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        echo -e "${YELLOW}No key found in $SHELL_CONFIG${NC}"
        return 0
    fi

    read -p "Remove API key from $SHELL_CONFIG? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        return 0
    fi

    sed -i '/# OpenRouter API Key/d' "$SHELL_CONFIG"
    sed -i '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"

    # Clean up any empty lines at end of file
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$SHELL_CONFIG" 2>/dev/null || true

    echo -e "${GREEN}API key removed from $SHELL_CONFIG${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC} The key may still be in your current session."
    echo "Run 'unset OPENROUTER_API_KEY' or restart your terminal."
}

# Full install
full_install() {
    echo ""
    echo -e "${BLUE}=== OpenRouter MCP Server Setup ===${NC}"
    echo ""

    # Check Node.js version
    if ! command -v node &> /dev/null; then
        echo -e "${RED}ERROR: Node.js is not installed. Please install Node.js 18+ first.${NC}"
        exit 1
    fi

    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "${RED}ERROR: Node.js 18+ required. Current version: $(node -v)${NC}"
        exit 1
    fi

    echo -e "Node.js version: ${GREEN}$(node -v)${NC}"

    # Install dependencies
    echo ""
    echo "Installing dependencies..."
    npm install

    # Build
    echo ""
    echo "Building TypeScript..."
    npm run build

    echo ""
    echo -e "${GREEN}Build complete!${NC}"

    # --- API Key Setup ---
    echo ""
    echo -e "${BLUE}=== API Key Configuration ===${NC}"
    echo ""

    # Check if key already exists
    if [ -n "$OPENROUTER_API_KEY" ]; then
        show_key
        read -p "Keep existing key? (Y/n): " KEEP
        if [[ "$KEEP" =~ ^[Nn]$ ]]; then
            set_key
        fi
    elif grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        show_key
        read -p "Keep existing key? (Y/n): " KEEP
        if [[ "$KEEP" =~ ^[Nn]$ ]]; then
            set_key
        fi
    else
        echo "No API key found."
        read -p "Would you like to set one now? (Y/n): " SET_NOW
        if [[ ! "$SET_NOW" =~ ^[Nn]$ ]]; then
            set_key
        else
            echo ""
            echo -e "${YELLOW}Skipped. Run './setup.sh --set-key' later to add your key.${NC}"
        fi
    fi

    # Get absolute path
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SERVER_PATH="$SCRIPT_DIR/dist/index.js"

    echo ""
    echo -e "${BLUE}=== Claude Code Configuration ===${NC}"
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
    echo -e "${GREEN}=== Setup Complete ===${NC}"
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        show_help
        ;;
    --set-key)
        set_key
        ;;
    --show-key)
        show_key
        ;;
    --remove-key)
        remove_key
        ;;
    "")
        full_install
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        show_help
        exit 1
        ;;
esac
