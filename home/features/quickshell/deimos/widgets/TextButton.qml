import QtQuick
import qs

// Label that acts as a button: no chrome, only a colour change on hover. The
// hit area reaches past the glyphs because the labels are short ("scan",
// "clear") and would otherwise be hard to hit.
StyledText {
    id: root

    property color restColor: Theme.primary
    property color hoverColor: Theme.foreground
    property bool interactive: true

    readonly property alias hovered: area.containsMouse

    signal clicked

    color: area.containsMouse ? root.hoverColor : root.restColor

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -6
        enabled: root.interactive
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
