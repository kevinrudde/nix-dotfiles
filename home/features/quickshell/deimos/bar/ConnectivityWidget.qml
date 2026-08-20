import QtQuick
import QtQuick.Layouts
import qs
import qs.popups
import qs.services
import qs.widgets

// Bluetooth and network status in one pill — each keeps the label it had on
// its own pill, just side by side, Bluetooth first since it sees more use. A
// single click opens the tabbed popup; rescanning either one happens from its
// own tab, not from the bar.
Pill {
    id: root

    required property var barScreen

    text: ""
    horizontalPadding: Theme.pillPadIcon
    minPillWidth: 0
    // Pill normally sizes itself around a text label; this pill's content is
    // a row of two, so its width has to come from that row.
    implicitWidth: contentRow.implicitWidth + root.horizontalPadding * 2
    tooltip: "Bluetooth: " + (!BluetoothInfo.powered ? "off" : BluetoothInfo.connectedDevices.length > 0 ? BluetoothInfo.connectedDevices.length + " connected" : "on")
        + " · Network: " + (SystemStatus.networkConnected ? (NetworkInfo.activeWifi !== "" ? NetworkInfo.activeWifi : "connected") : "disconnected")

    onClicked: Popups.toggle("connectivity", root.barScreen)

    // RowLayout, not Row: a Row sets its children's y itself and ignores any
    // anchors.verticalCenter on them, which would leave the shorter signal
    // reading pinned to the top of the taller glyphs beside it — the same
    // top-alignment gap Bar.qml's own RowLayout switch was for.
    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: 8

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: BluetoothInfo.label
            color: BluetoothInfo.foreground
            font.pixelSize: Theme.fontSizeIcon
        }

        // Signal strength stays at text size while the glyph beside it goes up
        // to icon size — it is a reading, not an icon, and the two are allowed
        // to differ.
        StyledText {
            visible: SystemStatus.networkType === "wifi"
            Layout.alignment: Qt.AlignVCenter
            text: SystemStatus.networkSignal + "%"
            color: SystemStatus.networkConnected ? Theme.primary : Theme.muted
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: SystemStatus.networkIcon
            color: SystemStatus.networkConnected ? Theme.primary : Theme.muted
            font.pixelSize: Theme.fontSizeIcon
        }
    }

    ConnectivityPopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
