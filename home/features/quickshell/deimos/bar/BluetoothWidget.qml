import qs
import qs.popups
import qs.services
import qs.widgets

// Bluetooth state: crossed-out icon when the adapter is off, the number of
// connected devices when there are any. Right click opens the popup and starts
// a scan.
Pill {
    id: root

    required property var barScreen

    text: BarState.expanded ? BluetoothInfo.label : BluetoothInfo.compactLabel
    foreground: BluetoothInfo.foreground
    horizontalPadding: BarState.expanded ? Theme.pillPad : Theme.pillPadCompact
    maxTextWidth: BarState.expanded ? 70 : 20

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            Popups.open("bluetooth", root.barScreen);
            BluetoothInfo.setScanning(true);
        } else {
            Popups.toggle("bluetooth", root.barScreen);
        }
    }

    BluetoothPopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
