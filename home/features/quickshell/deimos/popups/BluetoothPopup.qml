import QtQuick
import qs
import qs.services
import qs.widgets

// Paired and discovered devices. One click connects, disconnects or pairs,
// depending on the state the device is in.
BarPopup {
    id: root

    popupName: "bluetooth"
    body: surface

    PopupSurface {
        id: surface

        surfaceWidth: 380

        SectionHeader {
            width: parent.width
            title: "Bluetooth"

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
}
