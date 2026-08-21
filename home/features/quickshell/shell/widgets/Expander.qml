import QtQuick
import QtQuick.Layouts
import qs

// A summary row that reveals more detail below it on click. No animation —
// visibility changes outright, the same way `NotificationGroup` collapses and
// expands: `Column` skips invisible children on its own, so nothing has to
// resize by hand.
Column {
    id: root

    property bool expanded: false
    // Header content (an icon, a line of text, a hint) goes through `header`;
    // children declared directly under `Expander { ... }` are the detail rows
    // instead and only show once expanded.
    default property alias body: bodyColumn.data
    property alias header: headerRow.data

    spacing: Theme.popupSpacing

    Rectangle {
        width: parent.width
        implicitHeight: Theme.rowHeight
        color: toggleArea.containsMouse ? Theme.hoverBackground : "transparent"
        radius: Theme.rowRadius

        RowLayout {
            id: headerRow

            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 8
            spacing: 8
        }

        MouseArea {
            id: toggleArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    Column {
        id: bodyColumn

        width: parent.width
        visible: root.expanded
        spacing: 4
    }
}
