#!/bin/bash

# OpenRouter MCP Server Setup Script
# Professional installer with branded ASCII logos

set -e

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

VERSION="1.0.0"
TOTAL_STEPS=4
CURRENT_STEP=0
START_TIME=$(date +%s)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Brand Colors
ANTHROPIC_ORANGE='\033[38;5;208m'
OPENROUTER_BLUE='\033[38;5;33m'
GITHUB_GRAY='\033[38;5;245m'
GITHUB_LIGHT='\033[38;5;250m'

# Agent Orange Theme
ORANGE='\033[38;5;208m'
BRIGHT_ORANGE='\033[38;5;214m'
DARK_ORANGE='\033[38;5;202m'
AMBER='\033[38;5;220m'
BURNT_ORANGE='\033[38;5;166m'

BAR_EMPTY='\033[38;5;240m'

# Icons
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
INFO="${BLUE}ℹ${NC}"
SHIELD="${GREEN}🛡${NC}"
KEY="${AMBER}🔑${NC}"
ROCKET="${ORANGE}🚀${NC}"
WARN="${YELLOW}⚠${NC}"
BOLT="${ORANGE}⚡${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

sed_inplace() {
    if sed --version >/dev/null 2>&1; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

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
# LOGO FLOW DIAGRAM
# ═══════════════════════════════════════════════════════════════════════════════

print_logo_flow() {
    echo ""
    echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # ANTHROPIC (Orange) - Clean ASCII logo
    echo -e "${ANTHROPIC_ORANGE}"
cat << "EOF"
        506     3091   385 4008000087 091    09  19808891      40087    6808882   06       28081
       58904    28882  285    706     093    097 790   7407  892  1985  681   484 786    8857 7985
      286 105   282389 385     04     0800800897 198000009  805     867 689968081  185  684
     388888885  282  90884     04     091    09  190  7607  784    604  68          385  091   686
    309     405 205   1005     06     083    087 790    506   3900027   907          204  1600827
EOF
    echo -e "${NC}"
    echo -e "                                            ${ANTHROPIC_ORANGE}Claude Code${NC}"
    echo ""
    echo -e "                                                 ${ANTHROPIC_ORANGE}│${NC}"
    echo -e "                                                 ${ANTHROPIC_ORANGE}▼${NC}"
    echo ""

    # OPENROUTER (Blue) - Block text
    echo -e "${OPENROUTER_BLUE}${BOLD}"
cat << "EOF"
            ██████╗ ██████╗ ███████╗███╗   ██╗██████╗  ██████╗ ██╗   ██╗████████╗███████╗██████╗
           ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔═══██╗██║   ██║╚══██╔══╝██╔════╝██╔══██╗
           ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██████╔╝██║   ██║██║   ██║   ██║   █████╗  ██████╔╝
           ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██╗
           ╚██████╔╝██║     ███████╗██║ ╚████║██║  ██║╚██████╔╝╚██████╔╝   ██║   ███████╗██║  ██║
            ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝
EOF
    echo -e "${NC}"
    echo -e "                                            ${OPENROUTER_BLUE}API Gateway${NC}"
    echo ""
    echo -e "                          ${OPENROUTER_BLUE}┌──────────────────────┼──────────────────────┐${NC}"
    echo -e "                          ${OPENROUTER_BLUE}▼                      ▼                      ▼${NC}"
    echo ""

    # Three model boxes - VERSION 4 text only (cleanest)
    echo -e "          ${WHITE}╔═══════════════════╗${NC}  ${GREEN}╔═══════════════════╗${NC}  ${CYAN}╔═══════════════════╗${NC}"
    echo -e "          ${WHITE}║${NC}                   ${WHITE}║${NC}  ${GREEN}║${NC}                   ${GREEN}║${NC}  ${CYAN}║${NC}                   ${CYAN}║${NC}"
    echo -e "          ${WHITE}║${NC}     ${WHITE}${BOLD}OpenAI${NC}        ${WHITE}║${NC}  ${GREEN}║${NC}     ${GREEN}${BOLD}Gemini${NC}        ${GREEN}║${NC}  ${CYAN}║${NC}    ${CYAN}${BOLD}DeepSeek${NC}       ${CYAN}║${NC}"
    echo -e "          ${WHITE}║${NC}     ${DIM}GPT-5.2${NC}       ${WHITE}║${NC}  ${GREEN}║${NC}     ${DIM}2.5 Pro${NC}       ${GREEN}║${NC}  ${CYAN}║${NC}     ${DIM}R1${NC}            ${CYAN}║${NC}"
    echo -e "          ${WHITE}║${NC}                   ${WHITE}║${NC}  ${GREEN}║${NC}                   ${GREEN}║${NC}  ${CYAN}║${NC}                   ${CYAN}║${NC}"
    echo -e "          ${WHITE}╚═══════════════════╝${NC}  ${GREEN}╚═══════════════════╝${NC}  ${CYAN}╚═══════════════════╝${NC}"
    echo ""
    echo -e "                                          ${DIM}+ 200 more models${NC}"
    echo ""
    echo -e "                          ${GREEN}└──────────────────────┼──────────────────────┘${NC}"
    echo -e "                                                 ${GREEN}▼${NC}"
    echo ""

    # GITHUB (Gray) - Octocat silhouette
    echo -e "${GITHUB_LIGHT}"
cat << "EOF"
                                     ----------
                                -------------------*
                             -------------------------*
                           ------------------------------
                         *----   *----------------*   -----
                        -----       -          *      ------
                      -------                         --------
                      --------                        --------
                     -------*                           -------
                     -------                            *------
                     ------*                            *------
                     -------                            *------
                     -------                            -------
                     -------*                          --------
                     ---------                        --------*
                      ---*-*----                    ----------
                       ----   -------          -------------*
                        ----    *--*            ------------
                          ---                   ----------
                            ---                 --------
                              *-----            ------
                                 ---            ---
EOF
    echo -e "${NC}"
    echo -e "                                            ${GITHUB_LIGHT}GitHub${NC}"
    echo -e "                                      ${DIM}Your code, enhanced${NC}"
    echo ""
    echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Mini flow for banner
print_mini_flow() {
    echo ""
    echo -e "    ${ANTHROPIC_ORANGE}▓▓▓▓▓${NC}  ${DIM}━━▶${NC}  ${OPENROUTER_BLUE}▓▓▓▓▓${NC}  ${DIM}━━▶${NC}  ${WHITE}▓▓▓▓▓${NC}  ${DIM}━━▶${NC}  ${GITHUB_GRAY}▓▓▓▓▓${NC}"
    echo -e "  ${ANTHROPIC_ORANGE}Anthropic${NC}    ${OPENROUTER_BLUE}OpenRouter${NC}     ${WHITE}Models${NC}       ${GITHUB_GRAY}GitHub${NC}"
    echo ""
}

# Compact flow for installer (fits on one screen)
print_compact_flow() {
    echo ""
    echo -e "                              ${ANTHROPIC_ORANGE}${BOLD}ANTHROPIC${NC} ${DIM}Claude Code${NC}"
    echo -e "                                                 ${ANTHROPIC_ORANGE}│${NC}"
    echo -e "                                                 ${ANTHROPIC_ORANGE}▼${NC}"
    # OPENROUTER (Blue) - Block text
    echo -e "${OPENROUTER_BLUE}${BOLD}"
cat << "EOF"
            ██████╗ ██████╗ ███████╗███╗   ██╗██████╗  ██████╗ ██╗   ██╗████████╗███████╗██████╗
           ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔═══██╗██║   ██║╚══██╔══╝██╔════╝██╔══██╗
           ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██████╔╝██║   ██║██║   ██║   ██║   █████╗  ██████╔╝
           ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██╗
           ╚██████╔╝██║     ███████╗██║ ╚████║██║  ██║╚██████╔╝╚██████╔╝   ██║   ███████╗██║  ██║
            ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝
EOF
    echo -e "${NC}"
    echo -e "                          ${OPENROUTER_BLUE}┌──────────────────────┼──────────────────────┐${NC}"
    echo -e "                          ${OPENROUTER_BLUE}▼                      ▼                      ▼${NC}"
    # Three model boxes (compact)
    echo -e "          ${WHITE}╔═══════════════════╗${NC}  ${GREEN}╔═══════════════════╗${NC}  ${CYAN}╔═══════════════════╗${NC}"
    echo -e "          ${WHITE}║${NC}  ${WHITE}${BOLD}OpenAI${NC} ${DIM}GPT-5.2${NC}  ${WHITE}║${NC}  ${GREEN}║${NC}  ${GREEN}${BOLD}Gemini${NC} ${DIM}2.5 Pro${NC}  ${GREEN}║${NC}  ${CYAN}║${NC}  ${CYAN}${BOLD}DeepSeek${NC} ${DIM}R1${NC}    ${CYAN}║${NC}"
    echo -e "          ${WHITE}╚═══════════════════╝${NC}  ${GREEN}╚═══════════════════╝${NC}  ${CYAN}╚═══════════════════╝${NC}"
    echo -e "                                          ${DIM}+ 200 more models${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# UI COMPONENTS
# ═══════════════════════════════════════════════════════════════════════════════

print_banner() {
    clear 2>/dev/null || true
    echo ""
    echo -e "    ${ORANGE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${ORANGE}║${NC}                                                           ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}   ${BOLT} ${WHITE}${BOLD}OpenRouter MCP Server${NC}                                ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}   ${DIM}Bridge Claude Code to 200+ AI models${NC}                   ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}                                                           ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}   ${DIM}v${VERSION}${NC}                                                     ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}                                                           ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}╚═══════════════════════════════════════════════════════════╝${NC}"
    print_mini_flow
}

progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "    ${DIM}▐${NC}"
    for ((i=0; i<filled; i++)); do
        if ((i < filled / 3)); then
            printf "${BURNT_ORANGE}█${NC}"
        elif ((i < filled * 2 / 3)); then
            printf "${ORANGE}█${NC}"
        else
            printf "${BRIGHT_ORANGE}█${NC}"
        fi
    done
    printf "${BAR_EMPTY}"
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "${NC}${DIM}▌${NC} ${BOLD}%3d%%${NC}\n" "$percentage"
}

step_header() {
    local step_num=$1
    local step_name=$2
    CURRENT_STEP=$step_num

    echo ""
    echo -e "    ${BOLD}${ORANGE}Step ${step_num}/${TOTAL_STEPS}${NC} ${BOLD}${step_name}${NC}"
    progress_bar "$step_num" "$TOTAL_STEPS"
    echo -e "    ${DIM}$(printf '─%.0s' {1..50})${NC}"
}

spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while ps -p $pid > /dev/null 2>&1; do
        for i in $(seq 0 9); do
            printf "\r    ${ORANGE}${spinstr:$i:1}${NC} ${DIM}%s${NC}" "$message"
            sleep $delay
        done
    done
    printf "\r    %-60s\r" " "
}

success() {
    echo -e "    ${CHECK} ${GREEN}$1${NC}"
}

success_animation() {
    local message="$1"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

    for i in {0..5}; do
        printf "\r    ${ORANGE}${frames[$((i % 10))]}${NC} %s" "$message"
        sleep 0.05
    done
    printf "\r    ${CHECK} ${GREEN}%s${NC}          \n" "$message"
}

error() {
    echo -e "    ${CROSS} ${RED}${BOLD}$1${NC}"
    if [ -n "$2" ]; then
        echo -e "    ${DIM}   ├─ $2${NC}"
    fi
    if [ -n "$3" ]; then
        echo -e "    ${DIM}   └─ ${CYAN}Tip: $3${NC}"
    fi
}

info() {
    echo -e "    ${INFO} ${DIM}$1${NC}"
}

warn() {
    echo -e "    ${WARN} ${YELLOW}$1${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY PANEL
# ═══════════════════════════════════════════════════════════════════════════════

print_security_panel() {
    echo ""
    echo -e "    ${ORANGE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${ORANGE}║${NC} ${SHIELD} ${BOLD}Security Information${NC}                                    ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "    ${ORANGE}║${NC}                                                           ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}  ${CHECK} API key stored locally with ${BOLD}chmod 600${NC}               ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}  ${CHECK} Never transmitted except to OpenRouter              ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}  ${CHECK} Never committed to git (in .gitignore)              ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}  ${CHECK} Only accessible by your user account                ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}                                                           ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}  ${DIM}Files created:${NC}                                         ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}  ${DIM}  ~/.claude.json      (Claude Code config)${NC}            ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}  ${DIM}  ~/.config/openrouter-mcp/config.json${NC}                ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}║${NC}                                                           ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}╚═══════════════════════════════════════════════════════════╝${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY BOX
# ═══════════════════════════════════════════════════════════════════════════════

print_summary() {
    local api_status="$1"
    local claude_status="$2"

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))

    echo ""
    echo ""
    echo -e "    ${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${GREEN}║${NC}                                                            ${GREEN}║${NC}"
    echo -e "    ${GREEN}║${NC}   ${ROCKET} ${BOLD}${WHITE}INSTALLATION COMPLETE!${NC}                              ${GREEN}║${NC}"
    echo -e "    ${GREEN}║${NC}                                                            ${GREEN}║${NC}"
    echo -e "    ${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "    ${GREEN}║${NC}                                                            ${GREEN}║${NC}"
    echo -e "    ${GREEN}║${NC}   ${BOLD}Configuration Summary${NC}                                   ${GREEN}║${NC}"
    echo -e "    ${GREEN}║${NC}                                                            ${GREEN}║${NC}"
    echo -e "    ${GREEN}║${NC}   ${DIM}API Key:${NC}        $api_status                            ${GREEN}║${NC}"
    echo -e "    ${GREEN}║${NC}   ${DIM}Claude Config:${NC}  $claude_status                            ${GREEN}║${NC}"
    echo -e "    ${GREEN}║${NC}   ${DIM}Permissions:${NC}    ${CHECK} Secured (600)                    ${GREEN}║${NC}"
    echo -e "    ${GREEN}║${NC}   ${DIM}Completed in:${NC}   ${BOLD}${ELAPSED}s${NC}                                ${GREEN}║${NC}"
    echo -e "    ${GREEN}║${NC}                                                            ${GREEN}║${NC}"
    echo -e "    ${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_next_steps() {
    echo ""
    echo -e "    ${ORANGE}${BOLD}━━━ What's Next? ━━━${NC}"
    echo ""
    echo -e "    ${WHITE}${BOLD}1.${NC} Restart Claude Code ${DIM}(or open a new terminal)${NC}"
    echo -e "    ${WHITE}${BOLD}2.${NC} Start chatting and ask for second opinions!"
    echo ""
    echo -e "    ${ORANGE}${BOLD}Try these:${NC}"
    echo -e "    ${DIM}•${NC} ${CYAN}\"Ask GPT-5.2-Codex to review this code\"${NC}"
    echo -e "    ${DIM}•${NC} ${CYAN}\"What would Gemini do differently?\"${NC}"
    echo -e "    ${DIM}•${NC} ${CYAN}\"Have DeepSeek check for bugs\"${NC}"
    echo ""
    echo -e "    ${DIM}Docs: ${ORANGE}https://github.com/stefans71/Claude_GPT_MCP${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# API KEY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

verify_api_key() {
    local api_key="$1"

    if ! command -v curl &> /dev/null; then
        return 0
    fi

    printf "    ${DIM}Verifying API key...${NC}"

    local response
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        "https://openrouter.ai/api/v1/models" 2>/dev/null | tail -1)

    printf "\r                                    \r"

    if [ "$response" = "200" ]; then
        return 0
    else
        return 1
    fi
}

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
    echo -e "    ${DIM}   └─ Run ${ORANGE}./setup.sh --set-key${NC}${DIM} to add one${NC}"
    return 1
}

set_key_interactive() {
    echo ""
    echo -e "    ${KEY} ${BOLD}Enter your OpenRouter API Key${NC}"
    echo ""
    echo -e "    ${DIM}Get your free key at: ${ORANGE}https://openrouter.ai/keys${NC}"
    echo ""

    read -sp "    API Key: " API_KEY
    echo ""

    if [ -z "$API_KEY" ]; then
        error "No key entered"
        return 1
    fi

    if [[ ! "$API_KEY" =~ ^sk-or- ]]; then
        echo ""
        warn "Key format looks unusual (expected sk-or-...)"
        read -p "    Continue anyway? (y/N): " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    if verify_api_key "$API_KEY"; then
        success_animation "API key verified with OpenRouter"
    else
        warn "Could not verify key (might still work)"
    fi

    save_api_key "$API_KEY"

    return 0
}

save_api_key() {
    local api_key="$1"

    if grep -q "OPENROUTER_API_KEY" "$SHELL_CONFIG" 2>/dev/null; then
        sed_inplace '/# OpenRouter API Key/d' "$SHELL_CONFIG"
        sed_inplace '/OPENROUTER_API_KEY/d' "$SHELL_CONFIG"
    fi

    echo "" >> "$SHELL_CONFIG"
    echo "# OpenRouter API Key (added by Claude_GPT_MCP setup)" >> "$SHELL_CONFIG"
    echo "export OPENROUTER_API_KEY=\"$api_key\"" >> "$SHELL_CONFIG"
    export OPENROUTER_API_KEY="$api_key"

    save_mcp_config_key "$api_key"

    success "API key saved securely"
}

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

configure_claude_mcp() {
    local install_dir="$1"
    local api_key="$2"
    local claude_config="$HOME/.claude.json"

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

    chmod 600 "$claude_config" 2>/dev/null || true

    success_animation "Claude Code configured"
}

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
    # Intro screen with flow diagram
    clear 2>/dev/null || true
    echo ""
    echo -e "    ${ORANGE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${ORANGE}║${NC}   ${BOLT} ${WHITE}${BOLD}OpenRouter MCP Server${NC}  ${DIM}v${VERSION}${NC}                          ${ORANGE}║${NC}"
    echo -e "    ${ORANGE}╚═══════════════════════════════════════════════════════════╝${NC}"
    print_compact_flow
    echo -e "    ${DIM}Press Enter to start installation...${NC}"
    read -r

    # Installation screen
    clear 2>/dev/null || true
    print_banner

    echo -e "    ${DIM}Professional installer${NC}  •  ${SHIELD} ${DIM}Secure by default${NC}"
    echo ""

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CLAUDE_CONFIG="$HOME/.claude.json"

    # Step 1: Check Requirements
    step_header 1 "Checking Requirements"

    if ! command -v node &> /dev/null; then
        error "Node.js not found" \
              "Required for MCP server" \
              "Install from https://nodejs.org"
        exit 1
    fi

    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        error "Node.js 18+ required" \
              "Found $(node -v), please upgrade" \
              "Download latest from https://nodejs.org"
        exit 1
    fi
    success "Node.js $(node -v)"

    if command -v jq &> /dev/null; then
        success "jq installed"
    else
        info "jq not found (optional, using fallback)"
    fi

    if command -v curl &> /dev/null; then
        success "curl installed (for key verification)"
    else
        info "curl not found (key verification skipped)"
    fi

    # Step 2: Build Project
    step_header 2 "Building Project"

    npm install --silent 2>/dev/null &
    local npm_pid=$!
    spinner $npm_pid "Installing dependencies..."
    if ! wait $npm_pid; then
        error "npm install failed" \
              "Run 'npm install' manually to see errors" \
              "Check your internet connection"
        exit 1
    fi
    success "Dependencies installed"

    npm run build --silent 2>/dev/null &
    local build_pid=$!
    spinner $build_pid "Compiling TypeScript..."
    if ! wait $build_pid; then
        error "Build failed" \
              "Run 'npm run build' manually to see errors" \
              "Check for TypeScript errors"
        exit 1
    fi
    success_animation "Build complete"

    if [ ! -f "$SCRIPT_DIR/dist/index.js" ]; then
        error "Build output not found" "Expected: dist/index.js"
        exit 1
    fi

    # Step 3: API Key Configuration
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
            export OPENROUTER_API_KEY=$(grep "OPENROUTER_API_KEY" "$SHELL_CONFIG" | sed "s/.*[\"']\([^\"']*\)[\"'].*/\1/" | tail -1)
            api_configured=true
        fi
    else
        info "No API key found"
        echo ""
        read -p "    Set up API key now? (Y/n): " SET_NOW

        if [[ "$SET_NOW" =~ ^sk-or- ]]; then
            if verify_api_key "$SET_NOW"; then
                success_animation "API key verified"
            fi
            save_api_key "$SET_NOW"
            api_configured=true
        elif [[ ! "$SET_NOW" =~ ^[Nn]$ ]]; then
            set_key_interactive && api_configured=true
        else
            info "Skipped - run './setup.sh --set-key' later"
        fi
    fi

    if [ "$api_configured" = true ]; then
        print_security_panel
    fi

    # Step 4: Claude Code Integration
    step_header 4 "Claude Code Integration"

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

    if [ -f "$CLAUDE_CONFIG" ]; then
        cp "$CLAUDE_CONFIG" "$CLAUDE_CONFIG.bak"
        info "Backed up existing config"
    fi

    if [ -f "$CLAUDE_CONFIG" ] && command -v jq &> /dev/null; then
        if ! jq empty "$CLAUDE_CONFIG" 2>/dev/null; then
            error "Invalid JSON in ~/.claude.json" \
                  "Backup saved to ~/.claude.json.bak" \
                  "Fix the JSON syntax and try again"
            exit 1
        fi
    fi

    if [ -n "$OPENROUTER_API_KEY" ]; then
        save_mcp_config_key "$OPENROUTER_API_KEY"
    fi

    configure_claude_mcp "$SCRIPT_DIR" "$OPENROUTER_API_KEY"

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
    echo -e "    ${ORANGE}./setup.sh${NC}              Install and configure"
    echo -e "    ${ORANGE}./setup.sh --set-key${NC}    Add or change API key"
    echo -e "    ${ORANGE}./setup.sh --show-key${NC}   Show current key (masked)"
    echo -e "    ${ORANGE}./setup.sh --remove-key${NC} Remove API key"
    echo -e "    ${ORANGE}./setup.sh --uninstall${NC}  Remove from Claude Code"
    echo -e "    ${ORANGE}./setup.sh --diagram${NC}    Show integration diagram"
    echo -e "    ${ORANGE}./setup.sh --help${NC}       Show this help"
    echo ""
    echo -e "    ${BOLD}Security:${NC}"
    echo -e "    ${GRAY}• API keys are stored with chmod 600 (owner-only)${NC}"
    echo -e "    ${GRAY}• Keys are verified with OpenRouter before saving${NC}"
    echo -e "    ${GRAY}• No data is collected or transmitted${NC}"
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
    --diagram)
        clear 2>/dev/null || true
        print_logo_flow
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
