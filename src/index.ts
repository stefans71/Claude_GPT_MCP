#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs";
import { homedir } from "os";
import { join } from "path";

// OpenRouter API configuration
const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
const OPENROUTER_MODELS_URL = "https://openrouter.ai/api/v1/models";

// Config file path
const CONFIG_DIR = join(homedir(), ".config", "openrouter-mcp");
const CONFIG_FILE = join(CONFIG_DIR, "config.json");

// Default model shortcuts (fallback if API fails)
const DEFAULT_SHORTCUTS: Record<string, string> = {
  "gpt-4o": "openai/gpt-4o",
  "gpt-4-turbo": "openai/gpt-4-turbo",
  "claude-3-opus": "anthropic/claude-3-opus",
  "claude-3-sonnet": "anthropic/claude-3-sonnet",
  "gemini-pro": "google/gemini-pro",
  "deepseek-chat": "deepseek/deepseek-chat",
  "llama-3-70b": "meta-llama/llama-3-70b-instruct",
};

interface UserConfig {
  defaultModel?: string;
  favoriteModels?: string[];
  shortcuts?: Record<string, string>;
}

interface OpenRouterModel {
  id: string;
  name: string;
  description?: string;
  pricing?: {
    prompt: string;
    completion: string;
  };
  context_length?: number;
  top_provider?: {
    max_completion_tokens?: number;
  };
}

interface OpenRouterResponse {
  choices: Array<{
    message: {
      content: string;
    };
  }>;
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
  error?: {
    message: string;
  };
}

// Cached models list
let cachedModels: OpenRouterModel[] | null = null;
let cacheTimestamp = 0;
const CACHE_TTL = 1000 * 60 * 60; // 1 hour cache

// Load user config
function loadConfig(): UserConfig {
  try {
    if (existsSync(CONFIG_FILE)) {
      const data = readFileSync(CONFIG_FILE, "utf-8");
      return JSON.parse(data);
    }
  } catch (error) {
    console.error("Error loading config:", error);
  }
  return {};
}

// Save user config
function saveConfig(config: UserConfig): void {
  try {
    if (!existsSync(CONFIG_DIR)) {
      mkdirSync(CONFIG_DIR, { recursive: true });
    }
    writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
  } catch (error) {
    console.error("Error saving config:", error);
    throw new Error(`Failed to save config: ${error}`);
  }
}

// Fetch models from OpenRouter API
async function fetchModels(apiKey?: string): Promise<OpenRouterModel[]> {
  const key = apiKey || process.env.OPENROUTER_API_KEY;

  if (!key) {
    throw new Error("OPENROUTER_API_KEY not set");
  }

  // Return cached if still valid
  if (cachedModels && Date.now() - cacheTimestamp < CACHE_TTL) {
    return cachedModels;
  }

  const response = await fetch(OPENROUTER_MODELS_URL, {
    headers: {
      Authorization: `Bearer ${key}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch models: ${response.status} ${response.statusText}`);
  }

  const data = (await response.json()) as { data: OpenRouterModel[] };
  cachedModels = data.data || [];
  cacheTimestamp = Date.now();

  return cachedModels;
}

// Get model ID from shortcut or full ID
function resolveModelId(model: string, config: UserConfig): string {
  // Check user shortcuts first
  if (config.shortcuts?.[model]) {
    return config.shortcuts[model];
  }
  // Check default shortcuts
  if (DEFAULT_SHORTCUTS[model]) {
    return DEFAULT_SHORTCUTS[model];
  }
  // Assume it's a full model ID
  return model;
}

async function queryOpenRouter(
  model: string,
  prompt: string,
  context?: string,
  apiKey?: string
): Promise<string> {
  const key = apiKey || process.env.OPENROUTER_API_KEY;

  if (!key) {
    throw new Error(
      "OPENROUTER_API_KEY not set. Set it as an environment variable or pass it as a parameter."
    );
  }

  const config = loadConfig();
  const modelId = resolveModelId(model, config);

  const messages = [];

  if (context) {
    messages.push({
      role: "system",
      content: `Context from the current coding session:\n\n${context}`,
    });
  }

  messages.push({
    role: "user",
    content: prompt,
  });

  const response = await fetch(OPENROUTER_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${key}`,
      "HTTP-Referer": "https://github.com/anthropics/claude-code",
      "X-Title": "Claude Code MCP Bridge",
    },
    body: JSON.stringify({
      model: modelId,
      messages,
      max_tokens: 4096,
    }),
  });

  if (!response.ok) {
    let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
    try {
      const errorData = await response.json();
      if (errorData?.error?.message) {
        errorMessage = `OpenRouter API error (${response.status}): ${errorData.error.message}`;
      }
    } catch {
      // Response wasn't JSON, use the status text
    }
    throw new Error(errorMessage);
  }

  const data = (await response.json()) as OpenRouterResponse;

  if (data.error) {
    throw new Error(`OpenRouter API error: ${data.error.message}`);
  }

  const content = data.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error("No response content from OpenRouter");
  }

  const usage = data.usage;
  const usageInfo = usage
    ? `\n\n---\n_Tokens: ${usage.prompt_tokens} in / ${usage.completion_tokens} out_`
    : "";

  return content + usageInfo;
}

// Create the MCP server
const server = new Server(
  {
    name: "openrouter-bridge",
    version: "1.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  const config = loadConfig();
  const defaultModel = config.defaultModel || "gpt-4o";

  return {
    tools: [
      {
        name: "ask_model",
        description:
          "Ask a question to any model available on OpenRouter. Use this to get a second opinion, compare approaches, or leverage different model strengths.",
        inputSchema: {
          type: "object",
          properties: {
            model: {
              type: "string",
              description: `Model to query. Use shortcuts like: ${Object.keys(DEFAULT_SHORTCUTS).slice(0, 5).join(", ")}. Or use any full OpenRouter model ID. Default: ${defaultModel}`,
            },
            prompt: {
              type: "string",
              description: "The question or prompt to send to the model",
            },
            context: {
              type: "string",
              description:
                "Optional context about the current task, code, or conversation to include",
            },
          },
          required: ["prompt"],
        },
      },
      {
        name: "list_models",
        description: "List available models from OpenRouter with pricing info",
        inputSchema: {
          type: "object",
          properties: {
            filter: {
              type: "string",
              description: "Optional filter to search model names/IDs (e.g., 'gpt', 'claude', 'llama')",
            },
            limit: {
              type: "number",
              description: "Max number of models to return (default: 20)",
            },
          },
        },
      },
      {
        name: "set_default_model",
        description: "Set the default model for ask_model queries",
        inputSchema: {
          type: "object",
          properties: {
            model: {
              type: "string",
              description: "Model ID or shortcut to set as default",
            },
          },
          required: ["model"],
        },
      },
      {
        name: "get_config",
        description: "Get current OpenRouter MCP configuration (default model, favorites, shortcuts)",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "add_shortcut",
        description: "Add a custom model shortcut for easier access",
        inputSchema: {
          type: "object",
          properties: {
            shortcut: {
              type: "string",
              description: "Short name for the model (e.g., 'codex', 'fast')",
            },
            model_id: {
              type: "string",
              description: "Full OpenRouter model ID (e.g., 'openai/gpt-4o')",
            },
          },
          required: ["shortcut", "model_id"],
        },
      },
      {
        name: "add_favorite",
        description: "Add a model to your favorites list",
        inputSchema: {
          type: "object",
          properties: {
            model: {
              type: "string",
              description: "Model ID or shortcut to add to favorites",
            },
          },
          required: ["model"],
        },
      },
      {
        name: "remove_favorite",
        description: "Remove a model from your favorites list",
        inputSchema: {
          type: "object",
          properties: {
            model: {
              type: "string",
              description: "Model ID or shortcut to remove from favorites",
            },
          },
          required: ["model"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "ask_model": {
        const { model, prompt, context } = args as {
          model?: unknown;
          prompt?: unknown;
          context?: unknown;
        };

        if (typeof prompt !== "string" || prompt.trim() === "") {
          return {
            content: [{ type: "text", text: "Error: 'prompt' is required and must be a non-empty string." }],
            isError: true,
          };
        }

        // Use default model if not specified
        const config = loadConfig();
        const selectedModel = typeof model === "string" && model.trim() !== ""
          ? model
          : config.defaultModel || "gpt-4o";

        const validContext = typeof context === "string" ? context : undefined;

        const response = await queryOpenRouter(selectedModel, prompt, validContext);
        return {
          content: [
            {
              type: "text",
              text: `**Response from ${selectedModel}:**\n\n${response}`,
            },
          ],
        };
      }

      case "list_models": {
        const { filter, limit } = args as {
          filter?: unknown;
          limit?: unknown;
        };

        try {
          const models = await fetchModels();
          let filtered = models;

          // Apply filter if provided
          if (typeof filter === "string" && filter.trim() !== "") {
            const f = filter.toLowerCase();
            filtered = models.filter(
              (m) =>
                m.id.toLowerCase().includes(f) ||
                m.name.toLowerCase().includes(f)
            );
          }

          // Sort by name
          filtered.sort((a, b) => a.name.localeCompare(b.name));

          // Apply limit
          const maxResults = typeof limit === "number" ? limit : 20;
          filtered = filtered.slice(0, maxResults);

          if (filtered.length === 0) {
            return {
              content: [
                {
                  type: "text",
                  text: filter
                    ? `No models found matching "${filter}".`
                    : "No models available.",
                },
              ],
            };
          }

          const modelList = filtered
            .map((m) => {
              const price = m.pricing
                ? `$${parseFloat(m.pricing.prompt) * 1000000}/M in, $${parseFloat(m.pricing.completion) * 1000000}/M out`
                : "pricing N/A";
              const ctx = m.context_length ? `${Math.round(m.context_length / 1000)}k ctx` : "";
              return `- **${m.id}**\n  ${m.name} | ${price} | ${ctx}`;
            })
            .join("\n\n");

          const total = models.length;
          const shown = filtered.length;
          const footer = shown < total
            ? `\n\n_Showing ${shown} of ${total} models. Use filter to narrow results._`
            : "";

          return {
            content: [
              {
                type: "text",
                text: `**Available OpenRouter Models:**\n\n${modelList}${footer}`,
              },
            ],
          };
        } catch (error) {
          // Fallback to default shortcuts if API fails
          const shortcutList = Object.entries(DEFAULT_SHORTCUTS)
            .map(([shortcut, id]) => `- \`${shortcut}\` → ${id}`)
            .join("\n");
          return {
            content: [
              {
                type: "text",
                text: `**Available shortcuts (API unavailable):**\n\n${shortcutList}\n\nYou can also use any full OpenRouter model ID directly.`,
              },
            ],
          };
        }
      }

      case "set_default_model": {
        const { model } = args as { model?: unknown };

        if (typeof model !== "string" || model.trim() === "") {
          return {
            content: [{ type: "text", text: "Error: 'model' is required." }],
            isError: true,
          };
        }

        const config = loadConfig();
        const resolvedId = resolveModelId(model, config);
        config.defaultModel = resolvedId;
        saveConfig(config);

        return {
          content: [
            {
              type: "text",
              text: `Default model set to: **${resolvedId}**\n\nThis will be used when no model is specified in ask_model.`,
            },
          ],
        };
      }

      case "get_config": {
        const config = loadConfig();
        const lines = [
          "**OpenRouter MCP Configuration:**",
          "",
          `**Default Model:** ${config.defaultModel || "gpt-4o (built-in default)"}`,
          "",
          "**Favorites:**",
        ];

        if (config.favoriteModels && config.favoriteModels.length > 0) {
          config.favoriteModels.forEach((m) => lines.push(`- ${m}`));
        } else {
          lines.push("_No favorites set_");
        }

        lines.push("", "**Custom Shortcuts:**");
        if (config.shortcuts && Object.keys(config.shortcuts).length > 0) {
          Object.entries(config.shortcuts).forEach(([k, v]) => {
            lines.push(`- \`${k}\` → ${v}`);
          });
        } else {
          lines.push("_No custom shortcuts_");
        }

        lines.push("", "**Built-in Shortcuts:**");
        Object.entries(DEFAULT_SHORTCUTS).forEach(([k, v]) => {
          lines.push(`- \`${k}\` → ${v}`);
        });

        lines.push("", `**Config file:** ${CONFIG_FILE}`);

        return {
          content: [{ type: "text", text: lines.join("\n") }],
        };
      }

      case "add_shortcut": {
        const { shortcut, model_id } = args as {
          shortcut?: unknown;
          model_id?: unknown;
        };

        if (typeof shortcut !== "string" || shortcut.trim() === "") {
          return {
            content: [{ type: "text", text: "Error: 'shortcut' is required." }],
            isError: true,
          };
        }
        if (typeof model_id !== "string" || model_id.trim() === "") {
          return {
            content: [{ type: "text", text: "Error: 'model_id' is required." }],
            isError: true,
          };
        }

        const config = loadConfig();
        config.shortcuts = config.shortcuts || {};
        config.shortcuts[shortcut.trim()] = model_id.trim();
        saveConfig(config);

        return {
          content: [
            {
              type: "text",
              text: `Shortcut added: \`${shortcut}\` → ${model_id}`,
            },
          ],
        };
      }

      case "add_favorite": {
        const { model } = args as { model?: unknown };

        if (typeof model !== "string" || model.trim() === "") {
          return {
            content: [{ type: "text", text: "Error: 'model' is required." }],
            isError: true,
          };
        }

        const config = loadConfig();
        const resolvedId = resolveModelId(model, config);
        config.favoriteModels = config.favoriteModels || [];

        if (config.favoriteModels.includes(resolvedId)) {
          return {
            content: [{ type: "text", text: `${resolvedId} is already in favorites.` }],
          };
        }

        config.favoriteModels.push(resolvedId);
        saveConfig(config);

        return {
          content: [
            {
              type: "text",
              text: `Added to favorites: **${resolvedId}**`,
            },
          ],
        };
      }

      case "remove_favorite": {
        const { model } = args as { model?: unknown };

        if (typeof model !== "string" || model.trim() === "") {
          return {
            content: [{ type: "text", text: "Error: 'model' is required." }],
            isError: true,
          };
        }

        const config = loadConfig();
        const resolvedId = resolveModelId(model, config);

        if (!config.favoriteModels || !config.favoriteModels.includes(resolvedId)) {
          return {
            content: [{ type: "text", text: `${resolvedId} is not in favorites.` }],
          };
        }

        config.favoriteModels = config.favoriteModels.filter((m) => m !== resolvedId);
        saveConfig(config);

        return {
          content: [
            {
              type: "text",
              text: `Removed from favorites: **${resolvedId}**`,
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return {
      content: [
        {
          type: "text",
          text: `Error: ${message}`,
        },
      ],
      isError: true,
    };
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("OpenRouter MCP Bridge server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
