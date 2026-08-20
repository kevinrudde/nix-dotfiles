import QtQuick
import QtQuick.Layouts
import qs
import qs.popups
import qs.services
import qs.widgets

// Bell with the number of pending notifications. Right click toggles do not
// disturb, which also drops the toasts currently on screen. Count and icon
// are two separately-centred items, not one combined string — see
// CenteredGlyph.qml for why that matters here. The row itself is a
// RowLayout, not a plain Row: a Row sets its children's y directly and
// ignores any anchors.verticalCenter on them, so the shorter count badge
// would sit pinned to the top of the taller icon's row instead of centred
// against it — the same top-alignment gap Bar.qml's own RowLayout switch
// was for.
Pill {
    id: root

    required property var barScreen
    // The centre hangs off the corner of the bar, not off this pill.
    required property Item centreAnchor

    readonly property color tint: NotificationService.dnd ? Theme.muted : Theme.primary

    text: ""
    horizontalPadding: Theme.pillPadIcon
    minPillWidth: 0
    implicitWidth: contentRow.implicitWidth + root.horizontalPadding * 2
    tooltip: NotificationService.dnd
        ? "Do not disturb"
        : NotificationService.count + (NotificationService.count === 1 ? " notification" : " notifications")

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            NotificationService.toggleDnd();
        else
            Popups.toggle("notifications", root.barScreen);
    }

    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: 4

        CenteredGlyph {
            Layout.alignment: Qt.AlignVCenter
            visible: NotificationService.count > 0
            text: String(NotificationService.count)
            font.pixelSize: Theme.fontSizeSmall
            color: root.tint
        }

        CenteredGlyph {
            Layout.alignment: Qt.AlignVCenter
            text: NotificationService.icon
            color: root.tint
        }
    }

    NotificationCenter {
        anchorItem: root.centreAnchor
        popupScreen: root.barScreen
    }
}
