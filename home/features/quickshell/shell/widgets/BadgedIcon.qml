import QtQuick
import qs

// An icon carrying its count in the top-right corner instead of next to it.
// On a 30px strip a digit sitting beside the glyph reads as a second icon —
// three of those in a row and the right-hand side becomes a string of numbers
// with pictures between them. In the corner the number is unmistakably an
// annotation of the icon it sits on, and the pill barely grows: the badge is
// allowed to overlap the glyph by `Theme.badgeOverlap`.
//
// The badge draws its own solid disc rather than floating bare digits over the
// glyph's ink — at this size the two would tangle. That disc is the bar's own
// colour, so `surface` has to follow the pill into its hover state; callers
// pass `hovered ? Theme.barHoverSolid : Theme.barBackground`.
Item {
    id: root

    property string icon: ""
    property color color: Theme.foreground
    property int count: 0
    property int fontSize: Theme.fontSizeIcon
    property color surface: Theme.barBackground
    // Anything past this reads as "N+": a third digit would be wider than the
    // glyph it is annotating.
    property int maxCount: 9

    readonly property bool badged: root.count > 0
    readonly property string badgeText: root.count > root.maxCount ? root.maxCount + "+" : String(root.count)

    implicitWidth: glyph.implicitWidth + (root.badged ? Math.max(0, badge.width - Theme.badgeOverlap) : 0)
    implicitHeight: glyph.implicitHeight

    // Left-anchored, not centred: the badge's overhang is added on the right
    // only, so centring the glyph in that widened box would push it off the
    // optical centre of the icons around it.
    CenteredGlyph {
        id: glyph

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.color
        font.pixelSize: root.fontSize
    }

    Rectangle {
        id: badge

        anchors.right: parent.right
        anchors.top: parent.top
        visible: root.badged
        // Never narrower than it is tall: a single digit gets a circle, two
        // characters stretch it into a capsule rather than a squashed oval.
        width: Math.max(Theme.badgeHeight, Math.ceil(badgeInk.advanceWidth) + Theme.badgePad * 2)
        height: Theme.badgeHeight
        radius: height / 2
        color: root.surface

        // CenteredGlyph again, for the same reason it is used for the icon:
        // a digit's advance box carries descent space it never fills, which
        // would leave the number riding high inside its own disc.
        CenteredGlyph {
            anchors.fill: parent
            text: root.badgeText
            color: root.color
            font.pixelSize: Theme.fontSizeBadge
        }

        TextMetrics {
            id: badgeInk

            font.bold: true
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBadge
            text: root.badgeText
        }
    }
}
