import QtQuick
import QtQuick.Layouts
import qs

// One resource line inside a popup: icon, label, a value on the right, and a
// thin fill bar underneath.
ColumnLayout {
    id: root

    property string icon: ""
    property string label: ""
    property string detail: ""
    property int percent: 0
    property color barColor: Theme.primary

    spacing: 5

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        StyledText {
            text: root.icon
            color: root.barColor
            font.pixelSize: Theme.fontSizeNormal
        }

        StyledText {
            Layout.fillWidth: true
            text: root.label
            color: Theme.muted
            font.bold: false
            elide: Text.ElideRight
        }

        StyledText {
            text: root.detail
        }
    }

    ProgressBar {
        Layout.fillWidth: true
        Layout.preferredHeight: 5
        percent: root.percent
        fillColor: root.barColor
    }
}
