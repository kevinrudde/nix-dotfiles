import QtQuick
import qs

// Track-and-thumb toggle, for the handful of settings that are genuinely
// binary (Wi-Fi power) rather than a choice from a set (that's Chip). Also
// used non-interactively as a status indicator — `interactive: false` drops
// the hover/press feedback and the click, leaving only the position.
Rectangle {
    id: root

    property bool checked: false
    property bool interactive: true

    signal toggled(bool checked)

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    color: root.checked ? Theme.success : Theme.backgroundStrong
    border.color: Theme.primary
    border.width: 1
    opacity: root.interactive ? 1 : 0.6

    Rectangle {
        width: parent.height - 6
        height: parent.height - 6
        radius: width / 2
        x: root.checked ? parent.width - width - 3 : 3
        y: 3
        color: Theme.foreground
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
