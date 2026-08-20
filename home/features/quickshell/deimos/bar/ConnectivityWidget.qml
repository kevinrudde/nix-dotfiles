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

    // RowLayout, not Row: a Row sets its children's y itself and ignores
    // any anchors.verticalCenter on them — harmless here only because both
    // labels happen to share the same font size, which hid the same bug
    // NotificationWidget and GitHubWidget actually showed once their two
    // parts stopped being the same height.
    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: 8

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: BluetoothInfo.label
            color: BluetoothInfo.foreground
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: SystemStatus.networkText
            color: SystemStatus.networkConnected ? Theme.primary : Theme.muted
        }
    }

    ConnectivityPopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
