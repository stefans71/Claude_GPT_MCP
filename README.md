# OpenRouter MCP Server for Claude Code

<div align="center">

**Bridge Claude Code to 200+ AI models**

GPT-4o • Gemini • DeepSeek • Llama • Mistral • and more

[Quick Start](#-quick-start) •
[Features](#-features) •
[Usage](#-usage) •
[Uninstall](#-uninstall) •
[Troubleshooting](#-troubleshooting)

---

</div>

## What is this?

An MCP (Model Context Protocol) server that lets you query **any AI model** directly from Claude Code. Get second opinions, compare approaches, or use specialized models — all without leaving your coding session.

```
You: "Ask GPT-4o if there's a better way to handle this error"

Claude: [queries GPT-4o via OpenRouter]

Claude: "GPT-4o suggests using a Result type instead of try/catch..."
```

## ✨ Features

| Feature | Description |
|---------|-------------|
| **200+ Models** | Access GPT-4o, Gemini, DeepSeek, Llama, Mistral, and more |
| **Dynamic Model List** | Fetches available models from OpenRouter API |
| **Custom Shortcuts** | Create aliases like `fast` → `gpt-4o-mini` |
| **Favorites** | Save your go-to models for quick access |
| **Default Model** | Set your preferred model for all queries |
| **Secure** | API key stored locally, never uploaded |

## 📋 Prerequisites

Before installing, you need:

| Requirement | Where to get it |
|-------------|-----------------|
| **Claude Code CLI** | [claude.ai/download](https://claude.ai/download) (requires Pro/Max subscription or API key) |
| **Node.js 18+** | [nodejs.org](https://nodejs.org) |
| **OpenRouter Account** | [openrouter.ai](https://openrouter.ai) (free tier available) |
| **OpenRouter API Key** | [openrouter.ai/keys](https://openrouter.ai/keys) |

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/stefans71/Claude_GPT_MCP.git
cd Claude_GPT_MCP

# Run the installer
./setup.sh
```

The installer will:
1. ✓ Check Node.js version
2. ✓ Install dependencies & build
3. ✓ Prompt for your OpenRouter API key
4. ✓ Configure Claude Code automatically

**That's it!** Restart Claude Code and you're ready to go.

## 💬 Usage

Once installed, just ask Claude to query other models:

### Ask Any Model
```
"Ask GPT-4o to review this function"
"Get Gemini's opinion on this architecture"
"Ask DeepSeek to suggest optimizations"
```

### List Available Models
```
"What models are available on OpenRouter?"
"Show me models that match 'llama'"
```

### Set Default Model
```
"Set my default model to gpt-4o"
```

### Create Shortcuts
```
"Add a shortcut 'fast' for openai/gpt-4o-mini"
```

### Manage Favorites
```
"Add claude-3-opus to my favorites"
"Show my OpenRouter config"
```

## 🔧 CLI Commands

Manage your installation with these commands:

```bash
./setup.sh              # Install/reinstall
./setup.sh --set-key    # Change API key
./setup.sh --show-key   # View current key (masked)
./setup.sh --remove-key # Remove API key
./setup.sh --uninstall  # Remove from Claude Code
./setup.sh --help       # Show all options
```

## 🗑️ Uninstall

To completely remove OpenRouter MCP Server:

```bash
# Run the uninstaller
./setup.sh --uninstall
```

This will:
- Remove OpenRouter from Claude Code config
- Optionally remove your API key
- **Does NOT** delete the cloned repository

To also remove the repository:
```bash
cd ..
rm -rf Claude_GPT_MCP
```

<details>
<summary><b>Manual Uninstall</b></summary>

If the uninstaller doesn't work:

1. **Remove from Claude Code config:**
   ```bash
   # Edit ~/.claude.json and remove the "openrouter" entry
   nano ~/.claude.json
   ```

2. **Remove API key (optional):**
   ```bash
   # Edit your shell config and remove the OPENROUTER_API_KEY line
   nano ~/.bashrc  # or ~/.zshrc
   ```

3. **Delete the repository:**
   ```bash
   rm -rf /path/to/Claude_GPT_MCP
   ```

</details>

## 📁 Files & Locations

| File | Purpose |
|------|---------|
| `~/.claude.json` | Claude Code MCP server config |
| `~/.config/openrouter-mcp/config.json` | Your preferences (default model, favorites, shortcuts) |
| `~/.bashrc` or `~/.zshrc` | API key environment variable |

## 🐛 Troubleshooting

### "OPENROUTER_API_KEY not set"
```bash
./setup.sh --show-key   # Check if key exists
./setup.sh --set-key    # Set a new key
```

### MCP server not loading
```bash
claude --mcp-debug      # See detailed MCP logs
```

### Model not found
```
"List models matching 'gpt'"   # Search for available models
```

### Check your config
```
"Show my OpenRouter config"    # View current settings
```

## 🤝 Contributing

Contributions welcome! Please feel free to submit issues and pull requests.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">

**Built for the Claude Code community**

[Report Issue](https://github.com/stefans71/Claude_GPT_MCP/issues) •
[OpenRouter Docs](https://openrouter.ai/docs)

</div>
