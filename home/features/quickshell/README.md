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
  scripts/         nmcli/brightnessctl/power-menu/gh helpers
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
  module might need (audio, battery, brightness, Bluetooth, network, Wi-Fi
  telemetry, GitHub, notifications, system stats, the active submap, the
  bar's expanded state) is a singleton in `services/`.
- **A service that only matters while its popup is open gates its own poll
  loop on that, rather than always running.** `WifiStats` pings the gateway
  and re-reads the network device's byte counters every few seconds — a fair
  cost while the network tab is visible, a pointless one otherwise. Because
  one `ConnectivityPopup` instance exists per monitor but `WifiStats` is a
  single shared singleton, the gate is set imperatively
  (`onOpenChanged`/`onModeChanged`), not as a continuous binding — two
  instances both binding the same singleton property from their own state
  would fight over it every time either one changed.
- **A remote data source goes through a script, never a QML HTTP client.**
  `GitHubInfo` shells out to `scripts/github-fetch.sh`, which does everything
  through `gh` — no token ever touches this repository, and `gh auth status`
  gates the whole fetch. It reports three lists — reviews requested directly
  of the user, reviews routed to a team the user is on, and PRs assigned to
  the user — plus each PR's check-rollup state; no notifications, no
  repository browser. GitHub's search has `user-review-requested` but no
  complementary team-only qualifier, so the team list is a plain
  `review-requested` fetch with the direct list subtracted from it in `jq`.
- **A popup combines domains that are the same kind of decision, even if each
  has a real interaction of its own.** `SystemWidget`/`SystemPopup` fold
  volume, brightness, power profile, CPU/RAM and battery into one pill and one
  popup — none of them need more than a slider or a tap.
  `ConnectivityWidget`/`ConnectivityPopup` fold Bluetooth and network into a
  second pill behind a tab switch instead: both are "which device am I
  talking to" questions, and each interaction (pairing, a Wi-Fi password
  prompt) still gets a whole tab of uncontested room rather than sharing space
  with the other. Bluetooth is the default tab — it sees more day-to-day use
  than switching networks does.

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
- **A `Variants` or `Repeater` delegate must not redeclare a
  `required property modelData` that its own component already declares** —
  the injection then misses it, and the delegate fails to create with
  "Required property modelData was not initialized". Applies to an inline
  `component` used as a delegate too, not just a plain `Item`.
- **Mutating network commands (`nmcli connection modify`, `radio wifi off`)
  are not something to run against the machine actually running the shell.**
  `network-action.sh`'s `wifi-power` and `set-dns` cases were exercised end
  to end with the script stubbed out behind a fake state file standing in
  for `nmcli` — proving the refresh cycle fires correctly — rather than by
  actually flipping the real radio or forcing a real reconnect, either of
  which is a live disruption with no undo. Only `wifi-status.sh`'s read side
  (ping, sysfs byte counters, `nmcli` reads) was run against the real
  connection.
- **A control that fires a detached, fire-and-forget command must not read
  its own displayed value from a property nothing then refreshes.** The
  Wi-Fi power switch did exactly this: `execDetached` changed the radio but
  never told `NetworkInfo` to re-poll, so `wifiEnabled` — and the switch's
  `checked` — froze at whatever they were when the popup opened. Every
  further click computed `!<the same stale value>` and re-sent the same
  direction instead of alternating. The fix routes the action through
  `NetworkInfo`'s existing action `Process`, whose `onExited` already
  refreshes — the same pattern `connect` already used, just not yet applied
  to this control.
