import QtQuick
import qs
import qs.popups
import qs.services
import qs.widgets

// Bell with the number of pending notifications riding on its corner. Right
// click toggles do not disturb, which also drops the toasts currently on
// screen. See BadgedIcon.qml for why the count sits on the glyph instead of
// beside it.
Pill {
    id: root

    required property var barScreen
    // The centre hangs off the corner of the bar, not off this pill.
    required property Item centreAnchor

    readonly property color tint: NotificationService.dnd ? Theme.muted : Theme.primary

    text: ""
    horizontalPadding: Theme.pillPadIcon
    minPillWidth: 0
    implicitWidth: bell.implicitWidth + root.horizontalPadding * 2
    tooltip: NotificationService.dnd
        ? "Do not disturb"
        : NotificationService.count + (NotificationService.count === 1 ? " notification" : " notifications")

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            NotificationService.toggleDnd();
        else
            Popups.toggle("notifications", root.barScreen);
    }

    BadgedIcon {
        id: bell

        anchors.centerIn: parent
        icon: NotificationService.icon
        count: NotificationService.count
        color: root.tint
        surface: root.hovered ? Theme.barHoverSolid : Theme.barBackground
    }

    NotificationCenter {
        anchorItem: root.centreAnchor
        popupScreen: root.barScreen
    }
}
