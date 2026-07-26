# Pi

Home Manager configures Mise to install the current Pi release and declaratively manages:

- `~/.pi/agent/settings.json`
- `~/.pi/agent/extensions/nix-dotfiles/`
- global `AGENTS.md` and `APPEND_SYSTEM.md`
- `~/.pi/web-search.json`

Choose and authenticate providers interactively with `/login`; credentials stay
in Pi's runtime state and are never stored in this repository.

Pi runtime state remains outside Home Manager: sessions, trust decisions, and
packages downloaded by Pi under `~/.pi/agent/npm` or `~/.pi/agent/git`.

## Included setup

- `pi-web-access` uses Exa for search.
- `pi-codex-goal` tracks long-running work.
- `pi-agent-browser-native` provides browser automation.
- `rtk.ts` rewrites eligible Bash tool calls through RTK to reduce tool-output tokens.
- `pi-caveman` is pinned to upstream `v1.0.7`; enable it with `/caveman`.
- `minimal-footer.ts` is the pinned minimal-footer gist from the referenced setup.
- `@juicesharp/rpiv-ask-user-question` adds an `ask_user_question` tool for interactive follow-ups.
- `@tintinweb/pi-subagents` adds foreground/background subagents, parallel execution, steering, FleetView, and `/agents` management.
- `@ff-labs/pi-fff` replaces `find`/`grep` with fast FFF-backed search and adds `@`-mention file autocomplete.
- `pi-gh-dark-theme` supplies the `gh-dark` color theme.
- `pi-tool-display` provides compact tool output, diffs, and native input box rendering.
- `hetzner-inference.ts` registers Hetzner Inference's OpenAI-compatible API.

`pi-cursor-sdk` and `pi-vision-proxy` are intentionally not installed.

## Subagents and search

Use `Agent` for foreground or background subagents. Use `/agents` to inspect running agents, steer them, resume sessions, configure the widget, or manage schedules. Existing `cavecrew` skills remain useful for compressed investigator/builder/reviewer delegation; `pi-subagents` supplies the runtime and UI.

`pi-fff` registers `ffgrep`, `fffind`, and multi-grep tools. It can replace built-in search behavior and maintains ranked, git-aware results. Rebuild and restart Pi after changing packages so package resources load.

## Permission System

`@gotgenes/pi-permission-system` enforces tool and bash permissions. Config is managed in `extensions/pi-permission-system/config.json`.

Defaults: `rm -rf` / `git commit` / `git push` are **denied**. All other bash commands prompt (`ask`). File reads auto-allowed. `.env` files denied.

The permission-system config is managed by Home Manager (`extensions/pi-permission-system/config.json`). Any manual edits to `~/.pi/agent/extensions/pi-permission-system/config.json` are overwritten on rebuild. To customize, edit the source and rebuild.

## Hetzner Inference

Create token in [Hetzner Experiments](https://experiments.hetzner.com). After rebuilding, restart Pi and run:

```text
/login hetzner-inference
```

Pi prompts for token and stores it in runtime auth state (`~/.pi/agent/auth.json`), never `models.json`, repository, or Home-Manager store. Choose `hetzner-inference/Qwen/Qwen3.6-35B-A3B-FP8` with `/model`.

## Add a package

Add its pinned source to `settings.json`, for example:

```json
"packages": [
  "npm:@scope/pi-package@1.2.3",
  "git:github.com/owner/pi-package@v1.0.0"
]
```

Rebuild Home Manager, then start Pi. Pi installs missing configured packages on
startup. Use pinned npm versions and git tags/commits; do not use `pi install`,
since it edits the Home-Manager-managed settings file.

`pi-tool-display` config is managed at `tool-display-config.json`; manual edits
under `~/.pi/agent/extensions/pi-tool-display/` are overwritten on rebuild.

## Write an extension

Add a `.ts` file under `extensions/`. `default.nix` automatically exposes every
such file at `~/.pi/agent/extensions/<name>.ts`, which Pi auto-discovers.
For a new file in this Git flake, run `git add -N <file>` before rebuilding so
Nix includes it. Rebuild Home Manager and run `/reload` in an existing Pi
session (or restart Pi). `nix-dotfiles.ts` is a minimal working example. Test
an extension before rebuilding with:

```bash
pi -e home/features/pi/extensions/my-extension.ts
```
