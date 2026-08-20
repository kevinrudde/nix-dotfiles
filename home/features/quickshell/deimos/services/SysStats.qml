pragma Singleton

// CPU load and memory use straight from /proc — no subprocess per tick.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // 0..1
    property real cpu: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0

    readonly property real mem: root.memTotalGiB > 0 ? root.memUsedGiB / root.memTotalGiB : 0

    // Previous jiffy counters; CPU load is the delta between two readings.
    property real prevTotal: 0
    property real prevIdle: 0

    function parseStat(text: string): void {
        const line = text.split("\n", 1)[0];
        if (!line.startsWith("cpu "))
            return;

        const fields = line.split(/\s+/).slice(1).map(parseFloat);
        if (fields.length < 5)
            return;

        // idle + iowait count as not-busy.
        const idle = fields[3] + fields[4];
        let total = 0;
        for (const value of fields)
            total += value;

        const deltaTotal = total - root.prevTotal;
        const deltaIdle = idle - root.prevIdle;

        if (root.prevTotal > 0 && deltaTotal > 0)
            root.cpu = Math.max(0, Math.min(1, 1 - deltaIdle / deltaTotal));

        root.prevTotal = total;
        root.prevIdle = idle;
    }

    function parseMem(text: string): void {
        let total = 0;
        let available = 0;

        for (const line of text.split("\n")) {
            if (line.startsWith("MemTotal:"))
                total = parseFloat(line.split(/\s+/)[1]);
            else if (line.startsWith("MemAvailable:"))
                available = parseFloat(line.split(/\s+/)[1]);

            if (total > 0 && available > 0)
                break;
        }

        if (total <= 0)
            return;

        root.memTotalGiB = total / 1048576;
        root.memUsedGiB = (total - available) / 1048576;
    }

    FileView {
        id: statFile

        path: "/proc/stat"
        onLoaded: root.parseStat(statFile.text())
    }

    FileView {
        id: memFile

        path: "/proc/meminfo"
        onLoaded: root.parseMem(memFile.text())
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            statFile.reload();
            memFile.reload();
        }
    }
}
