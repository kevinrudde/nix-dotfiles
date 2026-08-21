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

    // The panel every other popup gets from PopupSurface. Not PopupSurface
    // itself: that widget's Column doesn't scroll, and the list here has to.
    // So the background+border live on their own Rectangle behind a Flickable
    // instead of wrapping it.
    Rectangle {
        anchors.fill: parent
        color: Theme.backgroundStrong
        border.color: Theme.primary
        border.width: 1
        radius: Theme.notificationRadius
    }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: Theme.popupPad
        anchors.rightMargin: Theme.popupPad
        contentHeight: stack.implicitHeight
        clip: true
        interactive: stack.implicitHeight > height

        Column {
            id: stack

            width: parent.width
            spacing: Theme.toastSpacing

            // Top breathing room. A fixed-height spacer rather than a margin
            // on the Flickable: `root.body` reads this Column's implicit
            // height to size the popup window, so padding has to live inside
            // it to be counted at all.
            Item {
                width: 1
                height: Theme.popupPad
            }

            // ── Title bar: count, DND, close ────────────────────────────
            // No background or border of its own — it sits directly on the
            // panel, the way the screenshot's header does; only the search
            // field and the cards below get their own outline.
            RowLayout {
                width: parent.width
                spacing: 8

                StyledText {
                    text: "Notifications"
                    font.pixelSize: Theme.fontSizeLarge
                }

                StyledText {
                    Layout.fillWidth: true
                    text: NotificationService.count === 1 ? "1 notification" : NotificationService.count + " notifications"
                    color: Theme.muted
                    font.bold: false
                    font.pixelSize: Theme.fontSizeTiny
                    elide: Text.ElideRight
                }

                // A chip rather than the plain "DND on/off" label the
                // toggle used to be: it is the one control in the centre
                // that changes system behaviour rather than just the
                // view, so it gets its own outline to read as a switch.
                Rectangle {
                    id: dndChip

                    implicitWidth: dndRow.implicitWidth + 16
                    implicitHeight: 22
                    radius: implicitHeight / 2
                    color: NotificationService.dnd ? Theme.activeBackground : "transparent"
                    border.color: NotificationService.dnd ? Theme.primary : Theme.muted
                    border.width: 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    RowLayout {
                        id: dndRow

                        anchors.centerIn: parent
                        spacing: 5

                        StyledText {
                            text: NotificationService.dnd ? Theme.iconBellDnd : Theme.iconBell
                            color: NotificationService.dnd ? Theme.primary : Theme.muted
                            font.pixelSize: Theme.fontSizeTiny
                        }

                        StyledText {
                            text: NotificationService.dnd ? "DND on" : "DND off"
                            color: NotificationService.dnd ? Theme.primary : Theme.muted
                            font.pixelSize: Theme.fontSizeTiny
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.toggleDnd()
                    }
                }

                TextButton {
                    text: "×"
                    restColor: Theme.muted
                    font.pixelSize: Theme.fontSizeLarge
                    onClicked: Popups.close()
                }
            }

            // ── Search ───────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 30
                color: Theme.background
                border.color: searchInput.activeFocus ? Theme.primary : Theme.cardBorder
                border.width: 1
                radius: Theme.notificationRadius

                Behavior on border.color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                // The service is cleared whenever the centre closes (see
                // NotificationService's Connections on Popups); mirror that
                // into the field itself, since a severed text binding would
                // otherwise leave stale query text showing on reopen.
                Connections {
                    target: NotificationService

                    function onSearchQueryChanged(): void {
                        if (NotificationService.searchQuery === "")
                            searchInput.text = "";
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 6

                    StyledText {
                        text: Theme.iconSearch
                        color: Theme.muted
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text.length === 0
                            text: "Search notifications"
                            color: Theme.muted
                            font.bold: false
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        TextInput {
                            id: searchInput

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true
                            color: Theme.foreground
                            selectionColor: Theme.activeBackground
                            selectedTextColor: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall

                            onTextEdited: NotificationService.searchQuery = text
                            Keys.onEscapePressed: text = ""
                        }
                    }

                    TextButton {
                        visible: searchInput.text.length > 0
                        text: "×"
                        restColor: Theme.muted
                        font.pixelSize: Theme.fontSizeNormal
                        onClicked: searchInput.text = ""
                    }
                }
            }

            // ── Section label + bulk clear ──────────────────────────────
            RowLayout {
                width: parent.width
                spacing: Theme.popupSpacing

                StyledText {
                    Layout.fillWidth: true
                    text: "Recent and live notifications"
                    color: Theme.muted
                    font.bold: false
                    font.pixelSize: Theme.fontSizeTiny
                    elide: Text.ElideRight
                }

                TextButton {
                    visible: NotificationService.count > 0
                    text: "Clear all"
                    font.pixelSize: Theme.fontSizeTiny
                    onClicked: NotificationService.clear()
                }
            }

            Rectangle {
                width: parent.width
                height: 52
                visible: NotificationService.groups.length === 0
                color: Theme.background
                border.color: Theme.primary
                border.width: 1
                radius: Theme.notificationRadius

                EmptyHint {
                    anchors.centerIn: parent
                    text: NotificationService.searchQuery !== "" ? "No matches for “" + NotificationService.searchQuery + "”" : "No notifications"
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

            StyledText {
                width: parent.width
                visible: NotificationService.groups.length > 0
                text: "Left-click a notification, or hover the × to dismiss  ·  Esc closes"
                color: Theme.muted
                font.bold: false
                font.pixelSize: Theme.fontSizeTiny
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            // Bottom breathing room — see the matching spacer above.
            Item {
                width: 1
                height: Theme.popupPad
            }
        }
    }
}
