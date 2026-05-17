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

## Directory Structure

The repository is organized by responsibility:

```text
.
├── home/                  # Home Manager entrypoints and reusable user features
├── systems/
│   ├── <hostname>/        # Host-specific system files, native packages, migrations
│   └── shared/            # Shared system modules
├── scripts/               # Rebuild, migration, and sync entrypoints
├── migrations/.templates/ # Templates for generating new host migrations
└── bin/                   # Checked-in helper scripts used by hosts or migrations
```

Common host-owned files live under `systems/<hostname>/`:

- `packages.txt`: native packages installed by the host package sync script
- `copr-repos.txt`: optional Fedora COPR repositories enabled before package install
- `dnf-release-rpms.txt`: optional Fedora repository release RPMs installed before package install
- `dnf-enabled-repos.txt`: optional Fedora repository IDs enabled before package install
- `migrations/`: timestamped host migration scripts
- `default.nix`: optional system module for hosts that have one

## Host Migrations

This repository includes a host migration system for Linux and macOS machines. The goal is to keep one-off setup steps separate from declarative state, while still making them repeatable and easy to audit.

Migration files live in:
```bash
systems/<hostname>/migrations/
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

It will ask for a hostname and a short description, then create an executable file in `systems/<hostname>/migrations/` with a timestamped filename.

The standard rebuild entrypoint is:
```bash
rebuild-system
```

The script version also works before your shell aliases are loaded:
```bash
~/.config/nix-dotfiles/scripts/rebuild-system.sh
```

On Linux it runs host migrations and then applies the matching Home Manager configuration for `<user>@<hostname>`. On macOS it runs host migrations and then applies the matching nix-darwin configuration for `<hostname>`. This keeps migrations out of Home Manager activation and makes rebuilds the single entrypoint.

To add a new migration, use `./scripts/new-migration.sh` or copy `migrations/.templates/host-migration.sh.template` into `systems/<hostname>/migrations/` and rename it to a timestamped `.sh` file. Keep each migration idempotent so it is safe even if you need to clear state and re-run it during development. These migrations run as the invoking user; if something truly needs root, keep that escalation explicit inside the migration itself, like the `intel-lpmd` example for `deimos`, instead of silently running the whole migration stream as `root`.

## Host Native Packages

Linux hosts can define native packages in:
```bash
systems/<hostname>/packages.txt
```

Put one package name per line. Empty lines and `#` comments are ignored.

During `rebuild-system`, Linux hosts choose a native package sync backend from the current distro:

- Arch/Cachy-based hosts use `./scripts/paru-sync.sh`
- Fedora hosts use `./scripts/fedora-packages-sync.sh`

Fedora hosts can also define COPR repositories in:
```bash
systems/<hostname>/copr-repos.txt
```

Put one COPR repository per line, such as `owner/project` or `@group/project`. The Fedora sync enables these repositories before installing packages with `dnf`. Empty lines and `#` comments are ignored.

Fedora hosts can install repository release RPMs before package installation with:
```bash
systems/<hostname>/dnf-release-rpms.txt
```

Put one release RPM per line as `<installed-package-name> <rpm-url>`. The placeholder `{fedora}` is expanded with `rpm -E %fedora`.

Fedora hosts can enable existing DNF repository IDs before package installation with:
```bash
systems/<hostname>/dnf-enabled-repos.txt
```

Put one repository ID per line, such as `fedora-cisco-openh264`.

Fedora hosts can define signed vendor RPM repositories with:
```bash
systems/<hostname>/rpm-keys.txt
systems/<hostname>/dnf-repos/*.repo
```

Put one RPM signing key URL or file path per line in `rpm-keys.txt`. Repository files are installed into `/etc/yum.repos.d/` before installing packages.

You can run the sync scripts manually:
```bash
./scripts/paru-sync.sh --host <hostname>
./scripts/fedora-packages-sync.sh --host <hostname>
```

If there are no native package, Fedora COPR, RPM key, or DNF repository definitions for a host, the sync step is skipped.
 
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
