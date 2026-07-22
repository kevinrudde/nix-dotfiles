/**
 * Minimal Footer — shows only what matters.
 *
 * Left:  ~/path/to/project git:branch± • model (thinking) • goal
 * Right: [####.........] 40% (128K)
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";

type RgbColor = { r: number; g: number; b: number };

type ModelWithThinking = {
  id?: string;
  provider?: string;
  reasoning?: boolean;
  contextWindow?: number;
  thinkingLevelMap?: Partial<Record<ThinkingLevel, string | null>>;
};

const THINKING_LEVELS: ThinkingLevel[] = [
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
];

const EFFORT_COLOR_STOPS: RgbColor[] = [
  { r: 142, g: 142, b: 147 }, // gray
  { r: 52, g: 199, b: 89 },   // green
  { r: 255, g: 214, b: 10 },  // yellow
  { r: 255, g: 159, b: 10 },  // orange
  { r: 255, g: 69, b: 58 },   // red
];

const CONTEXT_COLOR_STOPS: RgbColor[] = [
  { r: 52, g: 199, b: 89 },   // green
  { r: 255, g: 214, b: 10 },  // yellow
  { r: 255, g: 159, b: 10 },  // orange
  { r: 255, g: 69, b: 58 },   // red
];

const PROVIDER_COLORS: Record<string, RgbColor> = {
  anthropic: { r: 191, g: 90, b: 242 },
  openai: { r: 52, g: 199, b: 89 },
  google: { r: 66, g: 133, b: 244 },
  gemini: { r: 66, g: 133, b: 244 },
  github: { r: 175, g: 82, b: 222 },
  copilot: { r: 175, g: 82, b: 222 },
  openrouter: { r: 255, g: 159, b: 10 },
  ollama: { r: 142, g: 142, b: 147 },
  local: { r: 142, g: 142, b: 147 },
};

export default function (pi: ExtensionAPI) {
  let tuiRef: { requestRender(): void } | null = null;
  let thinkingLevel: string = "off";
  let currentModel: ModelWithThinking | undefined;
  let modelId: string | undefined;
  let contextWindow: number | undefined;
  let isDirty = false;

  // Keep values fresh so renders pick up changes immediately
  pi.on("model_select", async (event, _ctx) => {
    currentModel = event.model as ModelWithThinking;
    modelId = event.model.id;
    contextWindow = event.model.contextWindow;
    tuiRef?.requestRender();
  });

  pi.on("thinking_level_select", async (event, _ctx) => {
    thinkingLevel = event.level;
    tuiRef?.requestRender();
  });

  async function refreshDirty() {
    const insideWorkTree = await pi
      .exec("git", ["rev-parse", "--is-inside-work-tree"], { cwd: pi.cwd })
      .catch(() => undefined);

    if (insideWorkTree?.stdout.trim() !== "true") {
      if (isDirty) {
        isDirty = false;
        tuiRef?.requestRender();
      }
      return;
    }

    const result = await pi
      .exec("git", ["diff", "--stat"], { cwd: pi.cwd })
      .catch(() => undefined);
    const resultStaged = await pi
      .exec("git", ["diff", "--cached", "--stat"], { cwd: pi.cwd })
      .catch(() => undefined);
    const dirty =
      (result?.stdout.trim().length ?? 0) > 0 ||
      (resultStaged?.stdout.trim().length ?? 0) > 0;
    if (dirty !== isDirty) {
      isDirty = dirty;
      tuiRef?.requestRender();
    }
  }

  pi.on("turn_end", () => {
    void refreshDirty();
  });

  function formatContextWindow(n: number | undefined): string {
    if (!n) return "";
    if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(n % 1_000_000 === 0 ? 0 : 1)}M`;
    if (n >= 1_000) return `${(n / 1_000).toFixed(n % 1_000 === 0 ? 0 : 1)}K`;
    return `${n}`;
  }

  function middleTruncatePath(path: string, maxWidth = 42): string {
    if (visibleWidth(path) <= maxWidth) return path;

    const parts = path.split("/").filter(Boolean);
    const isHomePath = path.startsWith("~/");
    const isAbsolutePath = path.startsWith("/");
    const first = parts[0] === "~" ? parts[1] : parts[0];
    const last = parts[parts.length - 1];

    if (!first || !last) return truncateToWidth(path, maxWidth);

    const prefix = isHomePath
      ? `~/${first}`
      : isAbsolutePath
        ? `/${first}`
        : first;
    const shortened = `${prefix}/.../${last}`;

    return visibleWidth(shortened) <= maxWidth
      ? shortened
      : truncateToWidth(shortened, maxWidth);
  }

  function getCurrentDirectory(contextCwd: string): string {
    const home = process.env.HOME || process.env.USERPROFILE;
    const candidates = [pi.cwd, contextCwd, process.env.PWD, process.cwd()].filter(
      (candidate): candidate is string => typeof candidate === "string" && candidate.length > 0,
    );

    return candidates.find((candidate) => !home || candidate !== home) ?? candidates[0] ?? contextCwd;
  }

  function formatDirectory(path: string): string {
    const home = process.env.HOME || process.env.USERPROFILE;
    let cwd = path;
    if (home && cwd.startsWith(home)) {
      cwd = "~" + cwd.slice(home.length);
    }
    return middleTruncatePath(cwd);
  }

  function getExtensionStatusValues(statuses: unknown): string[] {
    if (statuses instanceof Map) {
      return Array.from(statuses.values());
    }
    if (Array.isArray(statuses)) {
      return statuses.filter((status): status is string => typeof status === "string");
    }
    return [];
  }

  function isThinkingLevel(value: string): value is ThinkingLevel {
    return THINKING_LEVELS.includes(value as ThinkingLevel);
  }

  function getSupportedThinkingLevels(model: ModelWithThinking | undefined): ThinkingLevel[] {
    if (!model || model.reasoning === false) return ["off"];

    const map = model.thinkingLevelMap ?? {};
    const supported = THINKING_LEVELS.filter((level) => map[level] !== null);
    return supported.length > 0 ? supported : ["off"];
  }

  function interpolateColor(position: number, stops: RgbColor[] = EFFORT_COLOR_STOPS): RgbColor {
    const safeStops = stops.length > 0 ? stops : EFFORT_COLOR_STOPS;
    const clamped = Math.max(0, Math.min(1, position));
    const scaled = clamped * (safeStops.length - 1);
    const leftIndex = Math.floor(scaled);
    const rightIndex = Math.min(safeStops.length - 1, leftIndex + 1);
    const mix = scaled - leftIndex;
    const left = safeStops[leftIndex];
    const right = safeStops[rightIndex];

    return {
      r: Math.round(left.r + (right.r - left.r) * mix),
      g: Math.round(left.g + (right.g - left.g) * mix),
      b: Math.round(left.b + (right.b - left.b) * mix),
    };
  }

  function colorRgb(text: string, { r, g, b }: RgbColor): string {
    return `\x1b[38;2;${r};${g};${b}m${text}\x1b[39m`;
  }

  function colorThinkingLabel(level: string, label: string, model: ModelWithThinking | undefined): string {
    if (!isThinkingLevel(level)) return label;

    const supported = getSupportedThinkingLevels(model);
    const supportedIndex = supported.indexOf(level);
    const fallbackIndex = THINKING_LEVELS.indexOf(level);
    const position =
      supportedIndex >= 0
        ? supported.length <= 1
          ? 0
          : supportedIndex / (supported.length - 1)
        : fallbackIndex / (THINKING_LEVELS.length - 1);

    return colorRgb(label, interpolateColor(position));
  }

  function getProviderColor(provider: string | undefined): RgbColor | undefined {
    if (!provider) return undefined;
    const normalized = provider.toLowerCase();
    return PROVIDER_COLORS[normalized];
  }

  pi.on("session_start", async (_event, ctx) => {
    currentModel = ctx.model as ModelWithThinking | undefined;
    modelId = ctx.model?.id;
    contextWindow = ctx.model?.contextWindow;
    thinkingLevel = pi.getThinkingLevel();
    void refreshDirty();

    ctx.ui.setFooter((tui, theme, footerData) => {
      tuiRef = tui;
      const unsub = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose() {
          unsub();
          tuiRef = null;
        },
        invalidate() {
          void refreshDirty();
        },
        render(width: number): string[] {
          // ── Current directory (with ~ for home) ──
          const cwd = formatDirectory(getCurrentDirectory(ctx.cwd));

          // ── Git branch + dirty marker ──
          const branch = footerData.getGitBranch();
          const dirtyMarker = branch && isDirty ? "±" : "";
          const branchStr = branch ? `git:${branch}${dirtyMarker}` : "";
          const branchColor: "warning" | "success" = isDirty ? "warning" : "success";

          // ── Model + dynamically colored thinking effort ──
          const activeModel = currentModel || (ctx.model as ModelWithThinking | undefined);
          const model = modelId || activeModel?.id || ctx.model?.id || "none";
          const provider = activeModel?.provider;
          const supportedThinkingLevels = getSupportedThinkingLevels(activeModel);
          const showThinkingLabel =
            thinkingLevel !== "off" || supportedThinkingLevels.length > 1;
          const thinkLabel = showThinkingLabel
            ? colorThinkingLabel(thinkingLevel, ` (${thinkingLevel})`, activeModel)
            : "";
          const providerColor = getProviderColor(provider);
          const modelStr = provider && !model.includes("/")
            ? (providerColor ? colorRgb(provider, providerColor) : theme.fg("muted", provider)) +
              theme.fg("dim", "/") +
              theme.fg("accent", model)
            : theme.fg("accent", model);

          // ── Optional status indicators from extensions ──
          const statuses = getExtensionStatusValues(footerData.getExtensionStatuses?.());
          const goalStatus = statuses.find((status) => /goal/i.test(status));
          const goalStr = goalStatus ? theme.fg("warning", goalStatus) : "";
          // pi-caveman already supplies its colored campfire and level label.
          const cavemanStr = statuses.find((status) => /caveman level:/i.test(status)) ?? "";

          const lastSlash = cwd.lastIndexOf("/");
          const pathPrefix = lastSlash >= 0 ? cwd.slice(0, lastSlash + 1) : "";
          const projectName = lastSlash >= 0 ? cwd.slice(lastSlash + 1) : cwd;
          const pathStr = projectName
            ? theme.fg("dim", pathPrefix) + theme.fg("accent", theme.bold(projectName))
            : theme.fg("dim", cwd);

          const leftParts = [
            pathStr,
            branchStr ? theme.fg(branchColor, branchStr) : "",
            modelStr + thinkLabel,
            goalStr,
            cavemanStr,
          ].filter(Boolean);
          const left = leftParts.join(theme.fg("dim", " • "));

          // ── Context bar ──
          const usage = ctx.getContextUsage();
          const pct = usage?.percent ?? 0;
          const pctStr =
            usage?.percent !== null ? `${Math.round(pct)}%` : "?";

          // Smooth context color: green → yellow → orange → red
          const ctxRgb = interpolateColor(pct / 100, CONTEXT_COLOR_STOPS);

          const BLOCKS = 10;
          const filled = Math.max(
            0,
            Math.min(BLOCKS, Math.round((pct / 100) * BLOCKS))
          );
          const bar =
            colorRgb("#".repeat(filled), ctxRgb) +
            theme.fg("dim", ".".repeat(BLOCKS - filled));
          const ctxWinStr = contextWindow ? ` (${formatContextWindow(contextWindow)})` : "";
          const right =
            colorRgb("[", ctxRgb) +
            bar +
            colorRgb("] ", ctxRgb) +
            colorRgb(pctStr, ctxRgb) +
            (pct >= 75 ? colorRgb(ctxWinStr, ctxRgb) : theme.fg("dim", ctxWinStr));

          // ── Layout: single row if it fits, else split into two ──
          const leftW = visibleWidth(left);
          const rightW = visibleWidth(right);

          if (leftW + rightW <= width) {
            // Single row: left … right
            const pad = " ".repeat(width - leftW - rightW);
            return [truncateToWidth(left + pad + right, width)];
          }

          // Two rows: left on top, context bar left-aligned below
          return [
            truncateToWidth(left, width),
            truncateToWidth(right, width),
          ];
        },
      };
    });
  });
}

// Source: https://gist.github.com/deepakness/81e716c4654d22bee6b3a830553ec004
// Pinned gist revision: 5563c39e2741d4a8ca5a68d306b7a42a9b145b3a
