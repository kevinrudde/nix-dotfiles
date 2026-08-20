import QtQuick
import qs

// Horizontal fill bar. Read-only — see Slider for the interactive version.
Rectangle {
    id: root

    property int percent: 0
    property color fillColor: Theme.primary

    implicitHeight: 8
    color: Theme.backgroundStrong
    radius: root.height / 2

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Theme.clampPercent(root.percent) / 100
        color: root.fillColor
        radius: parent.radius
    }
}
