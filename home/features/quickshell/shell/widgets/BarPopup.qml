import QtQuick
import Quickshell
import qs
import qs.services

// A popup hanging off a bar item. Open state lives in the Popups singleton, so
// opening one closes whatever else was open — including on another monitor.
//
// `grabFocus` is what closes the popup on a click elsewhere; Quickshell hides
// the window itself, and `onVisibleChanged` reports that back to the singleton.
PopupWindow {
    id: root

    // Identifies this popup in the Popups singleton; unique per shell.
    required property string popupName
    // The screen this instance belongs to — two bars own two popups of the same
    // name and only the one on the clicked screen may open.
    required property var popupScreen
    property Item anchorItem: null
    // Item whose implicit size the window follows.
    property Item body: null
    // 0 means "as tall as the body wants to be".
    property int maxHeight: 0
    // Set when the body cannot state its own width — a column whose children
    // size themselves off it has an implicit width of zero.
    property int surfaceWidth: 0

    property int anchorEdges: Edges.Bottom | Edges.Right
    property int anchorGravity: Edges.Bottom | Edges.Left
    property int anchorMarginTop: Theme.popupOffset

    readonly property bool open: Popups.isOpen(root.popupName, root.popupScreen)
    readonly property int bodyHeight: root.body ? root.body.implicitHeight : 0

    visible: root.open
    implicitWidth: root.surfaceWidth > 0 ? root.surfaceWidth : (root.body ? root.body.implicitWidth : 0)
    implicitHeight: root.maxHeight > 0 ? Math.min(root.bodyHeight, root.maxHeight) : root.bodyHeight
    color: "transparent"
    grabFocus: true

    onVisibleChanged: {
        if (!root.visible)
            Popups.closeIf(root.popupName, root.popupScreen);
    }

    anchor {
        item: root.anchorItem
        edges: root.anchorEdges
        gravity: root.anchorGravity
        adjustment: PopupAdjustment.Slide | PopupAdjustment.FlipY
        margins.top: root.anchorMarginTop
    }

    surfaceFormat {
        opaque: false
    }

    // Escape closes whatever is open, to match the click-elsewhere that
    // `grabFocus` already gives. Its own item rather than a handler on the
    // body, so every popup gets it without each one remembering to.
    //
    // A text field in the body keeps Escape while it has the focus — Qt
    // delivers the key to the focused item and walks up its own parents, which
    // never reach here. That is the order you want anyway: escape the field
    // you are typing in before the popup around it.
    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: Popups.close()
    }
}
