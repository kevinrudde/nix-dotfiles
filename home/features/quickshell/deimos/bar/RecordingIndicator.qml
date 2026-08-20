import QtQuick
import qs
import qs.services
import qs.widgets

// Lit while an application is holding the microphone open. It sits immediately
// right of the centred window title rather than out in the right-hand group of
// status icons: this is the one thing on the bar that reports what is being
// done to you rather than what the machine is doing, and the middle is where
// the eye already rests.
//
// Steady rather than blinking. The bar has no other motion in it, so a pulsing
// icon here would pull attention every time it appeared — which is right for an
// alarm and wrong for a fact that is often perfectly expected.
//
// The glyph is drawn here rather than through `Pill`'s own label because it has
// to land on the title's capital band exactly: same ink height, same baseline.
// A font size cannot express that — `font.pixelSize` is a whole number of
// logical pixels, and on a fractionally scaled screen the rounding is worth
// more than a physical pixel. A Scale transform can, so the glyph is rendered
// at the title's size and then scaled by the ratio the metrics actually call
// for.
Pill {
    id: root

    required property var barScreen

    // A capital in the title's own font: its ink is the band the icon has to
    // fill. "H" rather than a letter with a rounded top, which overshoots the
    // cap line slightly by design.
    readonly property real capHeight: capInk.tightBoundingRect.height
    // The icon measured at that same size, so the ratio between the two is
    // exactly what the icon has to shrink by. A Nerd Font glyph is drawn to
    // fill the whole em box where a letter only reaches cap height, so the two
    // are never the same to begin with.
    readonly property real glyphScale: glyphInk.tightBoundingRect.height > 0 ? root.capHeight / glyphInk.tightBoundingRect.height : 1

    readonly property real inkWidth: glyphInk.tightBoundingRect.width * root.glyphScale
    // The line the glyph's ink sits on, with the cap band centred in the pill.
    // Reported as this item's baseline as well, so anchoring to the title's
    // baseline puts the icon on the same line the letters stand on.
    // Deliberately not rounded to a whole pixel: the glyph is already being
    // drawn through a fractional Scale, so there is no crispness left to
    // protect, and rounding here costs more than a physical pixel on a screen
    // scaled by 1.6 — which is the whole of the misalignment worth fixing.
    readonly property real inkBaseline: (root.height + root.capHeight) / 2

    visible: Audio.recording
    text: ""
    minPillWidth: 0
    horizontalPadding: Theme.pillPadIcon
    implicitWidth: Math.ceil(root.inkWidth) + root.horizontalPadding * 2
    baselineOffset: root.inkBaseline
    tooltip: Audio.recorders.length === 1 ? Audio.recorders[0] + " is using the microphone" : Audio.recorders.length + " applications are using the microphone"

    // Straight to the input side of the system popup — the question this icon
    // raises is which device, and whether to mute it.
    onClicked: {
        Audio.mode = "input";
        Popups.open("system", root.barScreen);
    }

    Text {
        id: glyph

        // Left at its natural size and position so the metrics below describe
        // it directly; the transforms do all the placing.
        color: Theme.danger
        font.bold: true
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLarge
        text: Theme.iconMicrophone
        textFormat: Text.PlainText

        // Scale first, about this item's own origin, then translate the
        // scaled ink into place: centred across the pill, and sitting on
        // `inkBaseline`. `tightBoundingRect` is measured from the baseline,
        // which is why `baselineOffset` appears in the vertical term.
        transform: [
            Scale {
                origin.x: 0
                origin.y: 0
                xScale: root.glyphScale
                yScale: root.glyphScale
            },
            Translate {
                x: root.width / 2 - root.glyphScale * (glyphInk.tightBoundingRect.x + glyphInk.tightBoundingRect.width / 2)
                y: root.inkBaseline - root.glyphScale * (glyph.baselineOffset + glyphInk.tightBoundingRect.y + glyphInk.tightBoundingRect.height)
            }
        ]
    }

    TextMetrics {
        id: capInk

        font.bold: true
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLarge
        text: "H"
    }

    TextMetrics {
        id: glyphInk

        font: glyph.font
        text: glyph.text
    }
}
