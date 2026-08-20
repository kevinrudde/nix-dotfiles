import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// One bar per monitor. The bar itself is transparent — only the pills are
// visible. Three separately anchored groups instead of one layout row, so the
// centred window title does not shift when a neighbour changes width.
PanelWindow {
    id: root

    // Injected by the Variants in shell.qml: the monitor this bar belongs to.
    required property var modelData

    screen: root.modelData
    implicitHeight: Theme.barHeight
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.barMarginTop
        left: Theme.barMarginSide
        right: Theme.barMarginSide
    }

    surfaceFormat {
        opaque: false
    }

    // Inhibiting idle needs a surface to hang off; the bar is the one window
    // that is always there.
    IdleInhibitor {
        window: root
        enabled: BarState.idleInhibited
    }

    Item {
        id: content

        anchors.fill: parent

        // The notification centre lines up with the corner of the screen rather
        // than with the bell that opens it.
        Item {
            id: centreAnchor

            width: 1
            height: 1
            anchors.top: parent.top
            anchors.right: parent.right
        }

        Row {
            id: leftGroup

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.barGap

            LauncherButton {}

            Workspaces {}

            SubmapIndicator {}
        }

        WindowTitle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            // Symmetrical around the centre: whichever group is wider decides,
            // otherwise the title would sit off-centre or overlap one side.
            availableWidth: content.width - 2 * Math.max(leftGroup.width, rightGroup.width) - 60
        }

        Row {
            id: rightGroup

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: BarState.expanded ? Theme.barGap : Theme.barGapCompact

            ExpandToggle {}

            TrayWidget {
                barWindow: root
            }

            IdleToggle {}

            SystemWidget {
                barScreen: root.screen
            }

            ConnectivityWidget {
                barScreen: root.screen
            }

            GitHubWidget {
                barScreen: root.screen
            }

            NotificationWidget {
                barScreen: root.screen
                centreAnchor: centreAnchor
            }

            ClockWidget {}

            PowerButton {}
        }
    }
}
