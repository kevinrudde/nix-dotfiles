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
                screen: root.modelData
            }

            SubmapIndicator {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        WindowTitle {
            id: title

            anchors.verticalCenter: parent.verticalCenter
            // Centred on the screen, not on the free space between the two
            // groups: rightGroup is much wider than leftGroup, so splitting
            // the gap would pull the title visibly left of the monitor's
            // middle. availableWidth below keeps it from reaching either
            // group while it stays put.
            anchors.horizontalCenter: parent.horizontalCenter
            // Symmetrical around the centre: whichever group is wider decides,
            // otherwise the title would sit off-centre or overlap one side.
            // Twice the recording indicator, not once: it only eats room on
            // the right, so the same has to come off the left or the title
            // stops being centred the moment the microphone opens.
            availableWidth: content.width - 2 * Math.max(leftGroup.width, rightGroup.width) - 60 - 2 * (recording.visible ? recording.width + Theme.barGap : 0)
        }

        // Anchored to the title rather than placed in either group: it belongs
        // to the middle of the bar, and the title's own width changes with
        // every window focus.
        RecordingIndicator {
            id: recording

            // Baseline, not verticalCenter: both pills centre their own ink,
            // and the title's ink box grows downwards whenever its text has a
            // descender in it. Sharing a centre therefore puts the two on
            // different lines depending on the focused window's name; sharing
            // a baseline puts them on the same one always.
            anchors.baseline: title.baseline
            // Placed against the title's text, not against its pill. The pill
            // carries 14px of padding on each side for its own hover
            // highlight, and using its edge puts that padding into the gap —
            // which then reads as the space between two groups rather than
            // between a label and the icon annotating it. Subtracting this
            // pill's own padding as well leaves exactly `barGap` between the
            // two inks.
            anchors.left: title.left
            anchors.leftMargin: (title.width + title.drawnTextWidth) / 2 + Theme.barGap - recording.horizontalPadding
            barScreen: root.screen
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

            ClaudeUsageWidget {
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
