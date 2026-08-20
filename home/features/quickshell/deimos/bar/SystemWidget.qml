import QtQuick
import qs
import qs.popups
import qs.services
import qs.widgets

// System resources, volume and battery in one pill — CPU/RAM as small bars,
// volume and battery as bare icons; the popup carries the percentages, the
// bar only carries the glance. Left click opens the combined system popup;
// wheel and middle click act on the default sink without opening anything,
// matching how the other pills handle their primary control.
Pill {
    id: root

    required property var barScreen

    text: ""
    horizontalPadding: Theme.pillPadIcon
    minPillWidth: 0
    // Pill normally sizes itself around a text label; this pill's content is a
    // row of widgets instead, so its width has to come from that row.
    implicitWidth: contentRow.implicitWidth + root.horizontalPadding * 2

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            Audio.toggleMute(Audio.sink);
        else
            Popups.toggle("system", root.barScreen);
    }

    onWheel: wheel => Audio.stepVolume(Audio.sink, wheel.angleDelta.y > 0 ? 5 : -5)

    Row {
        id: contentRow

        anchors.centerIn: parent
        spacing: 8

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            ProgressBar {
                width: 20
                height: 4
                percent: Theme.clampPercent(SysStats.cpu * 100)
                fillColor: SysStats.cpu > 0.85 ? Theme.danger : (SysStats.cpu > 0.6 ? Theme.warning : Theme.primary)
            }

            ProgressBar {
                width: 20
                height: 4
                percent: Theme.clampPercent(SysStats.mem * 100)
                fillColor: SysStats.mem > 0.9 ? Theme.danger : Theme.success
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.sinkIcon
            color: Audio.sinkMuted ? Theme.muted : Theme.primary
            font.pixelSize: Theme.fontSizeNormal
        }

        StyledText {
            visible: BatteryInfo.ready
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryInfo.icon
            color: BatteryInfo.foreground
            font.pixelSize: Theme.fontSizeNormal
        }
    }

    SystemPopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
