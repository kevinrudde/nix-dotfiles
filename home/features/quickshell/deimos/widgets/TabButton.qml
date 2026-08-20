import QtQuick
import qs

// One half of a two-way switch, as used for the audio popup's output/input
// tabs.
Rectangle {
    id: root

    property string text: ""
    property bool active: false

    signal clicked

    implicitHeight: Theme.rowHeight
    color: root.active ? Theme.activeBackground : Theme.background
    border.color: Theme.primary
    border.width: 1
    radius: Theme.rowRadius

    StyledText {
        anchors.centerIn: parent
        text: root.text
        color: root.active ? Theme.foreground : Theme.primary
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
