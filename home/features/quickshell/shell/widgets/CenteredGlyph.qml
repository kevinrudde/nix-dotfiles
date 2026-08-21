import QtQuick
import qs

// A single glyph — icon or digit — ink-centred rather than advance-box
// centred: the same correction `Pill`'s label applies to its own text,
// pulled out standalone for a widget that pairs an icon with a count badge
// as two separate items rather than one combined string. A plain
// `anchors.verticalCenter` only centres the box a glyph draws inside, not
// the ink itself — a digit's box carries descent space it never uses, which
// leaves the digit sitting visibly above true centre, and an icon glyph is
// often asymmetric on top of that. Combining icon and badge into one string
// instead would centre the pair as a single block, which still would not
// make the two line up with each other; each needs its own correction.
Text {
    id: root

    color: Theme.foreground
    font.bold: true
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeIcon
    textFormat: Text.PlainText
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    transform: Translate {
        x: Math.round(ink.advanceWidth / 2 - (ink.tightBoundingRect.x + ink.tightBoundingRect.width / 2))
        y: Math.round(root.height / 2 - (root.baselineOffset + ink.tightBoundingRect.y + ink.tightBoundingRect.height / 2))
    }

    TextMetrics {
        id: ink

        font: root.font
        text: root.text
    }
}
