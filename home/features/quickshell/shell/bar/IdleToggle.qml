import qs
import qs.services
import qs.widgets

// Holds off dim, lock, screen-off and suspend. Only offered in the expanded bar: it is a rare
// action and an easy one to hit by accident.
Pill {
    visible: BarState.expanded
    text: BarState.sleepInhibited ? Theme.iconIdleOn : Theme.iconIdleOff
    fontSize: Theme.fontSizeIcon
    horizontalPadding: Theme.pillPadIcon
    tooltip: BarState.sleepInhibited ? "Idle inhibited" : "Inhibit idle"
    onClicked: BarState.sleepInhibited = !BarState.sleepInhibited
}
