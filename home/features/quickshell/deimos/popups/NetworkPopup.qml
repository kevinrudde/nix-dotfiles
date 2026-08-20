import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.widgets

// Wired links on top, then Wi-Fi networks. A secured network that has no saved
// connection expands into a password prompt on first click instead of opening
// an external dialog.
BarPopup {
    id: root

    popupName: "network"
    body: surface

    PopupSurface {
        id: surface

        surfaceWidth: 380

        SectionHeader {
            width: parent.width
            title: "Network"

            StyledText {
                text: NetworkInfo.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
                color: NetworkInfo.wifiEnabled ? Theme.primary : Theme.muted
            }

            TextButton {
                text: "scan"
                onClicked: NetworkInfo.refresh(true)
            }
        }

        Rectangle {
            width: parent.width
            height: Math.max(34, wiredColumn.implicitHeight + 12)
            visible: NetworkInfo.wired.length > 0
            color: Theme.background
            border.color: Theme.primary
            border.width: 1
            radius: Theme.rowRadius

            Column {
                id: wiredColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 3

                Repeater {
                    model: NetworkInfo.wired

                    RowLayout {
                        required property var modelData

                        width: wiredColumn.width
                        spacing: Theme.popupSpacing

                        StyledText {
                            text: Theme.iconEthernet
                            color: modelData.connected ? Theme.success : Theme.muted
                            font.pixelSize: Theme.fontSizeNormal
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.connection || modelData.device
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: modelData.connected ? "connected" : modelData.state
                            color: modelData.connected ? Theme.success : Theme.muted
                            font.bold: false
                            font.pixelSize: Theme.fontSizeTiny
                        }
                    }
                }
            }
        }

        EmptyHint {
            width: parent.width
            visible: NetworkInfo.wifi.length === 0
            text: NetworkInfo.wifiEnabled ? "No Wi-Fi networks" : "Wi-Fi disabled"
        }

        Repeater {
            // Capped: the list is sorted by signal, and everything past this is
            // too weak to be worth a click.
            model: NetworkInfo.wifi.slice(0, 10)

            ListRow {
                id: networkRow

                required property var modelData

                readonly property bool connectable: NetworkInfo.canConnect(modelData)

                width: parent.width
                icon: modelData.active ? Theme.iconCheck : NetworkInfo.signalIcon(modelData.signal)
                iconColor: modelData.active ? Theme.success : (connectable ? Theme.primary : Theme.muted)
                title: modelData.ssid
                titleColor: modelData.active ? Theme.foreground : (connectable ? Theme.primary : Theme.muted)
                detail: NetworkInfo.detail(modelData)
                active: modelData.active
                footerOpen: NetworkInfo.passwordSsid === modelData.ssid && NetworkInfo.needsPassword(modelData)
                onActivated: NetworkInfo.connect(modelData, "")

                onFooterOpenChanged: {
                    if (networkRow.footerOpen) {
                        passwordInput.text = "";
                        passwordInput.forceActiveFocus();
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: joinButton.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    height: 26
                    color: Theme.background
                    border.color: passwordInput.activeFocus ? Theme.primary : Theme.muted
                    border.width: 1
                    radius: 6

                    TextInput {
                        id: passwordInput

                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        clip: true
                        color: Theme.foreground
                        selectionColor: Theme.activeBackground
                        selectedTextColor: Theme.foreground
                        echoMode: TextInput.Password
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        verticalAlignment: TextInput.AlignVCenter

                        onAccepted: NetworkInfo.connect(networkRow.modelData, text)
                        Keys.onEscapePressed: NetworkInfo.passwordSsid = ""
                    }
                }

                Rectangle {
                    id: joinButton

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 60
                    height: 26
                    color: joinArea.containsMouse ? Theme.activeBackground : Theme.background
                    border.color: Theme.primary
                    border.width: 1
                    radius: 6

                    StyledText {
                        anchors.centerIn: parent
                        text: "join"
                        font.pixelSize: Theme.fontSizeTiny
                    }

                    MouseArea {
                        id: joinArea

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: NetworkInfo.connect(networkRow.modelData, passwordInput.text)
                    }
                }
            }
        }
    }
}
