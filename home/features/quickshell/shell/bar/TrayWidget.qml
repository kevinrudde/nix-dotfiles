import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs
import qs.services
import qs.widgets

// System tray: third-party icons this shell has no say over the look of.
// Tucked behind the overflow toggle so they cannot outnumber the bar's own,
// consistent icons. Left click activates, right click opens the item's own
// DBus menu, middle click triggers its secondary action.
Island {
    id: root

    required property var barWindow

    visible: BarState.expanded && SystemTray.items.values.length > 0
    spacing: 6

    Repeater {
        model: SystemTray.items

        Item {
            id: slot

            required property var modelData

            width: Theme.fontSizeIcon
            height: Theme.fontSizeIcon

            IconImage {
                anchors.centerIn: parent
                // Sized off the icon font rather than a number of its own:
                // these sit in the same row as the glyph icons and have to
                // read as the same size as them.
                implicitSize: Theme.fontSizeIcon
                source: slot.modelData.icon
            }

            HoverTooltip {
                anchorItem: slot
                hovering: iconMouse.containsMouse
                // Neither field is guaranteed — a tray item that sets
                // neither just never shows a tooltip.
                text: slot.modelData.tooltipTitle || slot.modelData.title || ""
            }

            MouseArea {
                id: iconMouse

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                hoverEnabled: true

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
