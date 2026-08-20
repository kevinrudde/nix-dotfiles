import QtQuick
import qs

// Horizontal fill bar. Read-only — see Slider for the interactive version.
// The track is `trackBackground`, not one of the surface colours: at the 4px
// height the bar's CPU and RAM meters use, a track that matches the panel it
// sits on leaves nothing to read the fill against.
Rectangle {
    id: root

    property int percent: 0
    property color fillColor: Theme.primary

    implicitHeight: 8
    color: Theme.trackBackground
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
