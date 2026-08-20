import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.widgets

// System tray. Left click activates, right click opens the item's own DBus
// menu, middle click triggers its secondary action.
Island {
    id: root

    required property var barWindow

    visible: SystemTray.items.values.length > 0
    spacing: 6

    Repeater {
        model: SystemTray.items

        Item {
            id: slot

            required property var modelData

            width: 18
            height: 18

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: slot.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && slot.modelData.hasMenu) {
                        // The menu is placed by the tray item itself and wants
                        // window coordinates, so the icon's position has to be
                        // mapped out of the layout it sits in.
                        const position = slot.mapToItem(null, 0, 0);
                        slot.modelData.display(root.barWindow, position.x, root.barWindow.height);
                    } else if (mouse.button === Qt.MiddleButton) {
                        slot.modelData.secondaryActivate();
                    } else {
                        slot.modelData.activate();
                    }
                }

                onWheel: wheel => slot.modelData.scroll(wheel.angleDelta.y, false)
            }
        }
    }
}
