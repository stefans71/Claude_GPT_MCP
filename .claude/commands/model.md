# /model - Set Default OpenRouter Model

Set the default model for OpenRouter queries.

## Usage

```
/model GPT-5.2-Codex      # Set default to GPT-5.2-Codex
/model openai/gpt-5.2-codex  # Set default using full model ID
/model                    # Show current config
```

## Instructions

When the user runs `/model`, use MCP tools from the openrouter-bridge server.

**Behavior:**

1. `/model` (no arguments) → Use `get_config` tool to show current settings
2. `/model <name>` → Use `set_default_model` tool with `model: "<name>"`

**Response format:**

For `/model` (show config):
- Display the current default model
- List any custom shortcuts
- List favorite models

For `/model <name>` (set default):
- Confirm the model was set
- Show the resolved model ID (in case a shortcut was used)
