import QtQuick
import QtQuick.Layouts
import qs

// Label on the left, value on the right. The label is deliberately not bold so
// a column of these reads as data rather than as headings.
RowLayout {
    id: root

    property string label: ""
    property string value: ""
    property color valueColor: Theme.primary

    height: 20
    spacing: Theme.popupSpacing

    StyledText {
        Layout.fillWidth: true
        text: root.label
        color: Theme.muted
        font.bold: false
    }

    StyledText {
        text: root.value
        color: root.valueColor
    }
}
