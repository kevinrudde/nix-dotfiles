import QtQuick
import Quickshell
import qs
import qs.services

// Transparent overlay in the top right corner holding the live toasts. Hidden
// while the notification centre is open — the same notifications would be
// listed twice, once behind the other.
PanelWindow {
    id: root

    required property var modelData

    screen: root.modelData
    visible: Popups.name !== "notifications" && NotificationService.toasts.length > 0
    implicitWidth: Theme.toastWidth
    implicitHeight: Math.min(stack.implicitHeight, root.screen.height - 72)
    color: "transparent"
    // Toasts float over windows instead of shrinking the usable area.
    exclusiveZone: 0
    aboveWindows: true

    anchors {
        top: true
        right: true
    }

    margins {
        top: 8
        right: Theme.barMarginSide
    }

    surfaceFormat {
        opaque: false
    }

    Flickable {
        anchors.fill: parent
        contentHeight: stack.implicitHeight
        clip: true
        interactive: stack.implicitHeight > height

        Column {
            id: stack

            width: parent.width
            spacing: Theme.toastSpacing

            Repeater {
                model: NotificationService.toastModel

                NotificationCard {
                    required property var modelData

                    notification: modelData
                    onDismissed: notification => NotificationService.dismiss(notification)
                }
            }
        }
    }
}
