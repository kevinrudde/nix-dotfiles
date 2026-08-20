pragma Singleton

// Values that have no Quickshell binding and come from a shell script instead:
// the clock string and a one-line network summary.
import Quickshell
import qs
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string clock: String(root.status.clock || "")
    readonly property string networkText: root.status.network ? String(root.status.network.text || "") : ""
    readonly property bool networkConnected: root.status.network ? !!root.status.network.connected : false

    // The compact bar shows only the icon, which the script appends last.
    readonly property string networkIcon: root.lastToken(root.networkText, Theme.iconUnknown)

    property var status: ({
            network: {
                text: "",
                connected: false
            },
            clock: ""
        })

    function lastToken(text: string, fallback: string): string {
        const value = String(text || "").trim();
        if (value === "")
            return fallback;

        const parts = value.split(/\s+/);
        return parts.length > 0 ? parts[parts.length - 1] : fallback;
    }

    function refresh(): void {
        if (!statusProc.running)
            statusProc.running = true;
    }

    // After an action that changes what the script reports (a network
    // switch) — one poll interval of stale text is very visible.
    function refreshSoon(): void {
        refreshDelay.restart();
    }

    Process {
        id: statusProc

        command: [Quickshell.shellDir + "/scripts/status.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(this.text);
                } catch (error) {
                    console.log("quickshell status parse failed: " + error);
                }
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshDelay

        interval: 250
        onTriggered: root.refresh()
    }
}
