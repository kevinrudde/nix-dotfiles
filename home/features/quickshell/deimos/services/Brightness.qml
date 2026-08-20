pragma Singleton

// Backlight, read from sysfs and set through brightnessctl. Reading it this way
// instead of parsing the status script keeps the slider responsive: sysfs is a
// FileView away, and a dragged slider fires far faster than a shell process can
// return.
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    property string device: ""
    property real max: 0
    property real raw: 0

    readonly property bool available: root.device !== "" && root.max > 1
    readonly property int percent: root.available ? Theme.clampPercent(root.raw / root.max * 100) : 0

    readonly property string icon: {
        if (root.percent < 34)
            return Theme.iconBrightnessLow;
        if (root.percent < 67)
            return Theme.iconBrightnessMedium;

        return Theme.iconBrightnessHigh;
    }

    function setPercent(percent: real): void {
        if (!root.available)
            return;

        // Never all the way to 0 — a black display is not a setting a slider
        // drag should be able to reach.
        const clamped = Math.round(Math.max(2, Math.min(100, percent)));
        // Set optimistically; the poll below confirms it shortly after.
        root.raw = root.max * clamped / 100;
        // Detached rather than a Process object: a drag fires calls faster than
        // a single brightnessctl invocation returns.
        Quickshell.execDetached(["brightnessctl", "-q", "-d", root.device, "set", `${clamped}%`]);
    }

    function toggle(): void {
        root.setPercent(root.percent > 50 ? 20 : 100);
    }

    Process {
        id: detectProc

        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight/ 2>/dev/null | head -n1"]

        stdout: StdioCollector {
            onStreamFinished: root.device = this.text.trim()
        }
    }

    FileView {
        id: maxFile

        path: root.device === "" ? "" : `/sys/class/backlight/${root.device}/max_brightness`
        onLoaded: root.max = parseFloat(maxFile.text())
    }

    FileView {
        id: currentFile

        path: root.device === "" ? "" : `/sys/class/backlight/${root.device}/brightness`
        onLoaded: root.raw = parseFloat(currentFile.text())
    }

    Timer {
        interval: 2000
        running: root.device !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: currentFile.reload()
    }
}
