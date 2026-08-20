import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.notifications
import qs.services
import qs.widgets

// The full notification history, grouped per application. Anchored to the top
// right corner of the bar rather than to the bell, so it lines up with the
// toasts it replaces.
BarPopup {
    id: root

    popupName: "notifications"
    surfaceWidth: Theme.toastWidth
    body: stack
    // Leave the bar and a margin visible; beyond that the list scrolls.
    maxHeight: root.popupScreen ? Math.max(0, root.popupScreen.height - 72) : 0

    anchorEdges: Edges.Top | Edges.Right
    anchorGravity: Edges.Top | Edges.Right
    anchorMarginTop: 50

    Flickable {
        anchors.fill: parent
        contentHeight: stack.implicitHeight
        clip: true
        interactive: stack.implicitHeight > height

        Column {
            id: stack

            width: parent.width
            spacing: Theme.toastSpacing

            Rectangle {
                width: parent.width
                height: Theme.rowHeight
                color: Theme.backgroundStrong
                border.color: Theme.primary
                border.width: 1
                radius: Theme.popupRadius

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 7

                    StyledText {
                        Layout.fillWidth: true
                        text: NotificationService.count === 1 ? "1 notification" : NotificationService.count + " notifications"
                        elide: Text.ElideRight
                    }

                    TextButton {
                        text: NotificationService.dnd ? "DND on" : "DND off"
                        restColor: NotificationService.dnd ? Theme.muted : Theme.primary
                        onClicked: NotificationService.toggleDnd()
                    }

                    TextButton {
                        visible: NotificationService.count > 0
                        text: "clear"
                        onClicked: NotificationService.clear()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 52
                visible: NotificationService.count === 0
                color: Theme.background
                border.color: Theme.primary
                border.width: 1
                radius: Theme.popupRadius

                EmptyHint {
                    anchors.centerIn: parent
                    text: "No notifications"
                    font.pixelSize: Theme.fontSizeNormal
                }
            }

            Repeater {
                model: NotificationService.groups

                NotificationGroup {
                    required property var modelData

                    width: stack.width
                    group: modelData
                }
            }
        }
    }
}
