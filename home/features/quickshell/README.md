# Quickshell (deimos)

The bar, its popups, toasts and the volume OSD, as a Quickshell QML shell.
Nix side: `default.nix`, shell source: `deimos/`.

## Layout

```
deimos/
  shell.qml        entry point: one Bar and one ToastLayer per monitor, the OSD
  Theme.qml        every colour, size, font and icon codepoint
  services/        state and data, one singleton per concern
  widgets/         reusable building blocks with no domain knowledge
  bar/             the bar and its modules, each owning its own popup
  popups/          the popup contents
  notifications/   notification card, per-app group, toast overlay
  osd/             volume OSD
  scripts/         nmcli/brightnessctl/power-menu helpers
```

Directory names are QML module names: `bar/` is imported as `qs.bar`,
`widgets/` as `qs.widgets`, the shell root as `qs`. Home Manager therefore
links the tree with `recursive = true` — real directories holding individual
symlinks, rather than one symlink to the whole store path.

## Rules the modules follow

- **Colours, sizes and icons come from `Theme.qml` only.** A value that appears
  in two modules belongs there. Icons are stored as codepoints
  (`Theme.glyph(0xf294)`) because the Nerd Font glyphs live in Unicode
  private-use areas and do not survive editors, terminals and diffs.
- **A bar module owns its popup.** `BarPopup` is not an `Item`, so declaring it
  inside a pill costs nothing in the layout and keeps the pair in one file.
- **One popup is open at a time, and `services/Popups.qml` decides which.**
  Widgets call `Popups.toggle(name, screen)` instead of clearing their
  neighbours' flags, so a new popup does not mean touching every other widget.
- **Services hold no visuals and widgets hold no state.** Anything a second
  module might need (audio, battery, brightness, Bluetooth, network,
  notifications, system stats, the active submap, the bar's expanded state) is
  a singleton in `services/`.
- **A popup only combines domains that are all a glance-and-close away.**
  `SystemWidget`/`SystemPopup` fold volume, brightness, power profile, CPU/RAM
  and battery into one pill and one popup — none of them need more than a
  slider or a tap. Network and Bluetooth stay separate: both carry a real
  interaction (a Wi-Fi password prompt, pairing) that would make a combined
  popup either cramped or a second click deep.

## Working on it

Run straight from the repository, without a rebuild:

```bash
qs -p ~/.config/nix-dotfiles/home/features/quickshell/deimos
```

Quickshell reloads changed files itself. It prints the path of its log file at
startup; `qs log <file>` reads one back.

## Gotchas

- **A new file has to be `git add`ed before it reaches a build.** Flakes only
  see tracked files, so an untracked module is silently missing from the
  generation while `qs -p` still works.
- **`Timer`, `Connections` and the `color` type need `import QtQuick`,** even in
  a service that renders nothing.
- **A `Variants` delegate must not redeclare a `required property modelData`
  that its own component already declares** — the injection then misses it.
