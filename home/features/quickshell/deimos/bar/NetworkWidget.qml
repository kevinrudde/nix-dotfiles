import qs
import qs.popups
import qs.services
import qs.widgets

// Connection summary from the status script. Right click opens the popup with a
// fresh scan; left click opens it with whatever the last poll returned.
Pill {
    id: root

    required property var barScreen

    text: BarState.expanded ? SystemStatus.networkText : SystemStatus.networkIcon
    foreground: SystemStatus.networkConnected ? Theme.primary : Theme.muted
    horizontalPadding: BarState.expanded ? Theme.pillPad : Theme.pillPadCompact
    maxTextWidth: BarState.expanded ? 110 : 20

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            Popups.open("network", root.barScreen);
            NetworkInfo.refresh(true);
            return;
        }

        Popups.toggle("network", root.barScreen);

        if (Popups.isOpen("network", root.barScreen))
            NetworkInfo.refresh(false);
    }

    NetworkPopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
