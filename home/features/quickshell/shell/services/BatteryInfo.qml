pragma Singleton

// The laptop battery via UPower, plus the derived text the bar and popup show.
import Quickshell
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
