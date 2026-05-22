# AGENTS.md

Personal nix-dotfiles. Home-manager + Nix for user-space; a shell pipeline
for root-owned state. Entrypoint: `scripts/rebuild-system.sh`.

Hosts: **deimos** (Fedora Asahi, aarch64), **cachy** (CachyOS, x86_64),
**phobos** (macOS via nix-darwin).

## Layout

- `home/` — home-manager. `home/<host>.nix` per-host; `home/features/`
  reusable modules.
- `systems/<host>/` — per-host root-level state:
  - `rootfs/` — tree copied into `/` by `sync-host-config.sh`
  - `apply-system-state.sh` — always-run idempotent root ops
  - `migrations/*.sh` — one-shot stamped scripts
  - `sync-config-post.sh` — reacts to rootfs file changes
  - `packages.txt` + DNF repo lists (Fedora hosts)
- `scripts/rebuild-system.sh` runs: native package sync → migrations →
  rootfs sync → `apply-system-state.sh` → home-manager.

## Picking the right shape for a root-level change

1. **Static file under `/`** → drop in `rootfs/`. The sync preserves
   source mode and reports `Current` vs `Installed`. Trigger any
   service reload from `sync-config-post.sh`, guarded by
   `target_changed <path>`.
2. **Idempotent system op** (`systemctl enable`, `ln -sfn`, `groupadd`,
   `nmcli connection modify`, perm repair) → `apply-system-state.sh`.
   Must be a no-op when state already matches — guard every action
   with `is-enabled` / `getent` / `readlink -f` / value-compare.
3. **Real one-shot** (signed-tarball install, etc.) → `migrations/`.
   Stamped in `~/.local/state/nix-dotfiles/migrations/system/<host>/`
   after success. Rare in practice; most things end up as (1) or (2).

## Don'ts

- No `host="$DOTFILES_MIGRATION_HOST"` guard in migrations — the
  runner only picks up `systems/$host/migrations/`.
- No writes to `/opt`, `/usr/share`, `/etc`, `/var/lib` from a
  home-manager module. Use `rootfs/` or `apply-system-state.sh`.
- `apply-system-state.sh` runs on every rebuild; never print or
  invoke sudo on the happy path.
- New migrations are expensive — prefer (1) or (2) unless the
  operation truly only makes sense once.

## Verifying

```
git add -N <new files>
nix --extra-experimental-features 'nix-command flakes' eval --impure --raw \
  .#homeConfigurations.\"kevin@deimos\".config.home.activationPackage.drvPath
```

`git add -N` is needed so flake's git source picks up untracked files.
