import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.widgets

// Bluetooth and network behind one pair of tabs rather than two popups: both
// are "which device am I talking to" questions, and neither needs its own
// pill to make that decision from. Bluetooth leads because it sees far more
// day-to-day use than switching networks does.
BarPopup {
    id: root

    // Which tab is showing. Local rather than a service property: nothing
    // outside this popup instance needs to read or drive it.
    property string mode: "bluetooth"

    popupName: "connectivity"
    body: surface

    PopupSurface {
        id: surface

        surfaceWidth: 380

        Row {
            width: parent.width
            height: Theme.rowHeight
            spacing: 6

            TabButton {
                width: (parent.width - parent.spacing) / 2
                text: "Bluetooth"
                active: root.mode === "bluetooth"
                onClicked: root.mode = "bluetooth"
            }

            TabButton {
                width: (parent.width - parent.spacing) / 2
                text: "Network"
                active: root.mode === "network"
                onClicked: root.mode = "network"
            }
        }

        // ── Bluetooth ────────────────────────────────────────────────────
        Column {
            width: parent.width
            visible: root.mode === "bluetooth"
            spacing: Theme.popupSpacing

            SectionHeader {
                width: parent.width
                title: ""

                TextButton {
                    text: BluetoothInfo.powered ? "on" : "off"
                    restColor: BluetoothInfo.powered ? Theme.primary : Theme.muted
                    onClicked: BluetoothInfo.togglePower()
                }

                TextButton {
                    visible: BluetoothInfo.powered
                    text: BluetoothInfo.discovering ? "busy" : "scan"
                    interactive: !BluetoothInfo.discovering
                    onClicked: BluetoothInfo.setScanning(true)
                }
            }

            EmptyHint {
                width: parent.width
                visible: !BluetoothInfo.powered || BluetoothInfo.devices.length === 0
                text: BluetoothInfo.powered ? "No Bluetooth devices" : "Bluetooth disabled"
            }

            Repeater {
                // Capped: a scan in a busy room finds far more than fits.
                model: BluetoothInfo.powered ? BluetoothInfo.devices.slice(0, 10) : []

                ListRow {
                    required property var modelData

                    readonly property bool connected: modelData.connected
                    readonly property bool usable: BluetoothInfo.powered && !BluetoothInfo.busy(modelData) && !modelData.blocked

                    width: parent.width
                    minHeight: 38
                    icon: connected ? Theme.iconCheck : BluetoothInfo.deviceIcon(modelData)
                    iconColor: connected ? Theme.success : (usable ? Theme.primary : Theme.muted)
                    title: BluetoothInfo.deviceName(modelData)
                    titleColor: connected ? Theme.foreground : (usable ? Theme.primary : Theme.muted)
                    detail: BluetoothInfo.detail(modelData)
                    trailing: BluetoothInfo.actionText(modelData)
                    trailingColor: usable ? Theme.primary : Theme.muted
                    active: connected
                    interactive: usable
                    onActivated: BluetoothInfo.activate(modelData)
                }
            }
        }
        // ── Network ──────────────────────────────────────────────────────
        Column {
            width: parent.width
            visible: root.mode === "network"
            spacing: Theme.popupSpacing

            SectionHeader {
                width: parent.width
                title: ""

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
                // Capped: the list is sorted by signal, and everything past
                // this is too weak to be worth a click.
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
}
