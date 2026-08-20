import QtQuick
import QtQuick.Layouts
import qs

// Title row at the top of a popup. Extra children land to the right of the
// title and keep their natural width.
RowLayout {
    id: root

    property string title: ""

    height: 26
    spacing: Theme.popupSpacing

    StyledText {
        Layout.fillWidth: true
        text: root.title
        elide: Text.ElideRight
        font.pixelSize: Theme.fontSizeNormal
    }
}
