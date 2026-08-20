pragma Singleton

// Active Hyprland submap. Hyprland only reports it as a raw event, so it has to
// be tracked rather than read.
import Quickshell
import QtQuick
import Quickshell.Hyprland

Singleton {
    id: root

    // Empty while the default submap is active.
    property string name: ""

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name === "submap")
                root.name = event.data === "default" ? "" : event.data;
        }
    }
}
