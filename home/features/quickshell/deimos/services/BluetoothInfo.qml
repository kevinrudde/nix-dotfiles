pragma Singleton

// The default Bluetooth adapter and its devices, sorted the way the popup shows
// them: connected first, then paired, then the rest by name.
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import qs

Singleton {
    id: root

    // Null in the first frame — the adapter arrives over DBus asynchronously.
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: !!(root.adapter && root.adapter.enabled)
    readonly property bool discovering: !!(root.adapter && root.adapter.discovering)

    readonly property var devices: {
        const values = root.adapter && root.adapter.devices && root.adapter.devices.values ? root.adapter.devices.values : [];

        return values.slice().sort((left, right) => {
            const leftConnected = left && left.connected ? 0 : 1;
            const rightConnected = right && right.connected ? 0 : 1;
            if (leftConnected !== rightConnected)
                return leftConnected - rightConnected;

            const leftPaired = left && (left.paired || left.bonded) ? 0 : 1;
            const rightPaired = right && (right.paired || right.bonded) ? 0 : 1;
            if (leftPaired !== rightPaired)
                return leftPaired - rightPaired;

            return root.deviceName(left).localeCompare(root.deviceName(right));
        });
    }

    readonly property var connectedDevices: root.devices.filter(device => device && device.connected)

    // Bar label: the count when something is connected, the crossed-out icon
    // when the adapter is off.
    readonly property string label: root.powered
        ? (root.connectedDevices.length > 0 ? root.connectedDevices.length + " " + Theme.iconBluetooth : Theme.iconBluetooth)
        : Theme.iconBluetoothOff

    readonly property string compactLabel: root.powered ? Theme.iconBluetooth : Theme.iconBluetoothOff

    readonly property color foreground: {
        if (!root.powered)
            return Theme.muted;

        return root.connectedDevices.length > 0 ? Theme.success : Theme.primary;
    }

    function deviceName(device: BluetoothDevice): string {
        return device ? (device.name || device.deviceName || device.address || "Unknown") : "Unknown";
    }

    function deviceIcon(device: BluetoothDevice): string {
        const icon = String(device && device.icon ? device.icon : "");

        if (icon.indexOf("head") >= 0 || icon.indexOf("audio") >= 0)
            return Theme.iconHeadphones;
        if (icon.indexOf("keyboard") >= 0)
            return Theme.iconKeyboard;
        if (icon.indexOf("mouse") >= 0)
            return Theme.iconMouse;

        return Theme.iconBluetooth;
    }

    // A device mid-connect must not take another click: BlueZ would queue both.
    function busy(device: BluetoothDevice): bool {
        return !!(device && (device.pairing
            || device.state === BluetoothDeviceState.Connecting
            || device.state === BluetoothDeviceState.Disconnecting));
    }

    function detail(device: BluetoothDevice): string {
        if (!device)
            return "";

        const parts = [];

        if (device.connected)
            parts.push("connected");
        else if (root.busy(device))
            parts.push("busy");
        else if (device.paired || device.bonded)
            parts.push("paired");
        else
            parts.push("new");

        if (device.trusted)
            parts.push("trusted");

        return parts.join(" · ");
    }

    function actionText(device: BluetoothDevice): string {
        if (!root.powered)
            return "";
        if (root.busy(device))
            return "busy";
        if (device.connected)
            return "disconnect";

        return device.paired || device.bonded ? "connect" : "pair";
    }

    function activate(device: BluetoothDevice): void {
        if (!device || !root.powered || device.blocked || root.busy(device))
            return;

        if (device.connected) {
            device.disconnect();
            return;
        }

        // Trusting first means BlueZ reconnects the device on its own later.
        device.trusted = true;

        if (device.paired || device.bonded)
            device.connect();
        else
            device.pair();
    }

    // Scanning burns power and floods the list, so it always stops on a timer
    // rather than running until the popup closes.
    function setScanning(discovering: bool): void {
        if (!root.adapter || !root.adapter.enabled)
            return;

        root.adapter.discovering = discovering;

        if (discovering)
            scanTimer.restart();
        else
            scanTimer.stop();
    }

    function togglePower(): void {
        if (!root.adapter)
            return;

        if (root.adapter.enabled)
            scanTimer.stop();

        root.adapter.enabled = !root.adapter.enabled;
    }

    Timer {
        id: scanTimer

        interval: 6000
        onTriggered: {
            if (root.adapter)
                root.adapter.discovering = false;
        }
    }
}
