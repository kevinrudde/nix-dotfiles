pragma Singleton

// Bar-wide UI state that is deliberately shared across monitors: collapsing the
// right-hand group on one screen collapses it everywhere.
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Shows the overflow icons — the system tray and the sleep-inhibit
    // toggle — that the flat bar keeps tucked away by default.
    property bool expanded: false
    property bool sleepInhibited: false

    // A systemd block inhibitor rather than a Wayland idle inhibitor: the idle
    // chain in hypridle.conf still dims, locks and blanks the panels, and only
    // its suspend rules stand down while logind reports a sleep block. Lives
    // here, not in Bar.qml, so there is one inhibitor however many monitors
    // are connected. setpriv ties the placeholder child to systemd-inhibit, so
    // stopping the Process does not leave an orphaned sleep behind.
    Process {
        running: root.sleepInhibited
        command: ["systemd-inhibit", "--what=sleep", "--mode=block", "--who=quickshell", "--why=Sleep toggle in the bar", "setpriv", "--pdeathsig", "TERM", "sleep", "infinity"]
    }
}
