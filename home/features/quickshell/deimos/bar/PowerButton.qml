import qs
import qs.services
import qs.widgets

// Opens the power menu. Confirmation for the destructive entries happens there,
// not here.
Pill {
    visible: BarState.expanded
    text: Theme.iconPower
    foreground: Theme.danger
    horizontalPadding: Theme.pillPadIcon
    onClicked: Actions.powerMenu()
}
