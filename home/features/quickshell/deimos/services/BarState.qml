pragma Singleton

// Bar-wide UI state that is deliberately shared across monitors: collapsing the
// right-hand group on one screen collapses it everywhere.
import Quickshell

Singleton {
    id: root

    // Right-hand group shows labels and the secondary pills.
    property bool expanded: false
    property bool idleInhibited: false
}
