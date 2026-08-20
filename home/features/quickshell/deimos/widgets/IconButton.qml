import QtQuick
import qs

// Round icon-only button for an on/off action inside a popup (mute, a
// brightness preset). Not a Pill: it has no text to size around.
Rectangle {
    id: root

    property string icon: ""
    property color iconColor: Theme.primary
    property int size: 28

    signal clicked

    implicitWidth: root.size
    implicitHeight: root.size
    radius: root.size / 2
    color: area.containsMouse ? Theme.hoverBackground : Theme.background
    border.color: Theme.primary
    border.width: 1

    StyledText {
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: Theme.fontSizeLarge
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
