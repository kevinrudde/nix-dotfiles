import QtQuick
import Quickshell
import qs

// A small bubble that appears after a pause in hovering, anchored under
// whatever declares it. Purely informational — `mask: Region {}` makes it
// click-through, the same way the volume OSD is, so it can never swallow a
// click meant for whatever is underneath once it fades in.
PopupWindow {
    id: root

    property Item anchorItem: null
    property bool hovering: false
    property string text: ""

    property bool ready: false

    visible: root.hovering && root.ready && root.text !== ""
    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 10
    color: "transparent"
    mask: Region {}

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        adjustment: PopupAdjustment.Slide
        margins.top: 6
    }

    surfaceFormat {
        opaque: false
    }

    // A brief pause rather than instant, so sweeping the mouse across the
    // bar does not flash a tooltip under every icon it passes over.
    onHoveringChanged: {
        if (root.hovering) {
            delay.restart();
        } else {
            delay.stop();
            root.ready = false;
        }
    }

    Timer {
        id: delay

        interval: 650
        onTriggered: root.ready = true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.backgroundStrong
        border.color: Theme.primary
        border.width: 1
        radius: Theme.rowRadius

        StyledText {
            id: label

            anchors.centerIn: parent
            text: root.text
            font.bold: false
            font.pixelSize: Theme.fontSizeTiny
        }
    }
}
