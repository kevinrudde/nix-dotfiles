import QtQuick
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

    onClicked: Popups.toggle("connectivity", root.barScreen)

    Row {
        id: contentRow

        anchors.centerIn: parent
        spacing: 8

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: BluetoothInfo.label
            color: BluetoothInfo.foreground
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: SystemStatus.networkText
            color: SystemStatus.networkConnected ? Theme.primary : Theme.muted
        }
    }

    ConnectivityPopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
