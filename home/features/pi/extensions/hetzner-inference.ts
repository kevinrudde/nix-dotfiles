import { createProvider, openAICompletionsApi } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const baseUrl = "https://inference.hetzner.com/api/v1";

export default function (pi: ExtensionAPI) {
  pi.registerProvider(createProvider({
    id: "hetzner-inference",
    name: "Hetzner Inference",
    baseUrl,
    auth: {
      apiKey: {
        name: "Hetzner Inference API key",
        async login(interaction) {
          return {
            type: "api_key",
            key: await interaction.prompt({ type: "secret", message: "Hetzner Inference API key" }),
          };
        },
        async resolve({ credential }) {
          return credential?.key
            ? { auth: { apiKey: credential.key }, source: "stored API key" }
            : undefined;
        },
      },
    },
    models: [
      {
        id: "Qwen/Qwen3.6-35B-A3B-FP8",
        name: "Qwen 3.6 35B A3B FP8",
        api: "openai-completions",
        provider: "hetzner-inference",
        baseUrl,
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 262144,
        maxTokens: 16384,
        compat: {
          maxTokensField: "max_tokens",
        },
      },
    ],
    api: openAICompletionsApi(),
  }));
}
