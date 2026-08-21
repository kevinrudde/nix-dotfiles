import QtQuick
import qs

// Unboxed container for a group of small items (workspaces, tray icons) that
// are not individually pill-shaped — on the flat bar this is purely a layout
// helper, not a visible chrome. Grows with its contents.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property int pad: 8
    property int minWidth: 0

    implicitWidth: Math.max(root.minWidth, row.implicitWidth + root.pad * 2)
    implicitHeight: Theme.pillHeight
    color: "transparent"

    data: [
        Row {
            id: row

            anchors.centerIn: parent
            spacing: 0
        }
    ]
}
