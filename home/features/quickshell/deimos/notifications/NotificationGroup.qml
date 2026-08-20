import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.widgets

// All notifications of one application. A group of two or more collapses into a
// single card showing the most recent one; expanding it adds a header and lists
// every card.
Column {
    id: root

    required property var group

    readonly property var latest: root.group.notifications.length > 0 ? root.group.notifications[0] : null
    readonly property bool expandable: root.group.notifications.length > 1
    readonly property bool expanded: NotificationService.groupExpanded(root.group.key)
    readonly property color accent: root.group.critical ? Theme.danger : Theme.primary

    spacing: 5

    Rectangle {
        width: parent.width
        height: Theme.rowHeight
        visible: root.expanded
        color: Theme.activeBackground
        border.color: root.accent
        border.width: 1
        radius: Theme.popupRadius

        MouseArea {
            id: headerArea

            anchors.fill: parent
            enabled: root.expandable
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: NotificationService.toggleGroup(root.group)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: Theme.popupSpacing

            StyledText {
                Layout.fillWidth: true
                text: root.group.appName
                elide: Text.ElideRight
            }

            StyledText {
                text: root.group.notifications.length === 1 ? "1 item" : root.group.notifications.length + " items"
                color: root.group.critical ? Theme.danger : Theme.muted
                font.pixelSize: Theme.fontSizeTiny
            }

            StyledText {
                text: root.expanded ? "collapse" : "expand"
                color: headerArea.containsMouse ? Theme.foreground : Theme.primary
                font.pixelSize: Theme.fontSizeTiny
            }

            TextButton {
                text: "clear"
                font.pixelSize: Theme.fontSizeTiny
                onClicked: NotificationService.dismissGroup(root.group)
            }
        }
    }

    Rectangle {
        width: parent.width
        visible: root.expandable && !root.expanded
        height: visible ? Math.max(74, collapsedContent.implicitHeight + 18) : 0
        color: Theme.background
        border.color: root.accent
        border.width: 1
        radius: Theme.popupRadius

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    NotificationService.dismissGroup(root.group);
                else
                    NotificationService.toggleGroup(root.group);
            }
        }

        ColumnLayout {
            id: collapsedContent

            anchors.fill: parent
            anchors.margins: 9
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.popupSpacing

                StyledText {
                    Layout.fillWidth: true
                    text: root.group.appName
                    color: Theme.muted
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeTiny
                }

                StyledText {
                    text: root.group.notifications.length + " grouped"
                    color: root.accent
                    font.pixelSize: Theme.fontSizeTiny
                }

                TextButton {
                    text: "clear"
                    font.pixelSize: Theme.fontSizeTiny
                    onClicked: NotificationService.dismissGroup(root.group)
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.latest ? root.latest.summary : ""
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeLarge
                maximumLineCount: 1
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.latest ? root.latest.body : ""
                elide: Text.ElideRight
                font.bold: false
                font.pixelSize: Theme.fontSizeNormal
                maximumLineCount: 2
                opacity: 0.84
                wrapMode: Text.Wrap
            }
        }
    }

    Repeater {
        // A single notification never collapses — there would be nothing to
        // expand into.
        model: root.expanded || !root.expandable ? root.group.notifications : []

        NotificationCard {
            required property var modelData

            width: root.width
            height: implicitHeight
            notification: modelData
            expanded: true
            onDismissed: notification => NotificationService.dismiss(notification)
        }
    }
}
