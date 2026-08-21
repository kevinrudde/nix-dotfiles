pragma Singleton

// Live telemetry for the network tab's header and stat grid: ping, packet
// loss, throughput, and the connection's DNS setting. Deliberately not
// always-on — a ping every few seconds is a fair cost while the popup is
// open and a pointless one while it is not, so `watching` gates every timer
// here. NetworkInfo's static per-network facts (signal, security, saved)
// stay in NetworkInfo; this is only what changes while you are looking at it.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Set by the popup: true only while its network tab is open.
    property bool watching: false

    property bool connected: false
    property string device: ""
    property string connection: ""
    property string ip: ""
    property string gateway: ""
    property string band: ""
    property var pingMs: null
    property var packetLoss: null
    // The address the last ping probe actually went to — the DNS server
    // handed out for this connection, or the gateway when no resolver is
    // known yet. Shown next to the reading so "Ping" never implies a target
    // it did not use.
    property string pingTarget: ""
    property string dns: ""
    property bool ignoreAutoDns: false

    // rx/tx are read straight from sysfs rather than through the script:
    // no subprocess needed, and the rate only means something if both sides
    // are sampled from the same tick, which a shared FileView pair here
    // handles more simply than a script invoked twice a second could.
    property real rawRx: 0
    property real rawTx: 0
    property real prevRx: -1
    property real prevTx: -1
    property real lastSampleAt: 0
    property real tickTimestamp: 0
    property bool rxReady: false
    property bool txReady: false
    property real rxRate: 0
    property real txRate: 0

    readonly property string dnsProvider: {
        if (!root.ignoreAutoDns)
            return "dhcp";

        const values = root.dns.split(",").map(v => v.trim()).filter(v => v !== "");
        const asSet = values.slice().sort().join(",");

        if (asSet === "1.0.0.1,1.1.1.1")
            return "cloudflare";
        if (asSet === "8.8.4.4,8.8.8.8")
            return "google";

        return "custom";
    }

    function byteUnits(bytes: real): string {
        const value = Math.max(0, Number(bytes) || 0);
        const units = ["B", "KB", "MB", "GB", "TB"];
        let scaled = value;
        let unitIndex = 0;

        while (scaled >= 1024 && unitIndex < units.length - 1) {
            scaled /= 1024;
            unitIndex++;
        }

        return scaled.toFixed(unitIndex === 0 ? 0 : 2) + " " + units[unitIndex];
    }

    function rateText(bytesPerSecond: real): string {
        return root.byteUnits(bytesPerSecond) + "/s";
    }

    function maybeSample(): void {
        if (!root.rxReady || !root.txReady)
            return;

        if (root.lastSampleAt > 0 && root.prevRx >= 0) {
            const dt = (root.tickTimestamp - root.lastSampleAt) / 1000;
            if (dt > 0) {
                root.rxRate = Math.max(0, (root.rawRx - root.prevRx) / dt);
                root.txRate = Math.max(0, (root.rawTx - root.prevTx) / dt);
            }
        }

        root.prevRx = root.rawRx;
        root.prevTx = root.rawTx;
        root.lastSampleAt = root.tickTimestamp;
    }

    // A device change mid-session (Wi-Fi handed off, adapter swapped) makes
    // the previous counters meaningless — sampling across that jump would
    // report a nonsense spike instead of skipping one tick.
    function resetThroughput(): void {
        root.prevRx = -1;
        root.prevTx = -1;
        root.lastSampleAt = 0;
        root.rxRate = 0;
        root.txRate = 0;
    }

    function refresh(): void {
        if (!fetchProcess.running)
            fetchProcess.running = true;
    }

    function apply(raw: string): void {
        try {
            const data = JSON.parse(raw);
            const previousDevice = root.device;

            root.connected = !!data.connected;
            root.device = String(data.device || "");
            root.connection = String(data.connection || "");
            root.ip = String(data.ip || "");
            root.gateway = String(data.gateway || "");
            root.band = String(data.band || "");
            root.pingMs = typeof data.pingMs === "number" ? data.pingMs : null;
            root.packetLoss = typeof data.packetLoss === "number" ? data.packetLoss : null;
            root.pingTarget = String(data.pingTarget || "");
            root.dns = String(data.dns || "");
            root.ignoreAutoDns = !!data.ignoreAutoDns;

            if (root.device !== previousDevice)
                root.resetThroughput();
        } catch (error) {
            root.connected = false;
        }
    }

    // Radio power lives on NetworkInfo instead: its action process already
    // refreshes `wifiEnabled` on exit, which a detached call here never
    // would — the same reason `setDns` below is not a detached call either.
    function setDns(provider: string, custom: string): void {
        if (root.connection === "" || dnsActionProc.running)
            return;

        dnsActionProc.command = [Quickshell.shellDir + "/scripts/network-action.sh", "set-dns", root.connection, provider, custom || ""];
        dnsActionProc.running = true;
    }

    Process {
        id: fetchProcess

        command: [Quickshell.shellDir + "/scripts/wifi-status.sh"]

        stdout: StdioCollector {
            onStreamFinished: root.apply(this.text)
        }
    }

    Process {
        id: dnsActionProc

        // The reconnect `set-dns` triggers is the only thing that would
        // otherwise tell this poll to run sooner than its next 3-second tick.
        onExited: root.refresh()
    }

    FileView {
        id: rxFile

        path: root.device === "" ? "" : `/sys/class/net/${root.device}/statistics/rx_bytes`

        onLoaded: {
            root.rawRx = parseFloat(rxFile.text()) || 0;
            root.rxReady = true;
            root.maybeSample();
        }
    }

    FileView {
        id: txFile

        path: root.device === "" ? "" : `/sys/class/net/${root.device}/statistics/tx_bytes`

        onLoaded: {
            root.rawTx = parseFloat(txFile.text()) || 0;
            root.txReady = true;
            root.maybeSample();
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.watching
        triggeredOnStart: true

        onTriggered: {
            root.refresh();
            // Catches a change made outside the shell entirely (a manual
            // `nmcli`, a hardware kill switch) — otherwise `wifiEnabled` only
            // ever updates in reaction to an action this shell itself took.
            NetworkInfo.refresh(false);

            if (root.device !== "") {
                root.tickTimestamp = Date.now();
                root.rxReady = false;
                root.txReady = false;
                rxFile.reload();
                txFile.reload();
            }
        }
    }
}
