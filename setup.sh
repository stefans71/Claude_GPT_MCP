#!/bin/bash

# OpenRouter MCP Server Setup Script
# Polished installer with key management

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Icons
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
ARROW="${CYAN}→${NC}"
INFO="${BLUE}ℹ${NC}"

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

# Print banner
print_banner() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}OpenRouter MCP Server${NC}                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${DIM}Bridge Claude Code to GPT, Gemini, Llama & more${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print step header
step() {
    echo ""
    echo -e "${BOLD}${BLUE}[$1/$2]${NC} ${BOLD}$3${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"
}

# Spinner for long operations
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        for i in $(seq 0 9); do
            printf "\r  ${CYAN}${spinstr:$i:1}${NC} $2"
            sleep $delay
        done
    done
    printf "\r                                                  \r"
}

# Show usage
show_help() {
    print_banner
    echo -e "${BOLD}Usage:${NC}"
    echo ""
    echo -e "  ${CYAN}./setup.sh${NC}              Install and configure everything"
    echo -e "  ${CYAN}./setup.sh --set-key${NC}    Add or change API key"
    echo -e "  ${CYAN}./setup.sh --show-key${NC}   Show current key (masked)"
    echo -e "  ${CYAN}./setup.sh --remove-key${NC} Remove stored API key"
    echo -e "  ${CYAN}./setup.sh --uninstall${NC}  Remove from Claude Code"
    echo -e "  ${CYAN}./setup.sh --help${NC}       Show this help"
    echo ""
}

# Show masked key
show_key() {
    echo ""
    if [ -n "$OPENROUTER_API_KEY" ]; then
        KEY="$OPENROUTER_API_KEY"
        PREFIX="${KEY:0:10}"
        SUFFIX="${KEY: -4}"
        echo -e "  $CHECK ${GREEN}API key found${NC}"
        echo -e "     ${DIM}$PREFIX...$SUFFIX${NC}"
        return 0
    fi

    if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        KEY=$(grep "OPENROUTER_API_KEY" "$SHELL_CONFIG" | sed 's/.*"\(.*\)".*/\1/' | tail -1)
        if [ -n "$KEY" ]; then
            PREFIX="${KEY:0:10}"
            SUFFIX="${KEY: -4}"
            echo -e "  $CHECK ${GREEN}API key found${NC}"
            echo -e "     ${DIM}$PREFIX...$SUFFIX${NC}"
            return 0
        fi
    fi

    echo -e "  $CROSS ${YELLOW}No API key configured${NC}"
    echo -e "     Run ${CYAN}./setup.sh --set-key${NC} to add one"
    echo ""
    return 1
}

# Set or update key
set_key() {
    echo ""
    echo -e "${BOLD}Set OpenRouter API Key${NC}"
    echo ""
    echo -e "  $ARROW Get your key at: ${CYAN}https://openrouter.ai/keys${NC}"
    echo ""
    read -sp "  Enter API key: " API_KEY
    echo ""

    if [ -z "$API_KEY" ]; then
        echo -e "  $CROSS ${YELLOW}No key entered${NC}"
        return 1
    fi

    # Validate format
    if [[ ! "$API_KEY" =~ ^sk-or- ]]; then
        echo ""
        echo -e "  ${YELLOW}⚠ Key format looks unusual${NC} ${DIM}(expected sk-or-...)${NC}"
        read -p "  Continue anyway? (y/N): " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    # Remove existing
    if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        sed -i '/# OpenRouter API Key/d' "$SHELL_CONFIG"
        sed -i '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"
    fi

    # Add new
    echo "" >> "$SHELL_CONFIG"
    echo "# OpenRouter API Key (added by Claude_GPT_MCP setup)" >> "$SHELL_CONFIG"
    echo "export OPENROUTER_API_KEY=\"$API_KEY\"" >> "$SHELL_CONFIG"
    export OPENROUTER_API_KEY="$API_KEY"

    echo ""
    echo -e "  $CHECK ${GREEN}API key saved${NC}"
    echo ""
    echo -e "  ${BOLD}Security:${NC}"
    echo -e "  ${DIM}├${NC} Stored locally on your machine"
    echo -e "  ${DIM}├${NC} Only accessible to your user account"
    echo -e "  ${DIM}└${NC} Never uploaded or committed to git"
    echo ""
}

# Remove key
remove_key() {
    echo ""
    echo -e "${BOLD}Remove API Key${NC}"
    echo ""

    if ! grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        echo -e "  $INFO No key found"
        echo ""
        return 0
    fi

    read -p "  Remove API key? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "  ${DIM}Cancelled${NC}"
        return 0
    fi

    sed -i '/# OpenRouter API Key/d' "$SHELL_CONFIG"
    sed -i '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"

    echo -e "  $CHECK ${GREEN}API key removed${NC}"
    echo ""
}

# Uninstall
uninstall() {
    print_banner
    echo -e "${BOLD}Uninstall OpenRouter MCP Server${NC}"
    echo ""

    CLAUDE_CONFIG="$HOME/.claude.json"

    if [ ! -f "$CLAUDE_CONFIG" ]; then
        echo -e "  $INFO No Claude Code config found"
        echo ""
        return 0
    fi

    if ! grep -q "openrouter" "$CLAUDE_CONFIG" 2>/dev/null; then
        echo -e "  $INFO OpenRouter not installed in Claude Code"
        echo ""
        return 0
    fi

    echo -e "  ${BOLD}This will:${NC}"
    echo -e "  ${DIM}├${NC} Remove OpenRouter from Claude Code config"
    echo -e "  ${DIM}└${NC} Only affects THIS machine"
    echo ""
    read -p "  Continue? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "  ${DIM}Cancelled${NC}"
        return 0
    fi

    if command -v jq &> /dev/null; then
        UPDATED=$(jq 'del(.mcpServers.openrouter)' "$CLAUDE_CONFIG")
        echo "$UPDATED" > "$CLAUDE_CONFIG"
        echo ""
        echo -e "  $CHECK ${GREEN}Removed from Claude Code${NC}"
    else
        echo ""
        echo -e "  ${YELLOW}Please manually remove 'openrouter' from ~/.claude.json${NC}"
    fi

    echo ""
    read -p "  Also remove API key? (y/N): " REMOVE_KEY
    if [[ "$REMOVE_KEY" =~ ^[Yy]$ ]]; then
        remove_key
    fi

    echo ""
    echo -e "  ${DIM}Restart Claude Code to apply changes${NC}"
    echo ""
    echo -e "  ${DIM}For manual uninstall instructions, see:${NC}"
    echo -e "  ${CYAN}https://github.com/stefans71/Claude_GPT_MCP#-uninstall${NC}"
    echo ""
}

# Full install
full_install() {
    print_banner

    echo -e "  ${DIM}You can run this while Claude Code is open.${NC}"
    echo -e "  ${DIM}Just restart Claude Code when setup completes.${NC}"

    local TOTAL_STEPS=4

    # Step 1: Check requirements
    step 1 $TOTAL_STEPS "Checking requirements"

    if ! command -v node &> /dev/null; then
        echo -e "  $CROSS ${RED}Node.js not found${NC}"
        echo -e "     Please install Node.js 18+ from ${CYAN}https://nodejs.org${NC}"
        exit 1
    fi

    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "  $CROSS ${RED}Node.js 18+ required${NC} ${DIM}(found $(node -v))${NC}"
        exit 1
    fi
    echo -e "  $CHECK Node.js $(node -v)"

    if command -v jq &> /dev/null; then
        echo -e "  $CHECK jq installed"
    else
        echo -e "  $INFO jq not found ${DIM}(optional, for JSON handling)${NC}"
    fi

    # Step 2: Install & Build
    step 2 $TOTAL_STEPS "Building project"

    echo -e "  ${DIM}Installing dependencies...${NC}"
    npm install --silent 2>/dev/null &
    spinner $! "Installing dependencies..."
    echo -e "  $CHECK Dependencies installed"

    echo -e "  ${DIM}Compiling TypeScript...${NC}"
    npm run build --silent 2>/dev/null &
    spinner $! "Compiling TypeScript..."
    echo -e "  $CHECK Build complete"

    # Step 3: API Key
    step 3 $TOTAL_STEPS "API key configuration"

    if [ -n "$OPENROUTER_API_KEY" ]; then
        show_key
        echo ""
        read -p "  Use this key? (Y/n): " KEEP
        if [[ "$KEEP" =~ ^[Nn]$ ]]; then
            set_key
        fi
    elif grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        show_key
        echo ""
        read -p "  Use this key? (Y/n): " KEEP
        if [[ "$KEEP" =~ ^[Nn]$ ]]; then
            set_key
        fi
    else
        echo -e "  $INFO No API key found"
        echo ""
        read -p "  Set up API key now? (Y/n): " SET_NOW
        if [[ ! "$SET_NOW" =~ ^[Nn]$ ]]; then
            set_key
        else
            echo ""
            echo -e "  ${DIM}Skipped. Run ${NC}${CYAN}./setup.sh --set-key${NC}${DIM} later${NC}"
        fi
    fi

    # Step 4: Claude Code config
    step 4 $TOTAL_STEPS "Claude Code integration"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SERVER_PATH="$SCRIPT_DIR/dist/index.js"
    CLAUDE_CONFIG="$HOME/.claude.json"

    # Check if already configured
    if [ -f "$CLAUDE_CONFIG" ] && grep -q "openrouter" "$CLAUDE_CONFIG" 2>/dev/null; then
        echo -e "  $CHECK ${GREEN}OpenRouter is ready to use!${NC}"
        echo ""
        echo -e "  ${DIM}Already configured in Claude Code.${NC}"
        echo -e "  ${DIM}Just restart Claude Code if you haven't already.${NC}"
        print_complete
        return 0
    fi

    if [ -f "$CLAUDE_CONFIG" ]; then
        echo -e "  $INFO Existing Claude config found"
    else
        echo -e "  $INFO No config file yet"
    fi

    echo ""
    echo -e "  ${BOLD}This will:${NC}"
    echo -e "  ${DIM}├${NC} Add OpenRouter to ~/.claude.json"
    echo -e "  ${DIM}├${NC} Only affects Claude Code on THIS machine"
    echo -e "  ${DIM}└${NC} Can be removed with: ${CYAN}./setup.sh --uninstall${NC}"
    echo ""
    read -p "  Add OpenRouter to Claude Code? (Y/n): " CONFIGURE
    if [[ "$CONFIGURE" =~ ^[Nn]$ ]]; then
        echo ""
        echo -e "  ${DIM}Skipped. Run setup again when ready.${NC}"
        print_complete
        return 0
    fi

    NEW_SERVER=$(cat << EOF
{
  "command": "node",
  "args": ["$SERVER_PATH"]
}
EOF
)

    if command -v jq &> /dev/null; then
        if [ -f "$CLAUDE_CONFIG" ]; then
            UPDATED=$(jq --argjson server "$NEW_SERVER" '.mcpServers.openrouter = $server' "$CLAUDE_CONFIG")
            echo "$UPDATED" > "$CLAUDE_CONFIG"
        else
            echo "{\"mcpServers\":{\"openrouter\":$NEW_SERVER}}" | jq '.' > "$CLAUDE_CONFIG"
        fi
        echo -e "  $CHECK ${GREEN}Added to Claude Code config${NC}"
    else
        if [ ! -f "$CLAUDE_CONFIG" ]; then
            cat << EOF > "$CLAUDE_CONFIG"
{
  "mcpServers": {
    "openrouter": {
      "command": "node",
      "args": ["$SERVER_PATH"]
    }
  }
}
EOF
            echo -e "  $CHECK ${GREEN}Created Claude Code config${NC}"
        else
            echo ""
            echo -e "  ${YELLOW}Please add this to ~/.claude.json manually:${NC}"
            echo ""
            echo -e "  ${DIM}\"openrouter\": {${NC}"
            echo -e "  ${DIM}  \"command\": \"node\",${NC}"
            echo -e "  ${DIM}  \"args\": [\"$SERVER_PATH\"]${NC}"
            echo -e "  ${DIM}}${NC}"
        fi
    fi

    print_complete
}

# Print completion message
print_complete() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}✓ Setup Complete!${NC}                                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}What now?${NC}"
    echo ""
    echo -e "  ${DIM}1.${NC} Close and reopen Claude Code (or run ${CYAN}claude${NC} in a new terminal)"
    echo -e "  ${DIM}2.${NC} Chat normally - Claude now has access to other AI models"
    echo ""
    echo -e "  ${BOLD}Get a second opinion from other AI models:${NC}"
    echo -e "  ${DIM}•${NC} ${CYAN}\"Ask GPT-4o to review my plan\"${NC}"
    echo -e "  ${DIM}•${NC} ${CYAN}\"What would Gemini do differently?\"${NC}"
    echo -e "  ${DIM}•${NC} ${CYAN}\"Have DeepSeek check this for bugs\"${NC}"
    echo ""
    echo -e "  ${DIM}Docs & help: ${CYAN}https://github.com/stefans71/Claude_GPT_MCP${NC}"
    echo ""
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
    --uninstall)
        uninstall
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
