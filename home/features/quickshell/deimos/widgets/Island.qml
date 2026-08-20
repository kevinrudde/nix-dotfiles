import QtQuick
import qs

// Bordered container for a group of small items (workspaces, tray icons) that
// are not individually pill-shaped. Grows with its contents.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property int pad: 8
    property int minWidth: Theme.pillHeight

    implicitWidth: Math.max(root.minWidth, row.implicitWidth + root.pad * 2)
    implicitHeight: Theme.pillHeight
    color: Theme.background
    border.color: Theme.primary
    border.width: 1
    radius: Theme.pillRadius

    data: [
        Row {
            id: row

            anchors.centerIn: parent
            spacing: 0
        }
    ]
}
