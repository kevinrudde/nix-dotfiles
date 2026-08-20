pragma Singleton

// Wired links and Wi-Fi networks from nmcli via a script: Quickshell's
// networking module only knows what NetworkManager manages, and the shape
// needed here (signal, security, saved-connection name) takes several nmcli
// calls to assemble anyway.
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    readonly property bool wifiEnabled: !!(root.state && root.state.wifiEnabled)
    readonly property string activeWifi: root.state ? String(root.state.activeWifi || "") : ""
    readonly property var wired: root.state && root.state.wired ? root.state.wired : []
    readonly property var wifi: root.state && root.state.wifi ? root.state.wifi : []

    // SSID whose password prompt is currently expanded in the popup.
    property string passwordSsid: ""

    property var state: ({
            wifiEnabled: false,
            activeWifi: "",
            wired: [],
            wifi: []
        })

    function refresh(rescan: bool): void {
        if (networkProc.running)
            return;

        const script = Quickshell.shellDir + "/scripts/network-status.sh";
        networkProc.command = rescan ? [script, "--rescan"] : [script];
        networkProc.running = true;
    }

    function signalIcon(signal: int): string {
        if (signal >= 80)
            return Theme.iconWifi4;
        if (signal >= 60)
            return Theme.iconWifi3;
        if (signal >= 40)
            return Theme.iconWifi2;
        if (signal >= 20)
            return Theme.iconWifi1;

        return Theme.iconWifi0;
    }

    function detail(network: var): string {
        if (!network)
            return "";

        const parts = [];

        parts.push(network.security ? network.security : "open");

        if (network.known)
            parts.push("saved");
        else if (network.security)
            parts.push("password");

        parts.push(network.signal + "%");
        return parts.join(" · ");
    }

    function canConnect(network: var): bool {
        return !!(network && !network.active);
    }

    // A saved connection needs no password, an open network needs none either.
    function needsPassword(network: var): bool {
        return !!(network && !network.active && network.security && !network.known);
    }

    function connect(network: var, password: string): void {
        if (!root.canConnect(network))
            return;

        // First click on a secured unknown network only opens the prompt.
        if (root.needsPassword(network) && !password) {
            root.passwordSsid = network.ssid || "";
            return;
        }

        networkActionProc.command = [
            Quickshell.shellDir + "/scripts/network-action.sh",
            "connect",
            network.ssid || "",
            network.knownConnection || "",
            network.security || "",
            password || ""
        ];
        networkActionProc.running = true;
        root.passwordSsid = "";
        Popups.close();
    }

    Process {
        id: networkProc

        command: [Quickshell.shellDir + "/scripts/network-status.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.state = JSON.parse(this.text);
                } catch (error) {
                    console.log("quickshell network parse failed: " + error);
                }
            }
        }
    }

    Process {
        id: networkActionProc

        onExited: {
            root.refresh(false);
            SystemStatus.refreshSoon();
        }
    }
}
