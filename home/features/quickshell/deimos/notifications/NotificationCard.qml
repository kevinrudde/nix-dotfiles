import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs
import qs.widgets

// One notification: app name, summary, body and its actions. Used both as a
// toast and inside the notification centre; `expanded` only decides how much of
// the body is shown.
Rectangle {
    id: card

    required property var notification
    // The centre has room to show more lines than a toast does.
    property bool expanded: false

    readonly property bool critical: !!(card.notification && card.notification.urgency === NotificationUrgency.Critical)

    signal dismissed(var notification)
    signal clicked(var notification)

    // The action a click on the card body triggers, if the sender offered one.
    // Freedesktop names it "default"; some senders instead ship a single
    // action with no label, which amounts to the same thing.
    readonly property var defaultAction: {
        const actions = card.notification ? card.notification.actions : null;
        if (!actions)
            return null;

        for (const action of actions) {
            if (action.identifier === "default")
                return action;
        }

        for (const action of actions) {
            if (card.actionText(action) === "")
                return action;
        }

        return null;
    }

    function actionText(action: var): string {
        if (!action || !action.text)
            return "";

        return String(action.text).trim();
    }

    function hasVisibleActions(actions: var): bool {
        if (!actions)
            return false;

        for (const action of actions) {
            if (card.actionText(action) !== "")
                return true;
        }

        return false;
    }

    function invokeDefaultAction(): void {
        if (!card.defaultAction)
            return;

        card.defaultAction.invoke();
        card.dismissed(card.notification);
    }

    implicitWidth: Theme.toastWidth
    implicitHeight: content.implicitHeight + 16
    color: card.critical ? Theme.criticalBackground : Theme.background
    border.color: card.critical ? Theme.danger : Theme.cardBorder
    border.width: 1
    radius: Theme.popupRadius

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: card.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                card.dismissed(card.notification);
                return;
            }

            if (card.defaultAction)
                card.invokeDefaultAction();
            else
                card.clicked(card.notification);
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 8
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.popupSpacing

            StyledText {
                Layout.fillWidth: true
                text: card.notification ? (card.notification.appName || "Notification") : "Notification"
                color: Theme.muted
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeTiny
                opacity: 0.86
            }

            StyledText {
                visible: card.critical
                text: "critical"
                color: Theme.danger
                font.pixelSize: Theme.fontSizeTiny
            }

            TextButton {
                text: "x"
                restColor: Theme.muted
                font.pixelSize: Theme.fontSizeNormal
                onClicked: card.dismissed(card.notification)
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: card.notification ? card.notification.summary : ""
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeLarge
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: card.notification ? card.notification.body : ""
            elide: Text.ElideRight
            font.bold: false
            font.pixelSize: Theme.fontSizeNormal
            maximumLineCount: card.expanded ? 6 : 3
            opacity: 0.84
            wrapMode: Text.Wrap
        }

        Row {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? implicitHeight : 0
            visible: card.notification && card.hasVisibleActions(card.notification.actions)
            spacing: 6

            Repeater {
                model: card.notification ? card.notification.actions : []

                Rectangle {
                    id: actionButton

                    required property var modelData

                    // Unlabelled actions are the default action, which the card
                    // body already triggers.
                    readonly property string label: card.actionText(actionButton.modelData)

                    visible: actionButton.label !== ""
                    implicitWidth: actionButton.visible ? actionLabel.implicitWidth + 16 : 0
                    implicitHeight: actionButton.visible ? 22 : 0
                    color: actionArea.containsMouse ? Theme.hoverBackground : Theme.backgroundStrong
                    border.color: Theme.primary
                    border.width: 1
                    radius: Theme.rowRadius

                    StyledText {
                        id: actionLabel

                        anchors.centerIn: parent
                        text: actionButton.label
                        color: Theme.primary
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSizeTiny
                    }

                    MouseArea {
                        id: actionArea

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            actionButton.modelData.invoke();
                            card.dismissed(card.notification);
                        }
                    }
                }
            }
        }
    }
}
