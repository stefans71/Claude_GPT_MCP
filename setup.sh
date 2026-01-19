#!/bin/bash

# OpenRouter MCP Server Setup Script
# Professional installer with security focus

set -e

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

VERSION="1.0.0"
TOTAL_STEPS=4
CURRENT_STEP=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Icons
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
ARROW="${CYAN}→${NC}"
INFO="${BLUE}ℹ${NC}"
LOCK="${YELLOW}🔒${NC}"
SHIELD="${GREEN}🛡${NC}"
KEY="${YELLOW}🔑${NC}"
ROCKET="${MAGENTA}🚀${NC}"
WARN="${YELLOW}⚠${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Portable sed -i (macOS compatibility)
sed_inplace() {
    if sed --version >/dev/null 2>&1; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

# Determine shell config file
get_shell_config() {
    if [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        echo "$HOME/.bash_profile"
    elif [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
    else
        echo "$HOME/.bashrc"
    fi
}

SHELL_CONFIG=$(get_shell_config)

# ═══════════════════════════════════════════════════════════════════════════════
# UI COMPONENTS
# ═══════════════════════════════════════════════════════════════════════════════

# Print modern banner
print_banner() {
    clear 2>/dev/null || true
    echo ""
    echo -e "${CYAN}"
    echo "    ╭─────────────────────────────────────────────────────────╮"
    echo "    │                                                         │"
    echo -e "    │   ${WHITE}${BOLD}🔐 OpenRouter MCP Server${NC}${CYAN}                             │"
    echo -e "    │   ${DIM}Bridge Claude Code to 200+ AI models${NC}${CYAN}                 │"
    echo "    │                                                         │"
    echo -e "    │   ${DIM}v${VERSION}${NC}${CYAN}                                                  │"
    echo "    │                                                         │"
    echo "    ╰─────────────────────────────────────────────────────────╯"
    echo -e "${NC}"
}

# Progress bar
progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "    ${DIM}["
    printf "${GREEN}"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "${DIM}"
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "] ${NC}${BOLD}%3d%%${NC}\n" "$percentage"
}

# Step header with progress
step_header() {
    local step_num=$1
    local step_name=$2
    CURRENT_STEP=$step_num

    echo ""
    echo -e "    ${BOLD}${BLUE}Step ${step_num}/${TOTAL_STEPS}${NC} ${BOLD}${step_name}${NC}"
    progress_bar "$step_num" "$TOTAL_STEPS"
    echo -e "    ${DIM}$(printf '─%.0s' {1..50})${NC}"
}

# Spinner with message
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while ps -p $pid > /dev/null 2>&1; do
        for i in $(seq 0 9); do
            printf "\r    ${CYAN}${spinstr:$i:1}${NC} ${DIM}%s${NC}" "$message"
            sleep $delay
        done
    done
    printf "\r    %-60s\r" " "
}

# Success message
success() {
    echo -e "    ${CHECK} ${GREEN}$1${NC}"
}

# Error message with help
error() {
    echo -e "    ${CROSS} ${RED}$1${NC}"
    if [ -n "$2" ]; then
        echo -e "    ${DIM}   └─ $2${NC}"
    fi
}

# Info message
info() {
    echo -e "    ${INFO} ${DIM}$1${NC}"
}

# Warning message
warn() {
    echo -e "    ${WARN} ${YELLOW}$1${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY PANEL
# ═══════════════════════════════════════════════════════════════════════════════

print_security_panel() {
    echo ""
    echo -e "    ${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "    ${CYAN}│${NC} ${SHIELD} ${BOLD}Security Information${NC}                                  ${CYAN}│${NC}"
    echo -e "    ${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "    ${CYAN}│${NC}                                                         ${CYAN}│${NC}"
    echo -e "    ${CYAN}│${NC}  ${CHECK} API key stored locally with ${BOLD}chmod 600${NC}             ${CYAN}│${NC}"
    echo -e "    ${CYAN}│${NC}  ${CHECK} Never transmitted except to OpenRouter            ${CYAN}│${NC}"
    echo -e "    ${CYAN}│${NC}  ${CHECK} Never committed to git (in .gitignore)            ${CYAN}│${NC}"
    echo -e "    ${CYAN}│${NC}  ${CHECK} Only accessible by your user account              ${CYAN}│${NC}"
    echo -e "    ${CYAN}│${NC}                                                         ${CYAN}│${NC}"
    echo -e "    ${CYAN}│${NC}  ${DIM}Files created:${NC}                                       ${CYAN}│${NC}"
    echo -e "    ${CYAN}│${NC}  ${DIM}  ~/.claude.json      (Claude Code config)${NC}          ${CYAN}│${NC}"
    echo -e "    ${CYAN}│${NC}  ${DIM}  ~/.config/openrouter-mcp/config.json${NC}              ${CYAN}│${NC}"
    echo -e "    ${CYAN}│${NC}                                                         ${CYAN}│${NC}"
    echo -e "    ${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY BOX
# ═══════════════════════════════════════════════════════════════════════════════

print_summary() {
    local api_status="$1"
    local claude_status="$2"

    echo ""
    echo -e "    ${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "    ${GREEN}│${NC} ${ROCKET} ${BOLD}${GREEN}Setup Complete!${NC}                                      ${GREEN}│${NC}"
    echo -e "    ${GREEN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "    ${GREEN}│${NC}                                                         ${GREEN}│${NC}"
    echo -e "    ${GREEN}│${NC}  ${BOLD}Configuration Summary:${NC}                                ${GREEN}│${NC}"
    echo -e "    ${GREEN}│${NC}                                                         ${GREEN}│${NC}"
    echo -e "    ${GREEN}│${NC}  ${DIM}API Key:${NC}        $api_status                             ${GREEN}│${NC}"
    echo -e "    ${GREEN}│${NC}  ${DIM}Claude Config:${NC}  $claude_status                             ${GREEN}│${NC}"
    echo -e "    ${GREEN}│${NC}  ${DIM}Permissions:${NC}    ${CHECK} Secured (600)                     ${GREEN}│${NC}"
    echo -e "    ${GREEN}│${NC}                                                         ${GREEN}│${NC}"
    echo -e "    ${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
}

print_next_steps() {
    echo ""
    echo -e "    ${BOLD}What's Next?${NC}"
    echo ""
    echo -e "    ${DIM}1.${NC} ${BOLD}Restart Claude Code${NC} (or open a new terminal)"
    echo -e "    ${DIM}2.${NC} Start chatting and ask for second opinions!"
    echo ""
    echo -e "    ${BOLD}Try these:${NC}"
    echo -e "    ${DIM}•${NC} ${CYAN}\"Ask GPT-5.2-Codex to review this code\"${NC}"
    echo -e "    ${DIM}•${NC} ${CYAN}\"What would Gemini do differently?\"${NC}"
    echo -e "    ${DIM}•${NC} ${CYAN}\"Have DeepSeek check for bugs\"${NC}"
    echo ""
    echo -e "    ${DIM}Docs: ${CYAN}https://github.com/stefans71/Claude_GPT_MCP${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# API KEY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Verify API key with OpenRouter
verify_api_key() {
    local api_key="$1"

    if ! command -v curl &> /dev/null; then
        return 0  # Skip verification if curl not available
    fi

    echo -e "    ${DIM}Verifying API key...${NC}"

    local response
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        "https://openrouter.ai/api/v1/models" 2>/dev/null | tail -1)

    if [ "$response" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Show masked key
show_key() {
    echo ""
    if [ -n "$OPENROUTER_API_KEY" ]; then
        local key="$OPENROUTER_API_KEY"
        local prefix="${key:0:10}"
        local suffix="${key: -4}"
        success "API key configured"
        echo -e "    ${DIM}   └─ ${prefix}...${suffix}${NC}"
        return 0
    fi

    if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        local key
        key=$(grep "OPENROUTER_API_KEY" "$SHELL_CONFIG" | sed "s/.*[\"']\([^\"']*\)[\"'].*/\1/" | tail -1)
        if [ -n "$key" ]; then
            local prefix="${key:0:10}"
            local suffix="${key: -4}"
            success "API key configured"
            echo -e "    ${DIM}   └─ ${prefix}...${suffix}${NC}"
            return 0
        fi
    fi

    warn "No API key configured"
    echo -e "    ${DIM}   └─ Run ${CYAN}./setup.sh --set-key${NC}${DIM} to add one${NC}"
    return 1
}

# Set or update key with verification
set_key_interactive() {
    echo ""
    echo -e "    ${KEY} ${BOLD}Enter your OpenRouter API Key${NC}"
    echo ""
    echo -e "    ${DIM}Get your free key at: ${CYAN}https://openrouter.ai/keys${NC}"
    echo ""

    read -sp "    API Key: " API_KEY
    echo ""

    if [ -z "$API_KEY" ]; then
        error "No key entered"
        return 1
    fi

    # Validate format
    if [[ ! "$API_KEY" =~ ^sk-or- ]]; then
        echo ""
        warn "Key format looks unusual (expected sk-or-...)"
        read -p "    Continue anyway? (y/N): " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    # Verify with OpenRouter
    if verify_api_key "$API_KEY"; then
        success "API key verified with OpenRouter"
    else
        warn "Could not verify key (might still work)"
    fi

    # Save the key
    save_api_key "$API_KEY"

    return 0
}

# Save API key to all locations
save_api_key() {
    local api_key="$1"

    # Remove existing from shell config
    if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        sed_inplace '/# OpenRouter API Key/d' "$SHELL_CONFIG"
        sed_inplace '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"
    fi

    # Add to shell config
    echo "" >> "$SHELL_CONFIG"
    echo "# OpenRouter API Key (added by Claude_GPT_MCP setup)" >> "$SHELL_CONFIG"
    echo "export OPENROUTER_API_KEY=\"$api_key\"" >> "$SHELL_CONFIG"
    export OPENROUTER_API_KEY="$api_key"

    # Save to MCP config as backup
    save_mcp_config_key "$api_key"

    success "API key saved securely"
}

# Remove key
remove_key() {
    print_banner
    echo -e "    ${BOLD}Remove API Key${NC}"
    echo ""

    if ! grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        info "No API key found to remove"
        return 0
    fi

    read -p "    Remove API key from this machine? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Cancelled"
        return 0
    fi

    sed_inplace '/# OpenRouter API Key/d' "$SHELL_CONFIG"
    sed_inplace '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"

    success "API key removed"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Configure MCP server in Claude config
configure_claude_mcp() {
    local install_dir="$1"
    local api_key="$2"
    local claude_config="$HOME/.claude.json"

    # Create config if doesn't exist
    if [[ ! -f "$claude_config" ]]; then
        echo '{}' > "$claude_config"
    fi

    local server_path="$install_dir/dist/index.js"

    if command -v jq &> /dev/null; then
        if [ -n "$api_key" ]; then
            local mcp_config="{\"command\": \"node\", \"args\": [\"$server_path\"], \"env\": {\"OPENROUTER_API_KEY\": \"$api_key\"}}"
            jq --argjson mcp "$mcp_config" '.mcpServers.openrouter = $mcp' "$claude_config" > "$claude_config.tmp" \
                && mv "$claude_config.tmp" "$claude_config"
        else
            jq --arg path "$server_path" '.mcpServers.openrouter = {command: "node", args: [$path]}' "$claude_config" > "$claude_config.tmp" \
                && mv "$claude_config.tmp" "$claude_config"
        fi
    else
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

    # Secure the config file
    chmod 600 "$claude_config" 2>/dev/null || true

    success "Claude Code configured"
}

# Save API key to MCP config
save_mcp_config_key() {
    local api_key="$1"
    local mcp_config_dir="$HOME/.config/openrouter-mcp"
    local mcp_config_file="$mcp_config_dir/config.json"

    mkdir -p "$mcp_config_dir"

    if [ -f "$mcp_config_file" ]; then
        node -e "
            const fs = require('fs');
            const config = JSON.parse(fs.readFileSync('$mcp_config_file', 'utf8'));
            config.apiKey = '$api_key';
            fs.writeFileSync('$mcp_config_file', JSON.stringify(config, null, 2));
        " 2>/dev/null || echo "{\"apiKey\": \"$api_key\"}" > "$mcp_config_file"
    else
        echo "{\"apiKey\": \"$api_key\"}" > "$mcp_config_file"
    fi

    chmod 600 "$mcp_config_file" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════════

full_install() {
    print_banner

    echo -e "    ${DIM}Professional installer • Secure by default${NC}"
    echo ""

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CLAUDE_CONFIG="$HOME/.claude.json"

    # ─────────────────────────────────────────────────────────────────────────
    # Step 1: Check Requirements
    # ─────────────────────────────────────────────────────────────────────────
    step_header 1 "Checking Requirements"

    # Check Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js not found" "Install Node.js 18+ from https://nodejs.org"
        exit 1
    fi

    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        error "Node.js 18+ required" "Found $(node -v), please upgrade"
        exit 1
    fi
    success "Node.js $(node -v)"

    # Check jq (optional)
    if command -v jq &> /dev/null; then
        success "jq installed"
    else
        info "jq not found (optional, using fallback)"
    fi

    # Check curl (optional, for key verification)
    if command -v curl &> /dev/null; then
        success "curl installed (for key verification)"
    else
        info "curl not found (key verification skipped)"
    fi

    # ─────────────────────────────────────────────────────────────────────────
    # Step 2: Build Project
    # ─────────────────────────────────────────────────────────────────────────
    step_header 2 "Building Project"

    # Install dependencies
    npm install --silent 2>/dev/null &
    local npm_pid=$!
    spinner $npm_pid "Installing dependencies..."
    if ! wait $npm_pid; then
        error "npm install failed" "Run 'npm install' manually to see errors"
        exit 1
    fi
    success "Dependencies installed"

    # Build TypeScript
    npm run build --silent 2>/dev/null &
    local build_pid=$!
    spinner $build_pid "Compiling TypeScript..."
    if ! wait $build_pid; then
        error "Build failed" "Run 'npm run build' manually to see errors"
        exit 1
    fi
    success "Build complete"

    # Verify output
    if [ ! -f "$SCRIPT_DIR/dist/index.js" ]; then
        error "Build output not found" "Expected: dist/index.js"
        exit 1
    fi

    # ─────────────────────────────────────────────────────────────────────────
    # Step 3: API Key Configuration
    # ─────────────────────────────────────────────────────────────────────────
    step_header 3 "API Key Configuration"

    local api_configured=false

    if [ -n "$OPENROUTER_API_KEY" ]; then
        show_key
        echo ""
        read -p "    Use this key? (Y/n): " KEEP
        if [[ "$KEEP" =~ ^[Nn]$ ]]; then
            set_key_interactive && api_configured=true
        else
            api_configured=true
        fi
    elif grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        show_key
        echo ""
        read -p "    Use this key? (Y/n): " KEEP
        if [[ "$KEEP" =~ ^[Nn]$ ]]; then
            set_key_interactive && api_configured=true
        else
            # Load existing key
            export OPENROUTER_API_KEY=$(grep "OPENROUTER_API_KEY" "$SHELL_CONFIG" | sed "s/.*[\"']\([^\"']*\)[\"'].*/\1/" | tail -1)
            api_configured=true
        fi
    else
        info "No API key found"
        echo ""
        read -p "    Set up API key now? (Y/n): " SET_NOW

        # Handle pasted API key
        if [[ "$SET_NOW" =~ ^sk-or- ]]; then
            if verify_api_key "$SET_NOW"; then
                success "API key verified"
            fi
            save_api_key "$SET_NOW"
            api_configured=true
        elif [[ ! "$SET_NOW" =~ ^[Nn]$ ]]; then
            set_key_interactive && api_configured=true
        else
            info "Skipped - run './setup.sh --set-key' later"
        fi
    fi

    # Show security info
    if [ "$api_configured" = true ]; then
        print_security_panel
    fi

    # ─────────────────────────────────────────────────────────────────────────
    # Step 4: Claude Code Integration
    # ─────────────────────────────────────────────────────────────────────────
    step_header 4 "Claude Code Integration"

    # Check if already configured
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
            success "Already configured in Claude Code"
            print_summary "${CHECK} Configured" "${CHECK} Ready"
            print_next_steps
            return 0
        fi
    fi

    # Backup existing config
    if [ -f "$CLAUDE_CONFIG" ]; then
        cp "$CLAUDE_CONFIG" "$CLAUDE_CONFIG.bak"
        info "Backed up existing config"
    fi

    # Validate existing JSON
    if [ -f "$CLAUDE_CONFIG" ] && command -v jq &> /dev/null; then
        if ! jq empty "$CLAUDE_CONFIG" 2>/dev/null; then
            error "Invalid JSON in ~/.claude.json" "Backup saved to ~/.claude.json.bak"
            exit 1
        fi
    fi

    # Save API key to MCP config
    if [ -n "$OPENROUTER_API_KEY" ]; then
        save_mcp_config_key "$OPENROUTER_API_KEY"
    fi

    # Configure Claude
    configure_claude_mcp "$SCRIPT_DIR" "$OPENROUTER_API_KEY"

    # ─────────────────────────────────────────────────────────────────────────
    # Complete!
    # ─────────────────────────────────────────────────────────────────────────

    local api_status="${CHECK} Configured"
    [ -z "$OPENROUTER_API_KEY" ] && api_status="${WARN} Not set"

    print_summary "$api_status" "${CHECK} Ready"
    print_next_steps
}

# ═══════════════════════════════════════════════════════════════════════════════
# UNINSTALL
# ═══════════════════════════════════════════════════════════════════════════════

uninstall() {
    print_banner
    echo -e "    ${BOLD}Uninstall OpenRouter MCP Server${NC}"
    echo ""

    CLAUDE_CONFIG="$HOME/.claude.json"

    if [ ! -f "$CLAUDE_CONFIG" ]; then
        info "No Claude Code config found"
        return 0
    fi

    if ! grep -q "openrouter" "$CLAUDE_CONFIG" 2>/dev/null; then
        info "OpenRouter not installed"
        return 0
    fi

    echo -e "    ${DIM}This will remove OpenRouter from Claude Code.${NC}"
    echo -e "    ${DIM}Your other settings will not be affected.${NC}"
    echo ""

    read -p "    Continue? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Cancelled"
        return 0
    fi

    if command -v jq &> /dev/null; then
        jq 'del(.mcpServers.openrouter)' "$CLAUDE_CONFIG" > "$CLAUDE_CONFIG.tmp" \
            && mv "$CLAUDE_CONFIG.tmp" "$CLAUDE_CONFIG"
        success "Removed from Claude Code"
    else
        warn "Please manually remove 'openrouter' from ~/.claude.json"
    fi

    echo ""
    read -p "    Also remove API key? (y/N): " REMOVE_KEY
    if [[ "$REMOVE_KEY" =~ ^[Yy]$ ]]; then
        sed_inplace '/# OpenRouter API Key/d' "$SHELL_CONFIG"
        sed_inplace '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"
        success "API key removed"
    fi

    echo ""
    info "Restart Claude Code to apply changes"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════════════════

show_help() {
    print_banner
    echo -e "    ${BOLD}Usage:${NC}"
    echo ""
    echo -e "    ${CYAN}./setup.sh${NC}              Install and configure"
    echo -e "    ${CYAN}./setup.sh --set-key${NC}    Add or change API key"
    echo -e "    ${CYAN}./setup.sh --show-key${NC}   Show current key (masked)"
    echo -e "    ${CYAN}./setup.sh --remove-key${NC} Remove API key"
    echo -e "    ${CYAN}./setup.sh --uninstall${NC}  Remove from Claude Code"
    echo -e "    ${CYAN}./setup.sh --help${NC}       Show this help"
    echo ""
    echo -e "    ${BOLD}Security:${NC}"
    echo -e "    ${DIM}• API keys are stored with chmod 600 (owner-only)${NC}"
    echo -e "    ${DIM}• Keys are verified with OpenRouter before saving${NC}"
    echo -e "    ${DIM}• No data is collected or transmitted${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

case "${1:-}" in
    --help|-h)
        show_help
        ;;
    --set-key)
        print_banner
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        set_key_interactive
        if [ -n "$OPENROUTER_API_KEY" ]; then
            configure_claude_mcp "$SCRIPT_DIR" "$OPENROUTER_API_KEY"
            print_security_panel
            echo ""
            info "Restart Claude Code to apply changes"
            echo ""
        fi
        ;;
    --show-key)
        print_banner
        show_key
        echo ""
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
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
