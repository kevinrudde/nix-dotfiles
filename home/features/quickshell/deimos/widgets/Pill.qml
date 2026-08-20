import QtQuick
import qs

// The bar's basic element: a label with no chrome of its own — the bar is one
// flat strip, not a row of boxed pills, so an item is only ever visible as a
// rounded highlight on hover (or, for the rare item that wants to stand out
// at rest too, an explicit `background`).
Rectangle {
    id: root

    property string text: ""
    property color foreground: Theme.primary
    property color background: "transparent"
    property int fontSize: Theme.fontSizeLarge
    property int horizontalPadding: Theme.pillPad
    property int minPillWidth: 18
    property int maxTextWidth: 260
    // Shown on a long hover. Empty by default — most pills already say
    // everything they need to in their own label.
    property string tooltip: ""

    readonly property int textWidthLimit: Math.max(0, root.maxTextWidth)
    // Measured rather than read off the Text item: the label is elided, so its
    // own width is the limit and cannot tell us how wide it wants to be.
    readonly property int labelNaturalWidth: Math.ceil(metrics.advanceWidth(root.text))
    readonly property alias hovered: area.containsMouse

    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: Math.max(root.minPillWidth, Math.min(root.labelNaturalWidth, root.textWidthLimit) + root.horizontalPadding * 2)
    implicitHeight: Theme.pillHeight
    clip: true
    color: area.containsMouse ? Theme.hoverBackground : root.background
    radius: Theme.pillRadius

    StyledText {
        id: label

        anchors.centerIn: parent
        width: Math.min(root.labelNaturalWidth, root.textWidthLimit)
        clip: true
        text: root.text
        color: root.foreground
        elide: Text.ElideRight
        font.pixelSize: root.fontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        // AlignHCenter/AlignVCenter centre the glyph's advance box, not its
        // visible ink — fine for most text, but a single-glyph icon pill
        // (the launcher's Fedora badge, for one) draws asymmetrically inside
        // that box and reads as visibly off-centre. `ink` gives the real
        // bounds, relative to the baseline; shifting by the gap between that
        // and the advance box centres what the eye actually sees instead.
        transform: Translate {
            x: Math.round(ink.advanceWidth / 2 - (ink.tightBoundingRect.x + ink.tightBoundingRect.width / 2))
            y: Math.round(label.height / 2 - (label.baselineOffset + ink.tightBoundingRect.y + ink.tightBoundingRect.height / 2))
        }
    }

    FontMetrics {
        id: metrics

        font.bold: true
        font.family: Theme.fontFamily
        font.pixelSize: root.fontSize
    }

    TextMetrics {
        id: ink

        font: label.font
        text: label.text
    }

    MouseArea {
        id: area

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }

    HoverTooltip {
        anchorItem: root
        hovering: root.hovered
        text: root.tooltip
    }
}
