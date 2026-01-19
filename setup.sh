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

# Portable sed -i (macOS compatibility)
sed_inplace() {
    if sed --version >/dev/null 2>&1; then
        # GNU sed
        sed -i "$@"
    else
        # BSD sed (macOS)
        sed -i '' "$@"
    fi
}

# Determine shell config file (with bash_profile support for macOS)
get_shell_config() {
    if [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        # macOS uses bash_profile for login shells
        echo "$HOME/.bash_profile"
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
        # Extract key - handle both double and single quotes
        KEY=$(grep "OPENROUTER_API_KEY" "$SHELL_CONFIG" | sed "s/.*[\"']\([^\"']*\)[\"'].*/\1/" | tail -1)
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

    # Remove existing from shell config
    if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        sed_inplace '/# OpenRouter API Key/d' "$SHELL_CONFIG"
        sed_inplace '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"
    fi

    # Add to shell config
    echo "" >> "$SHELL_CONFIG"
    echo "# OpenRouter API Key (added by Claude_GPT_MCP setup)" >> "$SHELL_CONFIG"
    echo "export OPENROUTER_API_KEY=\"$API_KEY\"" >> "$SHELL_CONFIG"
    export OPENROUTER_API_KEY="$API_KEY"

    # Also save to MCP config as backup
    save_mcp_config_key "$API_KEY"

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

    sed_inplace '/# OpenRouter API Key/d' "$SHELL_CONFIG"
    sed_inplace '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"

    echo -e "  $CHECK ${GREEN}API key removed${NC}"
    echo ""
}

# Configure MCP server in Claude config with env vars
configure_claude_mcp() {
    local install_dir="$1"
    local api_key="$2"
    local claude_config="$HOME/.claude.json"

    echo -e "  ${DIM}Configuring Claude MCP server...${NC}"

    # Create config if doesn't exist
    if [[ ! -f "$claude_config" ]]; then
        echo '{}' > "$claude_config"
    fi

    # Build the MCP server config with env
    local server_path="$install_dir/dist/index.js"

    if command -v jq &> /dev/null; then
        if [ -n "$api_key" ]; then
            # With API key in env
            local mcp_config="{\"command\": \"node\", \"args\": [\"$server_path\"], \"env\": {\"OPENROUTER_API_KEY\": \"$api_key\"}}"
            jq --argjson mcp "$mcp_config" '.mcpServers.openrouter = $mcp' "$claude_config" > "$claude_config.tmp" \
                && mv "$claude_config.tmp" "$claude_config"
        else
            # Without API key (rely on shell env)
            jq --arg path "$server_path" '.mcpServers.openrouter = {command: "node", args: [$path]}' "$claude_config" > "$claude_config.tmp" \
                && mv "$claude_config.tmp" "$claude_config"
        fi
    else
        # Fallback: use node to merge JSON
        if [ -n "$api_key" ]; then
            node -e "
                const fs = require('fs');
                const config = JSON.parse(fs.readFileSync('$claude_config', 'utf8'));
                config.mcpServers = config.mcpServers || {};
                config.mcpServers.openrouter = {
                    command: 'node',
                    args: ['$server_path'],
                    env: { OPENROUTER_API_KEY: '$api_key' }
                };
                fs.writeFileSync('$claude_config', JSON.stringify(config, null, 2));
            "
        else
            node -e "
                const fs = require('fs');
                const config = JSON.parse(fs.readFileSync('$claude_config', 'utf8'));
                config.mcpServers = config.mcpServers || {};
                config.mcpServers.openrouter = {
                    command: 'node',
                    args: ['$server_path']
                };
                fs.writeFileSync('$claude_config', JSON.stringify(config, null, 2));
            "
        fi
    fi

    # Secure the config file (contains API key)
    chmod 600 "$claude_config" 2>/dev/null || true

    echo -e "  $CHECK ${GREEN}MCP server configured in ~/.claude.json${NC}"
}

# Save API key to MCP's own config file (as backup)
save_mcp_config_key() {
    local api_key="$1"
    local mcp_config_dir="$HOME/.config/openrouter-mcp"
    local mcp_config_file="$mcp_config_dir/config.json"

    mkdir -p "$mcp_config_dir"

    if [ -f "$mcp_config_file" ]; then
        # Merge with existing config using node
        node -e "
            const fs = require('fs');
            const config = JSON.parse(fs.readFileSync('$mcp_config_file', 'utf8'));
            config.apiKey = '$api_key';
            fs.writeFileSync('$mcp_config_file', JSON.stringify(config, null, 2));
        " 2>/dev/null || echo "{\"apiKey\": \"$api_key\"}" > "$mcp_config_file"
    else
        echo "{\"apiKey\": \"$api_key\"}" > "$mcp_config_file"
    fi

    # Secure the config file (contains API key)
    chmod 600 "$mcp_config_file" 2>/dev/null || true
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
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SERVER_PATH="$SCRIPT_DIR/dist/index.js"
    CLAUDE_CONFIG="$HOME/.claude.json"

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
    local npm_pid=$!
    spinner $npm_pid "Installing dependencies..."
    if ! wait $npm_pid; then
        echo -e "  $CROSS ${RED}npm install failed${NC}"
        echo -e "     Run ${CYAN}npm install${NC} manually to see errors"
        exit 1
    fi
    echo -e "  $CHECK Dependencies installed"

    echo -e "  ${DIM}Compiling TypeScript...${NC}"
    npm run build --silent 2>/dev/null &
    local build_pid=$!
    spinner $build_pid "Compiling TypeScript..."
    if ! wait $build_pid; then
        echo -e "  $CROSS ${RED}Build failed${NC}"
        echo -e "     Run ${CYAN}npm run build${NC} manually to see errors"
        exit 1
    fi
    echo -e "  $CHECK Build complete"

    # Verify build output exists
    if [ ! -f "$SCRIPT_DIR/dist/index.js" ]; then
        echo -e "  $CROSS ${RED}Build output not found${NC}"
        echo -e "     Expected: ${CYAN}dist/index.js${NC}"
        exit 1
    fi

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
        # If user pasted their API key directly, use it
        if [[ "$SET_NOW" =~ ^sk-or- ]]; then
            echo ""
            echo -e "  ${DIM}Detected API key input...${NC}"
            # Remove existing
            if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
                sed_inplace '/# OpenRouter API Key/d' "$SHELL_CONFIG"
                sed_inplace '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"
            fi
            # Add new to shell config
            echo "" >> "$SHELL_CONFIG"
            echo "# OpenRouter API Key (added by Claude_GPT_MCP setup)" >> "$SHELL_CONFIG"
            echo "export OPENROUTER_API_KEY=\"$SET_NOW\"" >> "$SHELL_CONFIG"
            export OPENROUTER_API_KEY="$SET_NOW"
            # Also save to MCP config
            save_mcp_config_key "$SET_NOW"
            echo -e "  $CHECK ${GREEN}API key saved${NC}"
        elif [[ ! "$SET_NOW" =~ ^[Nn]$ ]]; then
            set_key
        else
            echo ""
            echo -e "  ${DIM}Skipped. Run ${NC}${CYAN}./setup.sh --set-key${NC}${DIM} later${NC}"
        fi
    fi

    # Step 4: Claude Code config
    step 4 $TOTAL_STEPS "Claude Code integration"

    # Check if already configured (use jq if available for accurate check)
    if [ -f "$CLAUDE_CONFIG" ]; then
        local already_configured=false
        if command -v jq &> /dev/null; then
            if jq -e '.mcpServers.openrouter' "$CLAUDE_CONFIG" >/dev/null 2>&1; then
                already_configured=true
            fi
        elif grep -q '"openrouter"' "$CLAUDE_CONFIG" 2>/dev/null; then
            already_configured=true
        fi

        if [ "$already_configured" = true ]; then
            echo -e "  $CHECK ${GREEN}OpenRouter is ready to use!${NC}"
            echo ""
            echo -e "  ${DIM}Already configured in Claude Code.${NC}"
            echo -e "  ${DIM}Just restart Claude Code if you haven't already.${NC}"
            print_complete
            return 0
        fi
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

    # Backup existing config before modification
    if [ -f "$CLAUDE_CONFIG" ]; then
        cp "$CLAUDE_CONFIG" "$CLAUDE_CONFIG.bak"
    fi

    # Validate existing JSON if present
    if [ -f "$CLAUDE_CONFIG" ] && command -v jq &> /dev/null; then
        if ! jq empty "$CLAUDE_CONFIG" 2>/dev/null; then
            echo -e "  $CROSS ${YELLOW}Warning: ~/.claude.json contains invalid JSON${NC}"
            echo -e "     Backup saved to ${CYAN}~/.claude.json.bak${NC}"
            echo -e "     Please fix the file manually and re-run setup"
            exit 1
        fi
    fi

    # Save API key to MCP config (as backup/fallback)
    if [ -n "$OPENROUTER_API_KEY" ]; then
        save_mcp_config_key "$OPENROUTER_API_KEY"
        echo -e "  $CHECK ${GREEN}API key saved to MCP config${NC}"
    fi

    # Configure Claude MCP with env var for API key
    configure_claude_mcp "$SCRIPT_DIR" "$OPENROUTER_API_KEY"

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
    echo -e "  ${DIM}•${NC} ${CYAN}\"Ask GPT-5.2-Codex to review my plan\"${NC}"
    echo -e "  ${DIM}•${NC} ${CYAN}\"What would Gemini do differently?\"${NC}"
    echo -e "  ${DIM}•${NC} ${CYAN}\"Have DeepSeek check this for bugs\"${NC}"
    echo ""
    echo -e "  ${YELLOW}⚠ First time only — Introducing \"The Blob\":${NC}"
    echo ""
    echo -e "  ${DIM}┌────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${DIM}config\${NC}\"\n    else\n  if [ ! -f \"\$CLA${NC}  ${DIM}│${NC}"
    echo -e "  ${DIM}│${NC} ${DIM}UDE_CONFIG\" ];\n then\n   cat << EOF > \"\$${NC}  ${DIM}│${NC}"
    echo -e "  ${DIM}│${NC} ${DIM}CLAUDE_CONFIG\"\n{\n  \"mcpServers\": {\n${NC}   ${DIM}│${NC}"
    echo -e "  ${DIM}│${NC} ${DIM}\"openrouter\":\n   \"command\": \"node\"${NC}   ${DIM}│${NC}"
    echo -e "  ${DIM}└────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${DIM}This is your prompt as raw JSON (how computers talk).${NC}"
    echo -e "  ${DIM}Claude Code shows it so you know what's being sent.${NC}"
    echo -e "  ${DIM}Just select:${NC} ${CYAN}\"Yes, and don't ask again\"${NC} ${DIM}to skip forever.${NC}"
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
        # Enhanced set-key that updates all locations
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

        echo ""
        echo -e "${BOLD}Set OpenRouter API Key${NC}"
        echo ""
        echo -e "  $ARROW Get your key at: ${CYAN}https://openrouter.ai/keys${NC}"
        echo ""
        read -sp "  Enter API key: " NEW_KEY
        echo ""

        if [ -z "$NEW_KEY" ]; then
            echo -e "  $CROSS ${YELLOW}No key entered${NC}"
            exit 1
        fi

        # Validate format
        if [[ ! "$NEW_KEY" =~ ^sk-or- ]]; then
            echo ""
            echo -e "  ${YELLOW}⚠ Key format looks unusual${NC} ${DIM}(expected sk-or-...)${NC}"
            read -p "  Continue anyway? (y/N): " CONTINUE
            if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi

        # 1. Update shell config (existing behavior)
        if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
            sed_inplace '/# OpenRouter API Key/d' "$SHELL_CONFIG"
            sed_inplace '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"
        fi
        echo "" >> "$SHELL_CONFIG"
        echo "# OpenRouter API Key (added by Claude_GPT_MCP setup)" >> "$SHELL_CONFIG"
        echo "export OPENROUTER_API_KEY=\"$NEW_KEY\"" >> "$SHELL_CONFIG"
        export OPENROUTER_API_KEY="$NEW_KEY"
        echo -e "  $CHECK ${GREEN}Saved to shell config${NC}"

        # 2. Update MCP's own config (backup)
        save_mcp_config_key "$NEW_KEY"
        echo -e "  $CHECK ${GREEN}Saved to MCP config${NC}"

        # 3. Update Claude's MCP config with env
        configure_claude_mcp "$SCRIPT_DIR" "$NEW_KEY"

        echo ""
        echo -e "  ${GREEN}${BOLD}✓ API key updated in all locations${NC}"
        echo ""
        echo -e "  ${YELLOW}Restart Claude Code to apply changes${NC}"
        echo ""
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
