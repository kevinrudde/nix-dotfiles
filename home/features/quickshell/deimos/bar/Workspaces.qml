import QtQuick
import Quickshell.Hyprland
import qs
import qs.widgets

// Hyprland's workspaces, as they exist right now: Hyprland does not keep empty
// ones around, so this list grows and shrinks on its own. Plain numbers
// directly on the bar, not boxed pills — the current one is what carries the
// colour, not a background fill behind it.
//
// Filtered to the bar's own monitor. `Hyprland.workspaces` is global, so an
// unfiltered list puts every screen's workspaces on every bar and lights up one
// as current per screen — two highlighted numbers on a two-monitor desk, one of
// which is not even on the screen you are looking at.
Row {
    id: root

    // The monitor this bar belongs to.
    required property var screen

    readonly property string screenName: root.screen ? root.screen.name : ""
    // Sorted by id rather than left in the order Hyprland hands them over,
    // which is whatever it last touched — close enough to sorted most of the
    // time to hide the difference, and jarring the one time it is not.
    readonly property var entries: Hyprland.workspaces.values.filter(workspace => workspace && workspace.monitor && workspace.monitor.name === root.screenName).sort((left, right) => left.id - right.id)

    spacing: 10

    Repeater {
        model: root.entries

        StyledText {
            id: entry

            required property var modelData

            // `active` alone, not `active || focused`: focus is a property of
            // the desk as a whole, so on the unfocused monitor's bar it would
            // light up nothing, and the list is already narrowed to workspaces
            // this screen owns.
            readonly property bool current: entry.modelData.active

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
