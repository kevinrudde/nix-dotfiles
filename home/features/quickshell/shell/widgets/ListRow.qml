import QtQuick
import qs

// One entry in a popup list: leading icon, title with a smaller detail line,
// optional trailing label, and an optional footer that expands the row (the
// Wi-Fi password prompt).
//
// Children of an instance land in the footer, so the internal parts are
// declared through `data` rather than as plain children.
Rectangle {
    id: root

    property string icon: ""
    property color iconColor: Theme.primary
    property string title: ""
    property color titleColor: Theme.primary
    property string detail: ""
    property string trailing: ""
    property color trailingColor: Theme.primary
    property int trailingWidth: 74

    // Highlighted as the current entry: connected device, active network.
    property bool active: false
    property bool interactive: true

    property int minHeight: 36
    property bool footerOpen: false
    property int expandedHeight: 78

    default property alias footer: footerHolder.data
    readonly property alias hovered: area.containsMouse

    signal activated

    implicitHeight: root.footerOpen
        ? root.expandedHeight
        : Math.max(root.minHeight, titleLabel.implicitHeight + detailLabel.implicitHeight + 12)
    height: root.implicitHeight
    color: area.containsMouse || root.active ? Theme.activeBackground : "transparent"
    border.color: root.active ? Theme.primary : "transparent"
    border.width: 1
    radius: Theme.rowRadius

    data: [
        StyledText {
            id: iconLabel

            anchors.left: parent.left
            anchors.leftMargin: 8
            // Top-aligned with the title while the footer is open, centred
            // otherwise — an expanded row is two rows tall.
            y: root.footerOpen ? 13 : (root.height - implicitHeight) / 2
            text: root.icon
            color: root.iconColor
            font.pixelSize: Theme.fontSizeNormal
        },
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 30
            anchors.right: trailingLabel.visible ? trailingLabel.left : parent.right
            anchors.rightMargin: 8
            y: root.footerOpen ? 8 : (root.height - implicitHeight) / 2
            spacing: 1

            StyledText {
                id: titleLabel

                width: parent.width
                text: root.title
                color: root.titleColor
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeNormal
            }

            StyledText {
                id: detailLabel

                width: parent.width
                visible: text !== ""
                text: root.detail
                color: Theme.muted
                elide: Text.ElideRight
                font.bold: false
                font.pixelSize: Theme.fontSizeTiny
            }
        },
        StyledText {
            id: trailingLabel

            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            visible: root.trailing !== ""
            width: root.trailingWidth
            text: root.trailing
            color: root.trailingColor
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeTiny
            horizontalAlignment: Text.AlignRight
        },
        MouseArea {
            id: area

            anchors.fill: parent
            // An open footer owns the row's clicks; its own controls handle them.
            enabled: root.interactive && !root.footerOpen
            hoverEnabled: true
            onClicked: root.activated()
        },
        Item {
            id: footerHolder

            anchors.left: parent.left
            anchors.leftMargin: 30
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            height: 26
            visible: root.footerOpen
        }
    ]
}
