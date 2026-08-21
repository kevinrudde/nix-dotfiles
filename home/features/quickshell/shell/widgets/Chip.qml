import QtQuick
import qs

// Selectable pill for one of a small set of mutually exclusive choices (power
// profile). Text only by design: a wrong guess at a glyph's codepoint shows as
// a blank box, and there is no good way to tell from inside QML whether one
// rendered — see Theme's icon comment.
Rectangle {
    id: root

    property string text: ""
    property bool selected: false
    property bool enabled: true

    signal clicked

    implicitHeight: Theme.rowHeight
    opacity: root.enabled ? 1 : 0.4
    color: root.selected ? Theme.activeBackground : (area.containsMouse ? Theme.hoverBackground : Theme.background)
    border.color: Theme.primary
    border.width: 1
    radius: Theme.rowRadius

    StyledText {
        anchors.centerIn: parent
        text: root.text
        color: root.selected ? Theme.foreground : Theme.primary
    }

    MouseArea {
        id: area

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
