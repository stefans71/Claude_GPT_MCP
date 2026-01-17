# OpenRouter MCP Server for Claude Code

This MCP server bridges Claude Code to OpenRouter, allowing you to query other AI models (GPT-4o, Gemini, DeepSeek, Llama, etc.) without leaving your Claude session.

## Prerequisites

Before installing, you need:

| Requirement | Description | Get it at |
|-------------|-------------|-----------|
| **Claude Code CLI** | Requires Max Pro subscription OR Anthropic API key | [claude.ai/code](https://claude.ai/code) |
| **Node.js 18+** | JavaScript runtime | [nodejs.org](https://nodejs.org) |
| **OpenRouter account** | With credits for API usage | [openrouter.ai](https://openrouter.ai) |
| **OpenRouter API key** | For authenticating requests | [openrouter.ai/keys](https://openrouter.ai/keys) |

## Quick Start

```bash
# Clone and setup
git clone <this-repo>
cd Claude_GPT_MCP
./setup.sh
```

The setup script will:
1. Check Node.js version
2. Install dependencies
3. Build the TypeScript
4. Prompt for your OpenRouter API key
5. Show the Claude Code configuration

## Key Management

```bash
./setup.sh              # Fresh install (build + prompt for key)
./setup.sh --set-key    # Add or change API key
./setup.sh --show-key   # Show current key (masked: sk-or-v1...xxxx)
./setup.sh --remove-key # Remove stored API key
./setup.sh --help       # Show help
```

## Claude Code Configuration

Add to `~/.claude.json`:

```json
{
  "mcpServers": {
    "openrouter": {
      "command": "node",
      "args": ["/path/to/Claude_GPT_MCP/dist/index.js"]
    }
  }
}
```

Then restart Claude Code: `claude --mcp-debug`

## Available MCP Tools

Once configured, Claude has access to these tools:

### `ask_model`
Query any OpenRouter model:
```
"Ask GPT-4o to review this function for edge cases"
"Get Gemini's opinion on this architecture"
"Ask DeepSeek for an alternative implementation"
```

### `list_models`
List available models with pricing:
```
"What models are available on OpenRouter?"
"List models that match 'llama'"
```

### `set_default_model`
Set your preferred default model:
```
"Set my default model to gpt-4o"
```

### `get_config`
View current configuration:
```
"Show my OpenRouter config"
```

### `add_shortcut`
Create custom model shortcuts:
```
"Add a shortcut 'fast' for openai/gpt-4o-mini"
```

### `add_favorite` / `remove_favorite`
Manage your favorites list:
```
"Add claude-3-opus to my favorites"
```

## Slash Commands

If you copy `.claude/commands/` to your project, you get:

| Command | Description |
|---------|-------------|
| `/models` | List available OpenRouter models |
| `/models gpt` | Filter models by name |
| `/model` | Show current config |
| `/model gpt-4o` | Set default model |

## Built-in Shortcuts

| Shortcut | OpenRouter Model ID |
|----------|---------------------|
| `gpt-4o` | openai/gpt-4o |
| `gpt-4-turbo` | openai/gpt-4-turbo |
| `claude-3-opus` | anthropic/claude-3-opus |
| `claude-3-sonnet` | anthropic/claude-3-sonnet |
| `gemini-pro` | google/gemini-pro |
| `deepseek-chat` | deepseek/deepseek-chat |
| `llama-3-70b` | meta-llama/llama-3-70b-instruct |

You can also use any full OpenRouter model ID directly.

## Configuration Files

| File | Purpose |
|------|---------|
| `~/.config/openrouter-mcp/config.json` | User preferences (default model, favorites, shortcuts) |
| `~/.bashrc` or `~/.zshrc` | API key environment variable |

## Example Workflow

```
You: "I'm not sure if this caching strategy is optimal. Ask GPT-4o for a second opinion."

Claude: [Uses ask_model tool with your code as context]

Claude: "GPT-4o suggests using an LRU cache instead of TTL-based expiration because..."
```

## Troubleshooting

### "OPENROUTER_API_KEY not set"
```bash
./setup.sh --show-key  # Check if key is set
./setup.sh --set-key   # Set/update the key
source ~/.bashrc       # Reload shell config
```

### MCP server not loading
```bash
claude --mcp-debug  # See detailed MCP loading logs
```

### Model not found
Use `list_models` to see available models, or check [openrouter.ai/models](https://openrouter.ai/models).

### Rate limits
OpenRouter has rate limits per model. If you hit them, wait or try a different model.
