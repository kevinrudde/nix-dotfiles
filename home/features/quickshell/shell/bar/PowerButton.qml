import qs
import qs.services
import qs.widgets

// Opens the power menu. Confirmation for the destructive entries happens there,
// not here.
Pill {
    text: Theme.iconPower
    fontSize: Theme.fontSizeIcon
    foreground: Theme.danger
    horizontalPadding: Theme.pillPadIcon
    tooltip: "Power menu"
    onClicked: Actions.powerMenu()
}
