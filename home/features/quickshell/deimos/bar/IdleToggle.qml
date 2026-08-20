import qs
import qs.services
import qs.widgets

// Holds off the idle daemon. Only offered in the expanded bar: it is a rare
// action and an easy one to hit by accident.
Pill {
    visible: BarState.expanded
    text: BarState.idleInhibited ? Theme.iconIdleOn : Theme.iconIdleOff
    horizontalPadding: Theme.pillPadIcon
    tooltip: BarState.idleInhibited ? "Idle inhibited" : "Inhibit idle"
    onClicked: BarState.idleInhibited = !BarState.idleInhibited
}
