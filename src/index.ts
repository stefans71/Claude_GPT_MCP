#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

// OpenRouter API configuration
const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";

// Popular models available on OpenRouter
const AVAILABLE_MODELS: Record<string, string> = {
  "gpt-5.2-codex": "openai/gpt-5.2-codex",
  "gpt-4o": "openai/gpt-4o",
  "gemini-2-pro": "google/gemini-2.0-pro",
  "deepseek-v3": "deepseek/deepseek-chat-v3",
  "llama-4-maverick": "meta-llama/llama-4-maverick",
};

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

  const modelId = AVAILABLE_MODELS[model] || model;

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
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
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
              description: `Model to query. Shortcuts: ${Object.keys(AVAILABLE_MODELS).join(", ")}. Or use full OpenRouter model ID.`,
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
          required: ["model", "prompt"],
        },
      },
      {
        name: "list_models",
        description: "List available model shortcuts and their OpenRouter IDs",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "ask_codex",
        description:
          "Quick shortcut to ask GPT-5.2 Codex specifically. Great for code review and alternative implementations.",
        inputSchema: {
          type: "object",
          properties: {
            prompt: {
              type: "string",
              description: "The question or prompt for Codex",
            },
            context: {
              type: "string",
              description: "Optional context about current code or task",
            },
          },
          required: ["prompt"],
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

        if (typeof model !== "string" || model.trim() === "") {
          return {
            content: [{ type: "text", text: "Error: 'model' is required and must be a non-empty string." }],
            isError: true,
          };
        }
        if (typeof prompt !== "string" || prompt.trim() === "") {
          return {
            content: [{ type: "text", text: "Error: 'prompt' is required and must be a non-empty string." }],
            isError: true,
          };
        }
        const validContext = typeof context === "string" ? context : undefined;

        const response = await queryOpenRouter(model, prompt, validContext);
        return {
          content: [
            {
              type: "text",
              text: `**Response from ${model}:**\n\n${response}`,
            },
          ],
        };
      }

      case "list_models": {
        const modelList = Object.entries(AVAILABLE_MODELS)
          .map(([shortcut, id]) => `- \`${shortcut}\` → ${id}`)
          .join("\n");
        return {
          content: [
            {
              type: "text",
              text: `**Available model shortcuts:**\n\n${modelList}\n\nYou can also use any full OpenRouter model ID directly.`,
            },
          ],
        };
      }

      case "ask_codex": {
        const { prompt, context } = args as {
          prompt?: unknown;
          context?: unknown;
        };

        if (typeof prompt !== "string" || prompt.trim() === "") {
          return {
            content: [{ type: "text", text: "Error: 'prompt' is required and must be a non-empty string." }],
            isError: true,
          };
        }
        const validContext = typeof context === "string" ? context : undefined;

        const response = await queryOpenRouter("gpt-5.2-codex", prompt, validContext);
        return {
          content: [
            {
              type: "text",
              text: `**Response from GPT-5.2 Codex:**\n\n${response}`,
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
