import qs
import qs.services
import qs.widgets

// Reveals the overflow icons (the system tray, the idle-inhibit toggle) —
// the flat bar's own icons are always visible and never behind this.
// Shared across monitors so both bars stay in the same shape.
Pill {
    text: BarState.expanded ? ">" : "<"
    horizontalPadding: Theme.pillPadIcon
    maxTextWidth: 14
    tooltip: BarState.expanded ? "Hide tray" : "Show tray"
    onClicked: BarState.expanded = !BarState.expanded
}
