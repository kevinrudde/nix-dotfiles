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

`pi-cursor-sdk` and `pi-vision-proxy` are intentionally not installed.

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
