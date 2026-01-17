# OpenRouter MCP Server Setup

This MCP server bridges Claude Code to OpenRouter, allowing you to query other AI models (GPT-5.2 Codex, Gemini, etc.) without leaving your Claude session.

## Prerequisites

- Node.js 18+
- OpenRouter API key (get one at https://openrouter.ai/keys)

## Installation

```bash
# 1. Navigate to the server directory
cd /path/to/openrouter-mcp-server

# 2. Install dependencies
npm install

# 3. Build the server
npm run build
```

## Configuration

### Step 1: Set your OpenRouter API key

Add to your shell profile (~/.bashrc, ~/.zshrc, etc.):

```bash
export OPENROUTER_API_KEY="sk-or-v1-your-key-here"
```

### Step 2: Add to Claude Code MCP config

Edit `~/.claude/claude_desktop_config.json` (create if it doesn't exist):

```json
{
  "mcpServers": {
    "openrouter": {
      "command": "node",
      "args": ["/absolute/path/to/openrouter-mcp-server/dist/index.js"],
      "env": {
        "OPENROUTER_API_KEY": "sk-or-v1-your-key-here"
      }
    }
  }
}
```

Or if you prefer using the environment variable:

```json
{
  "mcpServers": {
    "openrouter": {
      "command": "node",
      "args": ["/absolute/path/to/openrouter-mcp-server/dist/index.js"]
    }
  }
}
```

### Step 3: Restart Claude Code

```bash
claude --mcp-debug  # Use debug flag to verify MCP loads correctly
```

## Usage

Once configured, Claude will have access to these tools:

### `ask_model`
Query any OpenRouter model:
```
"Ask GPT-5.2 Codex to review this function for edge cases"
"Get Gemini's opinion on this architecture"
```

### `ask_codex`
Quick shortcut for GPT-5.2 Codex:
```
"Ask Codex if there's a more efficient algorithm for this"
```

### `list_models`
See available model shortcuts:
```
"What models are available through OpenRouter?"
```

## Available Model Shortcuts

| Shortcut | OpenRouter Model ID |
|----------|---------------------|
| `gpt-5.2-codex` | openai/gpt-5.2-codex |
| `gpt-4o` | openai/gpt-4o |
| `gemini-2-pro` | google/gemini-2.0-pro |
| `deepseek-v3` | deepseek/deepseek-chat-v3 |
| `llama-4-maverick` | meta-llama/llama-4-maverick |

You can also use any full OpenRouter model ID directly.

## Example Workflow

```
You: "I'm not sure if this caching strategy is optimal. Ask Codex for a second opinion."

Claude: [Uses ask_codex tool with your code as context]

Claude: "Codex suggests using an LRU cache instead of TTL-based expiration because..."
```

## Troubleshooting

### "OPENROUTER_API_KEY not set"
Ensure the key is set in your environment or in the MCP config's `env` block.

### MCP server not loading
Run `claude --mcp-debug` to see detailed MCP loading logs.

### Rate limits
OpenRouter has rate limits per model. If you hit them, wait a moment or try a different model.
