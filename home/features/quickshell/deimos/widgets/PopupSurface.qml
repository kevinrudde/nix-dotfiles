import QtQuick
import qs

// The body of a popup: bordered panel with a padded column. Children are placed
// in that column and can use `parent.width` for the content width.
Rectangle {
    id: root

    default property alias content: column.data
    property alias spacing: column.spacing
    property int surfaceWidth: 360

    implicitWidth: root.surfaceWidth
    implicitHeight: column.implicitHeight + Theme.popupPad * 2
    color: Theme.backgroundStrong
    border.color: Theme.primary
    border.width: 1
    radius: Theme.popupRadius

    data: [
        Column {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.popupPad
            spacing: Theme.popupSpacing
        }
    ]
}
