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

## Design language

The bar is one flush, opaque strip — icons and text sit directly on it, not
inside bordered "pill" boxes. `Pill.qml`/`Island.qml` still exist as the
shared building blocks (sizing, click handling, hover), but at rest they
paint nothing: a highlighted rounded rect only appears on hover, or where an
item (`SubmapIndicator`) deliberately wants to stand out even at rest.
Popups keep their own separate, bordered-card look — that redesign was the
bar only, popups were not touched.

`Pill.qml`'s label also corrects for Nerd Font glyphs not sitting centred in
their own advance box — `AlignHCenter`/`AlignVCenter` centre that box, not
the ink inside it, which reads as visibly off-centre on an icon-only pill
(the launcher's Fedora badge, for one). A `TextMetrics`-measured
`tightBoundingRect` gives the real ink bounds; a `Translate` shifts by the
gap between that and the advance box. Every pill gets this for free, not
just icon-only ones, since the correction is self-measuring and near zero
for ordinary text.

Every `Pill` also carries a `tooltip` property (empty by default — most
labels already say what they need to), shown by `widgets/HoverTooltip.qml`
after a pause in hovering. It is its own `PopupWindow` rather than a plain
child `Item` specifically because `Pill` clips its own bounds — an
in-tree tooltip would be cut off the moment it grew past the pill's edge.
`mask: Region {}` keeps it click-through, the same as the volume OSD, so it
can never swallow a click meant for the desktop underneath. Anything with
its own hover source — `TrayWidget`'s icons, which are not `Pill`s — embeds
`HoverTooltip` directly rather than going through `Pill` at all.

Every bar item is always in its compact, icon-only form; there is no more
"expanded" variant that swaps an icon for icon-plus-percentage. Percentages,
device lists and everything else still live one click away in the popup.
`BarState.expanded` survives with a narrower job: it now only reveals the
system tray and the idle-inhibit toggle, the two things worth keeping out of
sight by default. `ExpandToggle`'s "<"/">" is that overflow chevron, not a
detail-level switch anymore.

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
- **`NetworkInfo.wired` already existed before it had a reason to be shown.**
  `network-status.sh` has listed ethernet devices from `nmcli dev status`
  since the LAN tab was first deferred as out of scope — the popup just
  never rendered any of it. Adding the "Ethernet" section to
  `ConnectivityPopup.qml` was mostly wiring, not new plumbing: IP, gateway
  and link speed (`/sys/class/net/<dev>/speed`) are only fetched for an
  entry that is actually `connected`, since `dev status` also lists a
  handful of unmanaged `veth*` "ethernet" devices a container runtime
  leaves behind — cheap to list, not worth extra `nmcli`/sysfs calls on.
  `NetworkInfo.activeWired()` mirrors the existing `activeEntry()` for
  Wi-Fi, and the section is independently visible from the Wi-Fi one above
  it — both links can be up at once, and a wired link carrying the real
  traffic is exactly when this tab is worth opening.
- **A remote data source goes through a script, never a QML HTTP client.**
  `GitHubInfo` shells out to `scripts/github-fetch.sh`, which does everything
  through `gh` — no token ever touches this repository, and `gh auth status`
  gates the whole fetch. It reports three lists — reviews requested directly
  of the user, reviews routed to a team the user is on, and PRs assigned to
  the user — plus each PR's check-rollup state; no notifications, no
  repository browser. GitHub's search has `user-review-requested` but no
  complementary team-only qualifier, so the team list is a plain
  `review-requested` fetch with the direct list subtracted from it in `jq`.
- **A number this shell cannot verify does not appear, even approximated.**
  `ClaudeUsage` shows token counts by day and by model, and the current
  5-hour rate-limit window's usage from Claude Code's own local session
  transcripts (`~/.claude/projects/**/*.jsonl`, which already carry
  `message.usage` and `message.model` per turn). Its rate-limit percentages
  (session, weekly, and any model-scoped window) come from a real read of
  Anthropic's OAuth usage endpoint, the same one Claude Code's own client
  reads — not a guess, and not shown at all if that read is not available.
- **A credential this shell only reads is never the one it renews.**
  `claude-usage.sh` reads the existing `accessToken`/`expiresAt`/
  `rateLimitTier`/`subscriptionType` straight out of `~/.claude/.credentials.json`
  and calls `GET /api/oauth/usage` with it — the exact design Basecamp's
  Omarchy `omarchy-agent-usage-claude` plugin uses. It never refreshes that
  token and never writes back to the credentials file; an expired token
  just degrades to `usageStatusText: "Sign-in expired"` plus whatever
  limits were last cached (dropping any whose `resetsAt` has already
  passed), with `authHelpText` pointing the user at `claude auth login` or
  simply starting Claude Code themselves. A missing token, a transport
  failure, and an HTTP error status each degrade the same way but with
  their own status text — a 429's `retry-after` header is surfaced in the
  message rather than retried against automatically. Live probes are
  throttled to at most one every 15 seconds regardless of the bar's own
  refresh cadence, via a small cache at
  `$XDG_CACHE_HOME/quickshell-claude-usage/limits.json`.
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
- **`Row` top-aligns children of different heights; it does not centre
  them.** `leftGroup`/`rightGroup` in `Bar.qml` are `RowLayout`, not `Row`,
  specifically so every child can carry `Layout.alignment: Qt.AlignVCenter`
  — without it, the launcher's 28px-tall icon pill and the shorter,
  borderless workspace numbers next to it are each perfectly centred *within
  themselves* but do not line up with each other, which reads as the
  launcher icon sitting low. A new bar widget only needs this if its own
  implicit height differs from its neighbours', but there is no visible pill
  border left to reveal that mismatch by eye — check it by screenshot, the
  way this one was found. The exact same rule applies one level down, inside
  a single pill's own content: `NotificationWidget`/`GitHubWidget` pair a
  count badge with an icon at a different font size, and both used to sit in
  a plain `Row` with `anchors.verticalCenter` on each child — which a `Row`
  silently ignores, since it sets its children's `y` itself. `ConnectivityWidget`
  had the identical bug and never showed it, purely because its two labels
  happen to share one font size. All three are `RowLayout` now.
- **`anchors.verticalCenter` only centres the box a glyph draws inside, not
  the ink itself.** A digit's box carries descent space it never uses, which
  leaves it sitting visibly above true centre — the same class of problem
  `Pill`'s own ink-centring `Translate` exists to fix for its label, just
  showing up one level lower once an icon and a count badge became two
  separate items instead of one string. `widgets/CenteredGlyph.qml` pulls
  that correction out standalone (it is generic over any single glyph, digit
  or icon) for exactly this case — a widget that needs an icon and something
  else, each independently centred, rather than one block centred as a
  whole. `NotificationWidget` and `GitHubWidget` both use it now, with the
  count rendered at `Theme.fontSizeSmall` — the same size the network tile's
  percentage already used — instead of inheriting the icon's larger size,
  so every number-as-badge on the bar reads at one consistent size.
- **A screenshot for review needs the output's native pixel size, not the
  logical size `hyprctl monitors` reports.** On a scaled output (2x here),
  `grim -g "x,y WxH"` and the physical PNG size disagree in ways that are
  easy to mis-crop against — `grim -o <name>` (no `-g`) sidesteps the whole
  question by asking the compositor for the output's own bounds directly.
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
- **A list a person is about to click must never move an item that is
  already on screen — only grow or shrink at one end.** `addToast` used to
  `unshift` each new toast to the front, pushing every already-visible one
  down a slot. A click timed against a toast's position could then land on
  whatever had just slid into that spot instead — clicking one notification
  and triggering a different one's action, which is exactly as confusing as
  it sounds. Confirmed by sending two real notifications a second apart
  through a probe instance and logging `toasts` on every change: with
  `unshift`, the second notification jumped to index 0 and the first moved
  to index 1; with `push` (the fix), the first stays at index 0 and the
  second only ever appends after it. `NotificationService.groups` sorts by
  `latestId` and is not protected against this the same way — a lower-risk
  spot to hit the same bug if the notification centre is ever reported to
  have it too.
- **A mathematically-centred string can still read as sitting high, if a
  descender elsewhere in the same string pulls the shared baseline down.**
  The clock's `20 Aug 14:09` measured as centred to within a rounding error
  (`Pill`'s ink-centring `Translate` computed a −1px shift, i.e. already
  correct) — but "Aug" is the only part of that string with a descender
  (the `g`), and Qt centres the string's whole ink box, descender space
  included. Next to an icon whose ink fills its box top-to-bottom evenly,
  that shifts every digit's *apparent* centre upward relative to it, even
  though the string is centred by measurement. Confirmed by putting the
  clock pill directly beside a `CenteredGlyph` bell and the power icon on
  the same reference line — lowercase "Aug" visibly sits high against both,
  uppercase "AUG" lines up with them exactly. `status.sh` formats the month
  with `%^b`, not `%b`, purely to remove the only descender from the
  string — not a `Pill`/centring-logic change.
- **A window title centred on the bar's own midpoint is not the same as one
  centred in the space actually left for it**, once the two side groups
  stop being close to the same width. `rightGroup` picked up six more
  widgets than `leftGroup` has this session; anchoring `WindowTitle` to
  `parent.horizontalCenter` alone left it sitting about twice as close to
  the right icons as to the launcher, with all the freed space pooling on
  the left. `anchors.horizontalCenterOffset: (leftGroup.width -
  rightGroup.width) / 2` re-centres it on the actual gap between the two
  groups instead of the bar's raw midpoint, and keeps doing so as either
  group's width changes — no magic number to revisit the next time a
  widget is added to either side.
- **`Popups.open(name, screen)` called from a `Timer`, not a real click,
  does not actually make a `BarPopup` visible on screen** — the Wayland
  focus grab a popup needs requires a serial tied to a genuine input event,
  which a Timer-fired property change does not carry. `qs log` still shows
  the true story: no QML type/binding errors means every row's bindings
  evaluated correctly against real data, which is what this is actually
  good for — it is a binding-correctness check, not a "does this render"
  check, and treating it as the latter earlier in this shell's history was
  a real gap. To see the actual pixels without a real click, embed a popup's
  `PopupSurface` content directly inside a plain, always-visible
  `PanelWindow` in a throwaway probe — same rendering, none of the layer-shell
  grab machinery to fight with.
