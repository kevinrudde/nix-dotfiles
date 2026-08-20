import QtQuick
import Quickshell.Hyprland
import qs
import qs.widgets

// Hyprland's workspaces, as they exist right now: Hyprland does not keep empty
// ones around, so this list grows and shrinks on its own.
Island {
    id: root

    pad: 4

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: entry

            required property var modelData

            // `active` is the workspace shown on its monitor, `focused` the one
            // that has the keyboard — on a single monitor they agree.
            readonly property bool current: entry.modelData.active || entry.modelData.focused

            width: Math.max(28, label.implicitWidth + 14)
            height: 24
            color: entry.current ? Theme.activeBackground : "transparent"
            radius: Theme.rowRadius

            StyledText {
                id: label

                anchors.centerIn: parent
                text: entry.modelData.name
                color: entry.current ? Theme.primary : Theme.muted
                font.pixelSize: Theme.fontSizeLarge
            }

            MouseArea {
                anchors.fill: parent
                onClicked: entry.modelData.activate()
            }
        }
    }
}
