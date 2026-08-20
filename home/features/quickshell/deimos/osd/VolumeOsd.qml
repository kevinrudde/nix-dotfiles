import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.widgets

// Volume feedback, shown for a moment after any change to the default sink —
// including changes made by keybinds outside the shell.
PanelWindow {
    id: root

    implicitWidth: 360
    implicitHeight: 58
    color: "transparent"
    // Floats over windows and takes no space from them.
    exclusiveZone: 0
    aboveWindows: true

    anchors.top: true
    margins.top: 56

    surfaceFormat {
        opaque: false
    }

    // Empty input region: the OSD is feedback, not a control, and must not
    // swallow clicks meant for whatever is underneath.
    mask: Region {}

    Rectangle {
        anchors.fill: parent
        color: Theme.backgroundStrong
        border.color: Theme.primary
        border.width: 1
        radius: Theme.popupRadius

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 14
            spacing: 10

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: Audio.sinkIcon
                color: Audio.sinkMuted ? Theme.muted : Theme.primary
                font.pixelSize: Theme.fontSizeDisplay
            }

            ProgressBar {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 8
                percent: Audio.sinkPercent
                fillColor: Audio.sinkMuted ? Theme.muted : Theme.primary
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                width: 56
                text: Audio.sinkMuted ? "muted" : Audio.sinkPercent + "%"
                color: Audio.sinkMuted ? Theme.muted : Theme.foreground
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeNormal
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
