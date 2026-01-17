# Ask GPT-4o, Gemini & 200+ Models — Without Leaving Claude Code

<div align="center">

**Get instant second opinions, code reviews, and architecture feedback directly inside Claude.**

*No context switching. No copy-paste. Just ask.*

[30-Second Install](#-quick-start) •
[See It Work](#-how-it-works) •
[Examples](#-examples) •
[Uninstall](#-uninstall)

---

> **This project was reviewed and improved by GPT-5.2-Codex via OpenRouter** — proving the tool works! See the [contribution details](#-built-with-multi-model-collaboration).

</div>

## Why You'll Love This

- **Instant code review** from GPT-4o without leaving Claude
- **Compare approaches** across different LLMs in one conversation
- **Catch edge cases** by getting a second opinion in seconds
- **Stay in flow** — no tab switching, no context loss

> *"Ask GPT-4o to review this function"* — that's it. Claude handles the rest.

This MCP server lets Claude query **200+ models** via [OpenRouter](https://openrouter.ai/models) — all in the same conversation.

## 🎯 How It Works

```
                    ┌─────────────────────────┐
                    │      You + Claude       │
                    │    (Opus 4.5 Pro)       │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │  📝 Write initial plan  │
                    └───────────┬─────────────┘
                                │
          ┌─────────────────────▼─────────────────────┐
          │  🐬 "Ask Codex to review this plan"       │
          │     ↓                                     │
          │  OpenRouter → GPT-Codex → feedback        │
          └─────────────────────┬─────────────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │  ✏️  Refine plan with    │
                    │     Codex's feedback    │
                    └───────────┬─────────────┘
                                │
          ┌─────────────────────▼─────────────────────┐
          │  🐬 "Have Codex check the updated plan"   │
          │     ↓                                     │
          │  OpenRouter → GPT-Codex → approval ✓     │
          └─────────────────────┬─────────────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │  🚀 Implement with      │
                    │     Claude Opus         │
                    └─────────────────────────┘
```

**Just ask naturally — Claude handles the rest:**

```
You: "Write a function to parse CSV files"

Claude: [writes the function]

You: "Ask GPT-4o if there's a better approach"
      ~~~~~~ ← just name the model you want

Claude: [calls OpenRouter API → GPT-4o]

Claude: "GPT-4o suggests using a streaming parser for large files..."

You: "Good idea, let's update it"

Claude: [updates the code]
```

No special commands needed. Just say "ask GPT-4o", "have Gemini review", "get DeepSeek's opinion" — Claude figures out which model to call.

## ✨ Features

| Feature | Description |
|---------|-------------|
| **200+ Models** | GPT-4o, Gemini, DeepSeek, Llama, Mistral, and more |
| **Same Session** | No switching apps or copying code |
| **Your Context** | Other models see what you're working on |
| **Quick Access** | Just ask Claude to get another opinion |

## 📋 Prerequisites

| Requirement | Where to get it |
|-------------|-----------------|
| **Claude Code CLI** | [claude.ai/download](https://claude.ai/download) (requires Pro subscription) |
| **Node.js 18+** | [nodejs.org](https://nodejs.org) |
| **OpenRouter Account** | [openrouter.ai](https://openrouter.ai) (free tier available) |
| **OpenRouter API Key** | [openrouter.ai/keys](https://openrouter.ai/keys) |

## 🚀 Quick Start

### Option A: Download ZIP (no git needed)

1. **Download:** [Click here to download ZIP](https://github.com/stefans71/Claude_GPT_MCP/archive/refs/heads/main.zip)
2. **Extract** the ZIP file (you'll get `Claude_GPT_MCP-main` folder)
3. **Open terminal in that folder:**
   - **Windows:** Right-click folder → "Open in Terminal"
   - **Mac:** Right-click folder → "New Terminal at Folder"
   - **Linux:** Right-click → "Open Terminal Here"
4. **Run the installer:**
   ```bash
   ./setup.sh
   ```
   Windows users may need: `bash setup.sh`

### Option B: Clone with git

```bash
git clone https://github.com/stefans71/Claude_GPT_MCP.git
cd Claude_GPT_MCP
./setup.sh
```

---

The installer handles everything:
- ✓ Installs dependencies
- ✓ Prompts for your OpenRouter API key
- ✓ Configures Claude Code automatically

**Then restart Claude Code and you're ready.**

## 💬 Examples

### Get a Second Opinion
```
"Ask GPT-4o to review this function"
"What would Gemini do differently here?"
"Have DeepSeek check this for edge cases"
```

### Compare Approaches
```
"Ask GPT-4o and Gemini how they'd implement this"
"Get Claude and GPT-4o's opinion on this architecture"
```

### Specialized Tasks
```
"Ask Codex to optimize this algorithm"
"Have DeepSeek explain this regex"
"Get Gemini's take on this SQL query"
```

### Explore Models
```
"What models are available?"
"Show me models good for coding"
"Set my default to GPT-4o"
```

## 🔧 Management

### Check Your Setup
```bash
./setup.sh --show-key   # View API key (masked)
./setup.sh --help       # All options
```

### Change API Key
```bash
./setup.sh --set-key
```

Or just ask Claude: *"Change my OpenRouter API key"*

## 🗑️ Uninstall

### Step-by-Step

**1. Open your terminal**
- **Windows:** Open PowerShell or Command Prompt
- **Mac:** Open Terminal (Applications → Utilities → Terminal)
- **Linux:** Open your terminal

**2. Navigate to where you installed it**
```bash
cd Claude_GPT_MCP
```
If you don't remember where, search for the folder or check where you cloned it.

**3. Run the uninstaller**
```bash
./setup.sh --uninstall
```

**4. Follow the prompts**
- It will ask to remove OpenRouter from Claude Code → **Yes**
- It will ask to remove your API key → **Your choice** (Yes = removes from this machine)

**5. Restart Claude Code**

That's it! OpenRouter is removed.

---

### Optional: Delete the files completely

After uninstalling, you can delete the folder:

```bash
# Make sure you're NOT inside the folder first
cd ..

# Then delete it
rm -rf Claude_GPT_MCP
```

<details>
<summary><b>Manual Uninstall (if the script doesn't work)</b></summary>

**Remove from Claude Code config:**
```bash
# Open the config file
nano ~/.claude.json    # Mac/Linux
notepad %USERPROFILE%\.claude.json   # Windows
```
Find and delete the `"openrouter": { ... }` section.

**Remove API key (optional):**
```bash
# Open your shell config
nano ~/.bashrc    # or ~/.zshrc on Mac
```
Find and delete the line: `export OPENROUTER_API_KEY="..."`

**Delete the folder:**
```bash
rm -rf /path/to/Claude_GPT_MCP
```

</details>

## 📁 Where Things Live

| File | What it does |
|------|--------------|
| `~/.claude.json` | Tells Claude Code about OpenRouter |
| `~/.config/openrouter-mcp/config.json` | Your preferences (default model, etc.) |
| `~/.bashrc` or `~/.zshrc` | Your API key |

## 🐛 Troubleshooting

**"OPENROUTER_API_KEY not set"**
```bash
./setup.sh --set-key
```

**MCP not loading**
```bash
claude --mcp-debug
```

**Model not found**
```
"What models are available?"
```

---

## Built with Multi-Model Collaboration

This project practices what it preaches. **GPT-5.2-Codex reviewed and improved this codebase** via OpenRouter, demonstrating real multi-model workflows:

| Reviewed by GPT-5.2-Codex | Improvements Made |
|---------------------------|-------------------|
| `setup.sh` | Fixed macOS compatibility, improved error handling, added config backups |
| `package.json` | Added missing metadata, keywords, proper exports |
| `README.md` | Made more enticing, added trust/security section |

This is exactly how the tool is meant to be used — Claude writes code, another model reviews it, and you get better results.

## Privacy & Security

- **Your API key stays local** — stored only on your machine
- **Direct to OpenRouter** — requests go straight to OpenRouter, not through any middleman
- **No telemetry** — we don't collect any data
- **Open source** — inspect the code yourself

## Cost

OpenRouter offers a **free tier** with many models available at no cost. Pay-per-use pricing for premium models. See [openrouter.ai/models](https://openrouter.ai/models) for current pricing.

---

<div align="center">

**Built for Claude Code users who want more perspectives**

MIT License

[Report Issue](https://github.com/stefans71/Claude_GPT_MCP/issues) •
[OpenRouter Models](https://openrouter.ai/models) •
[OpenRouter](https://openrouter.ai)

</div>
