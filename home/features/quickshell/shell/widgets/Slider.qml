import QtQuick
import qs

// Draggable track with a handle. Reports positions rather than owning a value:
// the value belongs to the device it controls, and writing it back through a
// binding would fight with changes coming from elsewhere.
Item {
    id: root

    property int percent: 0
    property color fillColor: Theme.primary

    // Absolute position picked by click or drag.
    signal moved(real percent)
    // One wheel notch, sign only.
    signal stepped(real direction)

    implicitHeight: 20

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        color: Theme.trackBackground
        radius: 2
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * Theme.clampPercent(root.percent) / 100
        height: 4
        color: root.fillColor
        radius: 2
    }

    Rectangle {
        width: 14
        height: 14
        x: Math.max(0, Math.min(parent.width - width, parent.width * Theme.clampPercent(root.percent) / 100 - width / 2))
        y: Math.round((parent.height - height) / 2)
        color: area.containsMouse ? Theme.foreground : root.fillColor
        border.color: Theme.trackBackground
        border.width: 1
        radius: 7
    }

    MouseArea {
        id: area

        // The track is thin; the grab area is not.
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true

        function report(x: real): void {
            if (root.width > 0)
                root.moved(x * 100 / root.width);
        }

        onPressed: mouse => area.report(mouse.x)
        onPositionChanged: mouse => {
            if (area.pressed)
                area.report(mouse.x);
        }
        onWheel: wheel => root.stepped(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
