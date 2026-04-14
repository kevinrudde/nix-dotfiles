# nix-dotfiles

## Requirements

You need to install Nix, but we are not using their official installer. Instead, we are using the Determinate Systems Nix Installer. You can download it [here](https://install.determinate.systems/determinate-pkg/stable/Universal)!

To update your Nix version to the latest recommended release, use the following command
```bash
sudo determinate-nixd upgrade
```

### Homebrew

Some applications need to be installed through homebrew, so we just install it.
* https://brew.sh/

### SOPS for secrets (optional)
If you want to have your secrets decrypted lying in the repository, you need to have you age key located at `/home/<username>/.config/sops/age/keys.txt` (linux) or `/Users/<username>/Library/Application Support/sops/age/keys.txt` (darwin)

## Setup

1. Clone the repository
```bash
git clone git@github.com:kevinrudde/nix-dotfiles.git ~/.config/nix-dotfiles
```

2. Apply the configuration with
```bash
~/.config/nix-dotfiles/scripts/rebuild-system.sh
```

3. To apply future changes, run
```bash
rebuild-system
```

## Host Migrations

This repository includes a host migration system for Linux and macOS machines. The goal is to keep one-off setup steps separate from declarative state, while still making them repeatable and easy to audit.

Migration files live in:
```bash
migrations/system/<hostname>/
```

They are simple timestamped shell scripts such as `2026-04-14-init.sh`. The runner executes them in filename order and records applied migrations under:
```bash
~/.local/state/nix-dotfiles/migrations/system/<hostname>
```

You can run migrations manually from the repo root with:
```bash
./scripts/migrate.sh --host <hostname>
```

To create a new migration from the template, run:
```bash
./scripts/new-migration.sh
```

It will ask for a hostname and a short description, then create an executable file in `migrations/system/<hostname>/` with a timestamped filename.

The standard rebuild entrypoint is:
```bash
rebuild-system
```

The script version also works before your shell aliases are loaded:
```bash
~/.config/nix-dotfiles/scripts/rebuild-system.sh
```

On Linux it runs host migrations and then applies the matching Home Manager configuration for `<user>@<hostname>`. On macOS it runs host migrations and then applies the matching nix-darwin configuration for `<hostname>`. This keeps migrations out of Home Manager activation and makes rebuilds the single entrypoint.

To add a new migration, use `./scripts/new-migration.sh` or copy `migrations/templates/host-migration.sh.template` into the appropriate host directory and rename it to a timestamped `.sh` file. Keep each migration idempotent so it is safe even if you need to clear state and re-run it during development. These migrations run as the invoking user; if something truly needs root, keep that escalation explicit inside the migration itself, like the `intel-lpmd` example for `deimos`, instead of silently running the whole migration stream as `root`.
 
## MacOS Settings

### Keyboard

I am using the standard german layout, to have the same layout as Windows and Linux.
* Go to "Sytem Settings > Keyboard > Text Input".
* There you can change the layout by clicking on edit.
* Now another window is opening. Click on + in the left side to add another layout.
* Select German and then "German - Standard". Save it.

### Shortcuts

I have swapped my ctrl and cmd key on my external keyboard. You can simply do that aswell.
* Go to "Sytem Settings > Keyboard" and click on "Keyboard Shortcuts...".
* Switch to the "Modifier Keys" tab and select your external keyboard in the top
* Set Control to Command and Command to Control

### Change default shell

You can change your default shell with
```bash
chsh -s <Change this to your shell path which you can find in /etc/shells there is a comment with shells managed by nix> 
```
