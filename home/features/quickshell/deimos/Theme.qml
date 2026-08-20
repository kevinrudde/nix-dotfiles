pragma Singleton

// Central design tokens: every colour, size, font and icon lives here. Modules
// never define their own — if a value shows up twice, it belongs in this file.
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Palette ──────────────────────────────────────────────────────────
    // Tokyo Night, "night" variant. The upstream theme names its colours after
    // syntax roles (comment, fg_gutter, terminal_black); the roles below are
    // the shell's own, with the upstream name in a trailing comment so a value
    // can be traced back to the palette it came from.
    readonly property color primary: "#7aa2f7"       // blue
    readonly property color foreground: "#c0caf5"    // fg
    // dark5 rather than the palette's own `comment` (#565f89): a dimmed bar
    // icon still has to be readable at a glance from across the desk, which
    // comment-grey on the bar's background is not.
    readonly property color muted: "#737aa2"         // dark5
    readonly property color success: "#9ece6a"       // green
    readonly property color warning: "#e0af68"       // yellow
    readonly property color danger: "#f7768e"        // red
    // The one deliberately branded colour in an otherwise Tokyo Night bar —
    // Anthropic's own terracotta, used only for the Claude usage icon so it
    // reads as that specific app rather than another generic status pill. Left
    // off-palette on purpose; the theme's own orange would blend it back in.
    readonly property color claudeAccent: "#d97757"

    // Three surface levels, darkest first, so depth reads the way it does in
    // any dark UI: the further forward something sits, the lighter it is.
    // The bar is chrome and sits at the back; popups float above it; cards and
    // buttons nested inside a popup sit above that again.
    readonly property color barBackground: Qt.rgba(22 / 255, 22 / 255, 30 / 255, 1)          // bg_dark, solid
    readonly property color backgroundStrong: Qt.rgba(26 / 255, 27 / 255, 38 / 255, 0.96)    // bg
    readonly property color background: Qt.rgba(36 / 255, 40 / 255, 59 / 255, 0.82)          // bg_highlight-ish

    // The empty part of a meter, slider or switch. Its own level rather than a
    // reuse of `backgroundStrong`: a track has to stay visible against every
    // surface above, and one that matches the panel it is drawn on disappears —
    // which is exactly what the CPU and RAM meters on the bar used to do.
    readonly property color trackBackground: "#3b4261"                                       // fg_gutter

    readonly property color activeBackground: Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.16)
    readonly property color hoverBackground: Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.22)
    // What a hovered pill actually resolves to once `hoverBackground` is
    // composited over the strip. A count badge punches its digits out of
    // whatever is behind them, so it needs that as one solid colour rather
    // than the translucent tint — derived here instead of written out so the
    // two cannot drift apart.
    readonly property color barHoverSolid: {
        const tint = root.hoverBackground;
        const base = root.barBackground;
        const mix = (over, under) => tint.a * over + (1 - tint.a) * under;
        return Qt.rgba(mix(tint.r, base.r), mix(tint.g, base.g), mix(tint.b, base.b), 1);
    }

    // Notification cards sit on their own background and use a softer border
    // than the bar so a stack of them does not read as a grid of boxes.
    readonly property color cardBorder: Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.78)
    readonly property color criticalBackground: Qt.rgba(247 / 255, 118 / 255, 142 / 255, 0.13)

    // ── Typography ───────────────────────────────────────────────────────
    // One family for text and icons: the installed JetBrains Mono carries the
    // Nerd Font glyphs, so no separate icon font element is needed.
    readonly property string fontFamily: "JetBrains Mono"

    // Only for the count badge riding on an icon's corner: below fontSizeTiny
    // on purpose, since it has to stay smaller than the glyph it sits on.
    readonly property int fontSizeBadge: 10
    readonly property int fontSizeTiny: 11
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 14
    // Every icon glyph on the bar renders at this size — the launcher, the
    // tray, both toggles, and every status glyph in the right-hand group. A bar
    // of icons at four different sizes reads as clutter rather than as a row,
    // so a widget that wants a smaller icon is a widget that wants a different
    // icon. Text beside an icon (the clock, a signal percentage, a submap name)
    // is text and keeps its own size.
    readonly property int fontSizeIcon: 17
    readonly property int fontSizeDisplay: 22

    // ── Geometry ─────────────────────────────────────────────────────────
    // A dense, flush strip rather than a floating bar of boxed pills — the
    // bar reads as one surface, not a row of cards, so there is no gap left
    // between it and the screen edge for a shadow or a rounded corner to sit
    // in.
    readonly property int barHeight: 30
    // Applied to the bar's content, not the window itself: the strip stays
    // flush with the edge, but the first and last icon still get a little
    // breathing room instead of touching the screen corner.
    readonly property int barEdgeInset: 10
    // One spacing value for the whole bar: nothing here still has a
    // "collapsed vs. expanded" width, so there is no second value to keep in
    // sync with it.
    readonly property int barGap: 8

    // A count badge sits in the top-right corner of its icon rather than
    // beside it, overlapping the glyph by `badgeOverlap` — so a counted icon
    // costs a few pixels more width than a bare one instead of a whole extra
    // digit plus a gap.
    readonly property int badgeHeight: 13
    readonly property int badgePad: 2
    readonly property int badgeOverlap: 5

    readonly property int pillHeight: 28
    readonly property int pillRadius: 8
    readonly property int pillPad: 8
    readonly property int pillPadIcon: 7

    readonly property int rowRadius: 7
    readonly property int rowHeight: 28

    readonly property int popupRadius: 8
    readonly property int popupPad: 8
    readonly property int popupSpacing: 8
    // Gap between the bar and a popup anchored below it.
    readonly property int popupOffset: 18

    readonly property int toastWidth: 420
    readonly property int toastSpacing: 6

    // ── Icons (Nerd Font) ────────────────────────────────────────────────
    // Kept as codepoints rather than literals: the glyphs live in Unicode
    // private-use areas and do not survive editors, terminals and diffs
    // reliably.
    function glyph(code: int): string {
        return String.fromCodePoint(code);
    }

    readonly property string iconLauncher: root.glyph(0xf30a)
    readonly property string iconPower: root.glyph(0xf011)
    readonly property string iconUnknown: root.glyph(0xf071)
    readonly property string iconCheck: root.glyph(0xf00c)
    readonly property string iconBlank: ""

    readonly property string iconIdleOn: root.glyph(0xf06e)
    readonly property string iconIdleOff: root.glyph(0xf070)
    readonly property string iconBrightnessLow: root.glyph(0xf00de)
    readonly property string iconBrightnessMedium: root.glyph(0xf00df)
    readonly property string iconBrightnessHigh: root.glyph(0xf00e0)
    readonly property string iconCpu: root.glyph(0xf2db)
    readonly property string iconRam: root.glyph(0xefc5)
    readonly property string iconPullRequest: root.glyph(0xe726)
    // Plain Unicode, not a Nerd Font codepoint: there is no standard glyph
    // for "Claude" the way there is for a Linux distro or a git host, and a
    // guessed private-use codepoint would risk showing as a blank box
    // instead. An eight-pointed asterisk reads close enough to the real
    // mark and is guaranteed to render in any font.
    readonly property string iconClaude: "✳"
    readonly property string iconChecksSuccess: root.glyph(0xf012c)
    readonly property string iconChecksRunning: root.glyph(0xf046e)
    readonly property string iconChecksFailed: root.glyph(0xf0156)

    readonly property string iconVolumeMuted: root.glyph(0xf466)
    readonly property string iconVolumeLow: root.glyph(0xf026)
    readonly property string iconVolumeMedium: root.glyph(0xf027)
    readonly property string iconVolumeHigh: root.glyph(0xf028)
    readonly property string iconMicrophone: root.glyph(0xf130)

    readonly property string iconBluetooth: root.glyph(0xf294)
    readonly property string iconBluetoothOff: root.glyph(0xf00b2)
    readonly property string iconHeadphones: root.glyph(0xf025)
    readonly property string iconKeyboard: root.glyph(0xf030c)
    readonly property string iconMouse: root.glyph(0xf037d)

    readonly property string iconEthernet: root.glyph(0xf0200)
    readonly property string iconWifi4: root.glyph(0xf0928)
    readonly property string iconWifi3: root.glyph(0xf0925)
    readonly property string iconWifi2: root.glyph(0xf0922)
    readonly property string iconWifi1: root.glyph(0xf091f)
    readonly property string iconWifi0: root.glyph(0xf092f)

    readonly property string iconBatteryCharging: root.glyph(0xf0e7)
    readonly property string iconBatteryFull: root.glyph(0xf240)
    readonly property string iconBatteryThreeQuarters: root.glyph(0xf241)
    readonly property string iconBatteryHalf: root.glyph(0xf242)
    readonly property string iconBatteryQuarter: root.glyph(0xf243)
    readonly property string iconBatteryEmpty: root.glyph(0xf244)

    readonly property string iconBell: root.glyph(0xf009a)
    readonly property string iconBellEmpty: root.glyph(0xf009c)
    readonly property string iconBellDnd: root.glyph(0xf009b)
    readonly property string iconBellDndEmpty: root.glyph(0xf0a91)

    // ── Helpers ──────────────────────────────────────────────────────────
    function clampPercent(value: real): int {
        return Math.max(0, Math.min(100, Math.round(Number(value) || 0)));
    }
}
