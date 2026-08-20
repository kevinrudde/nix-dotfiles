import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// One bar per monitor: a single flush, opaque strip — not a floating row of
// boxed pills — with icons sitting directly on it. Three separately anchored
// groups instead of one layout row, so the centred window title does not
// shift when a neighbour changes width.
PanelWindow {
    id: root

    // Injected by the Variants in shell.qml: the monitor this bar belongs to.
    required property var modelData

    screen: root.modelData
    implicitHeight: Theme.barHeight
    color: Theme.barBackground

    anchors {
        top: true
        left: true
        right: true
    }

    surfaceFormat {
        opaque: true
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
        anchors.leftMargin: Theme.barEdgeInset
        anchors.rightMargin: Theme.barEdgeInset

        // The notification centre lines up with the corner of the screen rather
        // than with the bell that opens it.
        Item {
            id: centreAnchor

            width: 1
            height: 1
            anchors.top: parent.top
            anchors.right: parent.right
        }

        // RowLayout rather than Row: a plain Row top-aligns children of
        // different heights instead of centring each one, which is
        // invisible between same-height pills but very visible between the
        // launcher's tall icon pill and the shorter, borderless workspace
        // numbers next to it.
        RowLayout {
            id: leftGroup

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.barGap

            LauncherButton {
                Layout.alignment: Qt.AlignVCenter
            }

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
            }

            SubmapIndicator {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        WindowTitle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            // Symmetrical around the centre: whichever group is wider decides,
            // otherwise the title would sit off-centre or overlap one side.
            availableWidth: content.width - 2 * Math.max(leftGroup.width, rightGroup.width) - 60
        }

        RowLayout {
            id: rightGroup

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.barGap

            ExpandToggle {
                Layout.alignment: Qt.AlignVCenter
            }

            TrayWidget {
                Layout.alignment: Qt.AlignVCenter
                barWindow: root
            }

            IdleToggle {
                Layout.alignment: Qt.AlignVCenter
            }

            SystemWidget {
                Layout.alignment: Qt.AlignVCenter
                barScreen: root.screen
            }

            ConnectivityWidget {
                Layout.alignment: Qt.AlignVCenter
                barScreen: root.screen
            }

            GitHubWidget {
                Layout.alignment: Qt.AlignVCenter
                barScreen: root.screen
            }

            NotificationWidget {
                Layout.alignment: Qt.AlignVCenter
                barScreen: root.screen
                centreAnchor: centreAnchor
            }

            ClockWidget {
                Layout.alignment: Qt.AlignVCenter
            }

            PowerButton {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
