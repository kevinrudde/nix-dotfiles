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

    // One WifiStats singleton is shared by a popup instance per monitor, so
    // this has to be imperative rather than a continuous binding: two
    // instances both binding `WifiStats.watching` to their own `open`/`mode`
    // would fight over the same property. Popups.qml only ever lets one
    // instance be open at a time, so only the instance whose own state just
    // changed ever writes here — the other, closed, instance has nothing to
    // change and stays silent.
    onOpenChanged: WifiStats.watching = root.open && root.mode === "network"
    onModeChanged: WifiStats.watching = root.open && root.mode === "network"

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
            id: networkPane

            width: parent.width
            visible: root.mode === "network"
            spacing: Theme.popupSpacing

            // Whether the custom-DNS field is showing. Separate from
            // `WifiStats.dnsProvider === "custom"` so clicking the chip opens
            // the field immediately rather than waiting on the reconnect that
            // confirms the change actually took.
            property bool dnsCustomOpen: false
            property var knownNetworks: NetworkInfo.wifi.filter(entry => entry.known)
            // Capped: the list is sorted by signal, and everything past this
            // is too weak to be worth a click.
            property var otherNetworks: NetworkInfo.wifi.filter(entry => !entry.known).slice(0, 10)

            RowLayout {
                width: parent.width
                spacing: 10

                StyledText {
                    text: WifiStats.connected ? NetworkInfo.signalIcon((NetworkInfo.activeEntry() || {}).signal || 0) : Theme.iconWifi0
                    color: NetworkInfo.wifiEnabled ? (WifiStats.connected ? Theme.primary : Theme.muted) : Theme.muted
                    font.pixelSize: Theme.fontSizeDisplay
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    StyledText {
                        Layout.fillWidth: true
                        text: WifiStats.connected ? NetworkInfo.activeWifi : (NetworkInfo.wifiEnabled ? "Not connected" : "Wi-Fi off")
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: WifiStats.connected ? "connected" : (NetworkInfo.wifiEnabled ? "searching" : "off")
                        color: Theme.muted
                        font.bold: false
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }

                Switch {
                    checked: NetworkInfo.wifiEnabled
                    onToggled: checked => NetworkInfo.setWifiPower(checked)
                }
            }

            GridLayout {
                width: parent.width
                visible: WifiStats.connected
                columns: 2
                columnSpacing: 16
                rowSpacing: 2

                InfoRow {
                    Layout.fillWidth: true
                    // "(DNS)" once a resolver is actually known — otherwise
                    // this is still the gateway fallback, same as before.
                    label: WifiStats.pingTarget !== "" && WifiStats.pingTarget !== WifiStats.gateway ? "Ping (DNS)" : "Ping"
                    value: WifiStats.pingMs !== null ? Math.round(WifiStats.pingMs) + " ms" : "--"
                }

                InfoRow {
                    Layout.fillWidth: true
                    label: "Packet loss"
                    value: WifiStats.packetLoss !== null ? WifiStats.packetLoss + "%" : "--"
                }

                InfoRow {
                    Layout.fillWidth: true
                    label: "Receiving"
                    value: WifiStats.rateText(WifiStats.rxRate)
                }

                InfoRow {
                    Layout.fillWidth: true
                    label: "Sending"
                    value: WifiStats.rateText(WifiStats.txRate)
                }

                InfoRow {
                    Layout.fillWidth: true
                    label: "Downloaded"
                    value: WifiStats.byteUnits(WifiStats.rawRx)
                }

                InfoRow {
                    Layout.fillWidth: true
                    label: "Uploaded"
                    value: WifiStats.byteUnits(WifiStats.rawTx)
                }

                InfoRow {
                    Layout.fillWidth: true
                    label: "IP address"
                    value: WifiStats.ip
                }

                InfoRow {
                    Layout.fillWidth: true
                    label: "Gateway"
                    value: WifiStats.gateway
                }
            }

            Divider {
                visible: WifiStats.connected
            }

            StyledText {
                width: parent.width
                visible: WifiStats.connected && WifiStats.band !== ""
                text: "Wi-Fi band: " + WifiStats.band
                color: Theme.muted
                font.bold: false
            }

            Divider {
                visible: WifiStats.connected
            }

            Column {
                width: parent.width
                visible: WifiStats.connected
                spacing: Theme.popupSpacing

                Caption {
                    width: parent.width
                    label: "DNS provider"
                }

                Row {
                    width: parent.width
                    spacing: 6

                    Chip {
                        width: (parent.width - parent.spacing * 3) / 4
                        text: "DHCP"
                        selected: WifiStats.dnsProvider === "dhcp"
                        onClicked: {
                            networkPane.dnsCustomOpen = false;
                            WifiStats.setDns("dhcp", "");
                        }
                    }

                    Chip {
                        width: (parent.width - parent.spacing * 3) / 4
                        text: "Cloudflare"
                        selected: WifiStats.dnsProvider === "cloudflare"
                        onClicked: {
                            networkPane.dnsCustomOpen = false;
                            WifiStats.setDns("cloudflare", "");
                        }
                    }

                    Chip {
                        width: (parent.width - parent.spacing * 3) / 4
                        text: "Google"
                        selected: WifiStats.dnsProvider === "google"
                        onClicked: {
                            networkPane.dnsCustomOpen = false;
                            WifiStats.setDns("google", "");
                        }
                    }

                    Chip {
                        width: (parent.width - parent.spacing * 3) / 4
                        text: "Custom"
                        selected: WifiStats.dnsProvider === "custom"
                        onClicked: networkPane.dnsCustomOpen = !networkPane.dnsCustomOpen
                    }
                }

                Row {
                    width: parent.width
                    visible: networkPane.dnsCustomOpen || WifiStats.dnsProvider === "custom"
                    spacing: 6

                    Rectangle {
                        width: parent.width - 66
                        height: 26
                        color: Theme.background
                        border.color: dnsCustomInput.activeFocus ? Theme.primary : Theme.muted
                        border.width: 1
                        radius: 6

                        TextInput {
                            id: dnsCustomInput

                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            clip: true
                            color: Theme.foreground
                            selectionColor: Theme.activeBackground
                            selectedTextColor: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            verticalAlignment: TextInput.AlignVCenter
                            text: WifiStats.dnsProvider === "custom" ? WifiStats.dns.split(",").join(" ") : ""

                            onAccepted: WifiStats.setDns("custom", text)
                        }
                    }

                    Rectangle {
                        width: 60
                        height: 26
                        color: dnsApplyArea.containsMouse ? Theme.activeBackground : Theme.background
                        border.color: Theme.primary
                        border.width: 1
                        radius: 6

                        StyledText {
                            anchors.centerIn: parent
                            text: "apply"
                            font.pixelSize: Theme.fontSizeTiny
                        }

                        MouseArea {
                            id: dnsApplyArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: WifiStats.setDns("custom", dnsCustomInput.text)
                        }
                    }
                }
            }

            Divider {}

            Caption {
                width: parent.width
                label: "Known networks"
            }

            EmptyHint {
                width: parent.width
                visible: networkPane.knownNetworks.length === 0
                text: "No known networks nearby"
            }

            Repeater {
                model: networkPane.knownNetworks

                NetworkEntryRow {}
            }

            RowLayout {
                width: parent.width

                Caption {
                    Layout.fillWidth: true
                    label: "Other networks"
                }

                TextButton {
                    text: "scan"
                    onClicked: NetworkInfo.refresh(true)
                }
            }

            EmptyHint {
                width: parent.width
                visible: networkPane.otherNetworks.length === 0
                text: NetworkInfo.wifiEnabled ? "No other networks nearby" : "Wi-Fi disabled"
            }

            // Collapsed by default: a scan in a busy building can turn up a
            // long tail of networks nobody here is going to join, and the
            // "scan" button above already works without expanding this.
            Expander {
                id: otherNetworksExpander

                width: parent.width
                visible: networkPane.otherNetworks.length > 0

                header: [
                    StyledText {
                        Layout.fillWidth: true
                        text: networkPane.otherNetworks.length + " nearby"
                        color: Theme.muted
                        font.bold: false
                    },
                    StyledText {
                        text: otherNetworksExpander.expanded ? "less" : "more"
                        color: Theme.muted
                        font.bold: false
                        font.pixelSize: Theme.fontSizeTiny
                    }
                ]

                Repeater {
                    model: networkPane.otherNetworks

                    NetworkEntryRow {}
                }
            }
        }
    }

    // One row of the Wi-Fi lists — declared once and used for both the known
    // and other repeaters, which are otherwise identical down to the password
    // footer.
    component NetworkEntryRow: ListRow {
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
