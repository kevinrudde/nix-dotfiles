import QtQuick
import Quickshell.Hyprland
import qs
import qs.widgets

// Hyprland's workspaces, as they exist right now: Hyprland does not keep
// empty ones around, so this list grows and shrinks on its own. Plain
// numbers directly on the bar, not boxed pills — the current one is what
// carries the colour, not a background fill behind it.
Row {
    id: root

    spacing: 10

    Repeater {
        model: Hyprland.workspaces

        StyledText {
            id: entry

            required property var modelData

            // `active` is the workspace shown on its monitor, `focused` the
            // one that has the keyboard — on a single monitor they agree.
            readonly property bool current: entry.modelData.active || entry.modelData.focused

            text: entry.modelData.name
            color: entry.current ? Theme.primary : (area.containsMouse ? Theme.foreground : Theme.muted)
            font.pixelSize: Theme.fontSizeLarge
            font.bold: entry.current

            MouseArea {
                id: area

                anchors.fill: parent
                anchors.margins: -5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: entry.modelData.activate()
            }
        }
    }
}
