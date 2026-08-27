pragma Singleton

// The laptop battery via UPower, plus the derived text the bar and popup show.
//
// Charge thresholds, charge mode and cycle count come from sysfs rather than
// UPower: the UPowerDevice binding exposes none of them, and on this Dell the two
// disagree anyway (upower reports a 75/80 window against the driver's own 50/90),
// so the kernel's numbers win. All of them are absent on hardware without a
// charge controller that takes limits, and the rows they feed hide themselves
// when that is the case.
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs

Singleton {
    id: root

    // UPower's display device aggregates everything; prefer the real laptop
    // battery so peripherals cannot dilute the reading.
    readonly property UPowerDevice device: {
        const devices = UPower.devices && UPower.devices.values ? UPower.devices.values : [];

        for (const candidate of devices) {
            if (candidate && candidate.isLaptopBattery && candidate.isPresent)
                return candidate;
        }

        return UPower.displayDevice;
    }

    readonly property bool ready: !!(root.device && root.device.ready && root.device.isPresent)

    // Some drivers report a fraction, others a percentage.
    readonly property int percent: {
        const raw = Number(root.device && root.device.ready ? root.device.percentage : 0) || 0;
        return Theme.clampPercent(raw > 0 && raw <= 1 ? raw * 100 : raw);
    }

    readonly property bool charging: root.device
        && (root.device.state === UPowerDeviceState.Charging || root.device.state === UPowerDeviceState.PendingCharge)
    readonly property bool discharging: root.device
        && (root.device.state === UPowerDeviceState.Discharging || root.device.state === UPowerDeviceState.PendingDischarge)

    // The battery's own directory under /sys/class/power_supply, e.g. BAT0.
    readonly property string sysfsPath: root.ready && root.device.nativePath
        ? "/sys/class/power_supply/" + root.device.nativePath
        : ""

    // -1 for "the driver does not report this", which is not the same as 0.
    property int chargeStart: -1
    property int chargeEnd: -1
    property int cycles: -1

    // The selected entry of charge_types, e.g. "Fast" out of
    // "Trickle [Fast] Standard Adaptive Custom". Empty on a driver without the
    // attribute at all, which is the common case.
    property string chargeType: ""

    // Dell keeps the stored thresholds readable whether or not the active charge
    // type honours them — on this machine 50/90 are the untouched Custom
    // defaults while the mode is Fast, so a naive reading would advertise a limit
    // that is not being applied. Only Custom consults them. A driver that
    // publishes thresholds and no charge_types has nothing to override them.
    readonly property bool limitActive: root.chargeEnd > 0
        && (root.chargeType === "" || root.chargeType === "Custom")

    // Charging parked at the limit: on AC, limit in force, and the battery either
    // waiting or nominally charging while drawing nothing.
    readonly property bool holding: {
        if (!root.ready || UPower.onBattery || !root.limitActive)
            return false;

        const state = root.device.state;

        if (state === UPowerDeviceState.PendingCharge)
            return true;

        if (state === UPowerDeviceState.FullyCharged && root.percent < 99)
            return true;

        // A "charging" battery that has reached the limit and stopped taking
        // power is being held, whatever the driver still calls it. 0.2 W is
        // above the noise floor of an idle pack and well below a real charge.
        return state === UPowerDeviceState.Charging
            && Math.abs(Number(root.device.changeRate) || 0) <= 0.2
            && root.chargeEnd < 99
            && root.percent >= root.chargeEnd;
    }

    // "50–90%" when start and stop differ, "90%" when the driver only has a stop
    // threshold, empty when it has neither. A limit the active charge type is
    // ignoring is still worth showing — it is what the firmware would apply — but
    // it says which mode is winning instead, so the row cannot be read as a limit
    // in force.
    readonly property string thresholdText: {
        if (root.chargeEnd <= 0)
            return "";

        const range = root.chargeStart > 0 && root.chargeStart !== root.chargeEnd
            ? root.chargeStart + "–" + root.chargeEnd + "%"
            : root.chargeEnd + "%";

        return root.limitActive ? range : range + " (" + root.chargeType + ")";
    }

    readonly property string cyclesText: root.cycles > 0 ? String(root.cycles) : ""

    readonly property string icon: {
        if (!root.ready)
            return Theme.iconBatteryEmpty;
        if (root.charging)
            return Theme.iconBatteryCharging;
        if (root.percent >= 80)
            return Theme.iconBatteryFull;
        if (root.percent >= 60)
            return Theme.iconBatteryThreeQuarters;
        if (root.percent >= 40)
            return Theme.iconBatteryHalf;
        if (root.percent >= 20)
            return Theme.iconBatteryQuarter;

        return Theme.iconBatteryEmpty;
    }

    readonly property string label: (root.ready ? root.percent + "%" : "--%") + " " + root.icon

    readonly property color foreground: {
        if (!root.ready)
            return Theme.muted;
        if (root.percent <= 15)
            return Theme.danger;
        if (root.percent <= 30)
            return Theme.warning;

        return Theme.success;
    }

    readonly property string stateText: {
        if (!root.ready)
            return "Unavailable";

        // Ahead of the switch: the driver's own state for a held battery is
        // whatever it was doing before it stopped, which reads as a lie.
        if (root.holding)
            return "Holding";

        switch (root.device.state) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.Discharging:
            return "Discharging";
        case UPowerDeviceState.FullyCharged:
            return "Full";
        case UPowerDeviceState.PendingCharge:
            return "Waiting to charge";
        case UPowerDeviceState.PendingDischarge:
            return "Waiting to discharge";
        case UPowerDeviceState.Empty:
            return "Empty";
        default:
            return UPower.onBattery ? "On battery" : "On AC";
        }
    }

    readonly property string timeText: {
        if (!root.ready)
            return "Unknown";
        // Neither estimate means anything while charging is parked: time-to-full
        // never arrives and time-to-empty is not being spent.
        if (root.holding)
            return "Held at " + root.chargeEnd + "%";
        if (root.device.state === UPowerDeviceState.FullyCharged)
            return "Full";

        if (root.charging) {
            const toFull = root.duration(root.device.timeToFull);
            return toFull === "" ? "Charging" : toFull + " to full";
        }

        if (root.discharging || UPower.onBattery) {
            const toEmpty = root.duration(root.device.timeToEmpty);
            return toEmpty === "" ? "Calculating" : toEmpty + " left";
        }

        return UPower.onBattery ? "Calculating" : "On AC";
    }

    readonly property string rateText: {
        if (!root.ready)
            return "-- W";

        const rate = Math.abs(Number(root.device.changeRate) || 0);
        const suffix = root.charging ? "charge" : ((root.discharging || UPower.onBattery) ? "draw" : "idle");
        return rate.toFixed(1) + " W " + suffix;
    }

    readonly property string energyText: {
        if (!root.ready || !root.device.energyCapacity)
            return "Unknown";

        return (Number(root.device.energy) || 0).toFixed(1) + " / " + (Number(root.device.energyCapacity) || 0).toFixed(1) + " Wh";
    }

    // Empty when the driver does not report design capacity — the popup hides
    // the row rather than showing a placeholder.
    readonly property string healthText: {
        if (!root.ready || !root.device.healthSupported)
            return "";

        return Theme.clampPercent(root.device.healthPercentage) + "% health";
    }

    // printErrors is off on all four: these attributes are Dell/ThinkPad-class
    // extras, and a host whose battery driver has none of them would otherwise
    // log a failure on every tick.
    FileView {
        id: chargeStartFile

        path: root.sysfsPath === "" ? "" : root.sysfsPath + "/charge_control_start_threshold"
        printErrors: false
        onLoaded: root.chargeStart = parseInt(chargeStartFile.text()) || -1
        onLoadFailed: root.chargeStart = -1
    }

    FileView {
        id: chargeEndFile

        path: root.sysfsPath === "" ? "" : root.sysfsPath + "/charge_control_end_threshold"
        printErrors: false
        onLoaded: root.chargeEnd = parseInt(chargeEndFile.text()) || -1
        onLoadFailed: root.chargeEnd = -1
    }

    FileView {
        id: cyclesFile

        path: root.sysfsPath === "" ? "" : root.sysfsPath + "/cycle_count"
        printErrors: false
        onLoaded: root.cycles = parseInt(cyclesFile.text()) || -1
        onLoadFailed: root.cycles = -1
    }

    FileView {
        id: chargeTypeFile

        path: root.sysfsPath === "" ? "" : root.sysfsPath + "/charge_types"
        printErrors: false
        // The whole list is one line with the active entry in brackets; drivers
        // that only support one mode print it bare, without brackets.
        onLoaded: {
            const text = chargeTypeFile.text().trim();
            const selected = /\[([^\]]+)\]/.exec(text);
            root.chargeType = selected ? selected[1] : (text.indexOf(" ") < 0 ? text : "");
        }
        onLoadFailed: root.chargeType = ""
    }

    // Slow on purpose: a threshold only moves when someone changes it in the
    // firmware or writes sysfs, and a cycle completes at most a few times a day.
    // The live half of the reading is UPower's and needs no polling here.
    Timer {
        interval: 60000
        repeat: true
        running: root.sysfsPath !== ""
        triggeredOnStart: true

        onTriggered: {
            chargeStartFile.reload();
            chargeEndFile.reload();
            cyclesFile.reload();
            chargeTypeFile.reload();
        }
    }

    function duration(seconds: real): string {
        const value = Math.round(Number(seconds) || 0);
        if (value <= 0)
            return "";

        const minutes = Math.max(1, Math.round(value / 60));
        const hours = Math.floor(minutes / 60);
        const remainder = minutes % 60;

        if (hours <= 0)
            return minutes + "m";

        return hours + "h " + (remainder < 10 ? "0" : "") + remainder + "m";
    }
}
