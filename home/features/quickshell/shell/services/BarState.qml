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

    // A systemd block inhibitor rather than a Wayland idle inhibitor: hypridle
    // honours logind idle blocks, so its whole chain (dim, lock, blank) pauses,
    // and its suspend rules also stand down while logind reports a sleep block.
    // A manual lock still works. Lives here, not in Bar.qml, so there is one inhibitor however many monitors
    // are connected. setpriv ties the placeholder child to systemd-inhibit, so
    // stopping the Process does not leave an orphaned sleep behind.
    Process {
        running: root.sleepInhibited
        command: ["systemd-inhibit", "--what=sleep:idle", "--mode=block", "--who=quickshell", "--why=Idle toggle in the bar", "setpriv", "--pdeathsig", "TERM", "sleep", "infinity"]
    }
}
