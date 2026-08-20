pragma Singleton

// The one-line network summary for the bar, from a shell script: nmcli is the
// only thing that knows which device is actually carrying traffic and how
// strong its signal is, and no Quickshell binding covers it.
//
// This is the shell's only unconditional poller — everything else here gates
// on a `watching` flag set while a popup is open. It stays that way because
// the bar shows this text all the time, but the interval is set to what the
// value actually does: signal strength drifts slowly, and the events that
// change it abruptly (a network switch) call `refreshSoon` themselves.
import Quickshell
import Quickshell.Io
import QtQuick
import qs

Singleton {
    id: root

    readonly property string networkType: root.status.network ? String(root.status.network.type || "") : ""
    readonly property int networkSignal: root.status.network ? Number(root.status.network.signal || 0) : 0
    readonly property bool networkConnected: root.status.network ? !!root.status.network.connected : false

    // The glyph for whatever is carrying traffic, picked here rather than in
    // the script: Theme owns the icons, and NetworkInfo already knows which
    // one a given signal strength deserves.
    readonly property string networkIcon: {
        if (!root.networkConnected)
            return "";

        if (root.networkType === "wifi")
            return NetworkInfo.signalIcon(root.networkSignal);

        if (root.networkType === "ethernet")
            return Theme.iconEthernet;

        return "";
    }

    property var status: ({
            network: {
                type: "",
                signal: 0,
                connected: false
            }
        })

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
        interval: 10000
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
