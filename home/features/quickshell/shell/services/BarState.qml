pragma Singleton

// Bar-wide UI state that is deliberately shared across monitors: collapsing the
// right-hand group on one screen collapses it everywhere.
import Quickshell

Singleton {
    id: root

    // Shows the overflow icons — the system tray and the idle-inhibit
    // toggle — that the flat bar keeps tucked away by default.
    property bool expanded: false
    property bool idleInhibited: false
}
