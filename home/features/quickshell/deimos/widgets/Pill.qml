import QtQuick
import qs

// The bar's basic element: a bordered capsule around one label, clipped to a
// maximum text width so a long window title cannot push its neighbours off
// screen.
Rectangle {
    id: root

    property string text: ""
    property color foreground: Theme.primary
    property color background: Theme.background
    property int fontSize: Theme.fontSizeLarge
    property int horizontalPadding: Theme.pillPad
    property int minPillWidth: 18
    property int maxTextWidth: 260

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
    border.color: Theme.primary
    border.width: 1
    radius: Theme.pillRadius

    StyledText {
        anchors.centerIn: parent
        width: Math.min(root.labelNaturalWidth, root.textWidthLimit)
        clip: true
        text: root.text
        color: root.foreground
        elide: Text.ElideRight
        font.pixelSize: root.fontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    FontMetrics {
        id: metrics

        font.bold: true
        font.family: Theme.fontFamily
        font.pixelSize: root.fontSize
    }

    MouseArea {
        id: area

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }
}
