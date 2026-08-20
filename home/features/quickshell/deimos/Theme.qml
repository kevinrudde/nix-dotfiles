pragma Singleton

// Central design tokens: every colour, size, font and icon lives here. Modules
// never define their own — if a value shows up twice, it belongs in this file.
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Palette ──────────────────────────────────────────────────────────
    readonly property color primary: "#96d8ff"
    readonly property color foreground: "#d9e4ff"
    readonly property color muted: "#6f7285"
    readonly property color success: "#a8ff96"
    readonly property color warning: "#ffd166"
    readonly property color danger: "#ff5874"

    readonly property color background: Qt.rgba(21 / 255, 18 / 255, 27 / 255, 0.82)
    readonly property color backgroundStrong: Qt.rgba(10 / 255, 10 / 255, 16 / 255, 0.92)
    readonly property color activeBackground: Qt.rgba(150 / 255, 216 / 255, 255 / 255, 0.14)
    readonly property color hoverBackground: Qt.rgba(150 / 255, 216 / 255, 255 / 255, 0.20)
    // Solid rather than translucent: the bar is a flush, opaque strip, not a
    // floating panel with the desktop showing through it like the islands and
    // popups are.
    readonly property color barBackground: Qt.rgba(10 / 255, 10 / 255, 16 / 255, 1)

    // Notification cards sit on their own background and use a softer border
    // than the bar so a stack of them does not read as a grid of boxes.
    readonly property color cardBorder: Qt.rgba(150 / 255, 216 / 255, 255 / 255, 0.78)
    readonly property color criticalBackground: Qt.rgba(255 / 255, 88 / 255, 116 / 255, 0.13)

    // ── Typography ───────────────────────────────────────────────────────
    // One family for text and icons: the installed JetBrains Mono carries the
    // Nerd Font glyphs, so no separate icon font element is needed.
    readonly property string fontFamily: "JetBrains Mono"

    readonly property int fontSizeTiny: 11
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 14
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
    readonly property int barGap: 12

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
