# /models - List OpenRouter Models

List available AI models from OpenRouter with pricing and context info.

## Usage

```
/models              # List top 20 models
/models gpt          # Filter by "gpt"
/models claude       # Filter by "claude"
/models llama 50     # Show up to 50 llama models
```

## Instructions

When the user runs `/models`, use the `list_models` MCP tool from the openrouter-bridge server.

**Arguments:**
- `filter` (optional): Search term to filter model names/IDs
- `limit` (optional): Maximum number of results (default: 20)

Parse the user's input:
- `/models` → call with no arguments
- `/models <term>` → call with `filter: "<term>"`
- `/models <term> <number>` → call with `filter: "<term>", limit: <number>`

Display the results formatted as a table or list showing:
- Model ID (for use with ask_model)
- Pricing per million tokens
- Context window size
