import qs
import qs.services
import qs.widgets

// Opens the application launcher.
Pill {
    text: Theme.iconLauncher
    fontSize: Theme.fontSizeIcon
    horizontalPadding: Theme.pillPadIcon
    onClicked: Actions.launcher()
}
