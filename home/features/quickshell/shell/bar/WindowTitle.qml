import Quickshell.Hyprland
import qs
import qs.widgets

// Title of the focused window, centred in the bar. The width it may take is
// decided by the bar, which knows how much room the two groups beside it left.
Pill {
    id: root

    // Space between the left and right groups.
    property int availableWidth: 0

    text: Hyprland.activeToplevel && Hyprland.activeToplevel.title ? Hyprland.activeToplevel.title : "Desktop"
    foreground: Theme.foreground
    horizontalPadding: 14
    // No minimum: on a narrow screen the title gives way entirely rather than
    // overlapping its neighbours.
    minPillWidth: 0
    maxTextWidth: Math.max(0, Math.min(520, root.availableWidth))
}
