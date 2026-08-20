import QtQuick
import qs
import qs.popups
import qs.services
import qs.widgets

// Bell with the number of pending notifications. Right click toggles do not
// disturb, which also drops the toasts currently on screen.
Pill {
    id: root

    required property var barScreen
    // The centre hangs off the corner of the bar, not off this pill.
    required property Item centreAnchor

    text: NotificationService.label
    fontSize: Theme.fontSizeIcon
    foreground: NotificationService.dnd ? Theme.muted : Theme.primary
    horizontalPadding: Theme.pillPadIcon
    maxTextWidth: 52
    tooltip: NotificationService.dnd
        ? "Do not disturb"
        : NotificationService.count + (NotificationService.count === 1 ? " notification" : " notifications")

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            NotificationService.toggleDnd();
        else
            Popups.toggle("notifications", root.barScreen);
    }

    NotificationCenter {
        anchorItem: root.centreAnchor
        popupScreen: root.barScreen
    }
}
