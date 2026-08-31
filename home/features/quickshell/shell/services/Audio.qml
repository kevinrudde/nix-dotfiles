pragma Singleton

// Pipewire: the default sink and source, the pickable device lists, and the
// volume OSD that any volume change anywhere triggers.
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs

Singleton {
    id: root

    // Which side the audio popup is showing; also decides what the popup's
    // slider and device list act on.
    property string mode: "output"

    property bool osdOpen: false

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property PwNode current: root.node(root.mode)

    readonly property int sinkPercent: root.percent(root.sink)
    readonly property bool sinkMuted: root.muted(root.sink)
    readonly property string sinkIcon: root.icon(root.sinkMuted, root.sinkPercent)

    readonly property int currentPercent: root.percent(root.current)
    readonly property bool currentMuted: root.muted(root.current)

    readonly property var outputs: root.sorted(Pipewire.nodes.values.filter(node => root.isOutput(node)))
    readonly property var inputs: root.sorted(Pipewire.nodes.values.filter(node => root.isInput(node)))
    readonly property var devices: root.mode === "output" ? root.outputs : root.inputs

    // Applications currently holding a capture stream, by name, deduplicated —
    // one app can open the microphone more than once.
    readonly property var recorders: {
        const names = [];

        for (const node of Pipewire.nodes.values) {
            if (!root.isCapture(node))
                continue;

            const name = root.clientName(node);
            if (names.indexOf(name) < 0)
                names.push(name);
        }

        return names;
    }
    readonly property bool recording: root.recorders.length > 0

    function node(mode: string): PwNode {
        return mode === "output" ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;
    }

    function percent(node: PwNode): int {
        return Theme.clampPercent(node && node.audio ? node.audio.volume * 100 : 0);
    }

    function muted(node: PwNode): bool {
        return !!(node && node.audio && node.audio.muted);
    }

    function icon(muted: bool, percent: int): string {
        if (muted)
            return Theme.iconVolumeMuted;
        if (percent < 30)
            return Theme.iconVolumeLow;
        if (percent < 70)
            return Theme.iconVolumeMedium;

        return Theme.iconVolumeHigh;
    }

    // Label for the expanded bar: "muted" reads faster than "0%".
    function label(node: PwNode): string {
        const isMuted = root.muted(node);
        const value = root.percent(node);
        return (isMuted ? "muted " : value + "% ") + root.icon(isMuted, value);
    }

    function setVolume(node: PwNode, percent: real): void {
        if (!node || !node.audio)
            return;

        node.audio.volume = Theme.clampPercent(percent) / 100;
    }

    function stepVolume(node: PwNode, delta: real): void {
        root.setVolume(node, root.percent(node) + delta);
    }

    function toggleMute(node: PwNode): void {
        if (!node || !node.audio)
            return;

        node.audio.muted = !node.audio.muted;
    }

    function setCurrentVolume(percent: real): void {
        root.setVolume(root.current, percent);
    }

    function select(node: PwNode): void {
        if (!node)
            return;

        if (root.mode === "output")
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    function isCurrent(node: PwNode): bool {
        return !!(root.current && node && root.current.id === node.id);
    }

    function displayName(node: PwNode): string {
        if (!node)
            return "Unknown";

        return node.description || node.nickname || node.name || "Unknown";
    }

    // Second line of a device row: only worth showing when it adds something
    // the display name does not already say.
    function detail(node: PwNode): string {
        if (!node)
            return "";

        const nickname = node.nickname || "";
        if (nickname !== "" && nickname !== root.displayName(node))
            return nickname;

        return node.name || "";
    }

    // Something is reading from a source. `isStream && !isSink` alone is not
    // enough: a filter chain is a stream too, and this machine's speaker tuning
    // is connected from boot, so the plain check reads as "always recording".
    // Only a real client carries `application.name`.
    //
    // No check on `pulse.corked` — an app can hold the source open without
    // pulling from it, but corking flips on a live node, and this list is only
    // re-evaluated when nodes come and go. Reporting the mic as open when an
    // app merely has it claimed is the failure worth having in this direction.
    function isCapture(node: PwNode): bool {
        if (!node || !node.isStream || node.isSink || !node.audio)
            return false;

        return !!(node.properties && node.properties["application.name"]);
    }

    function clientName(node: PwNode): string {
        const name = node && node.properties ? node.properties["application.name"] : "";
        return String(name || (node ? node.name : "") || "Unknown");
    }

    function isMonitor(node: PwNode): bool {
        const name = String(node ? node.name : "").toLowerCase();
        const description = String(node ? node.description : "").toLowerCase();
        return name.indexOf("monitor") >= 0 || description.indexOf("monitor") >= 0;
    }

    // EasyEffects' own sink/source are routing plumbing for its effects chain,
    // not a device to pick — same reasoning as excluding monitors.
    function isEasyEffects(node: PwNode): bool {
        const name = String(node ? node.name : "").toLowerCase();
        return name.indexOf("easyeffects") >= 0 || name.indexOf("xps16_speaker_tuning") >= 0;
    }

    // Streams are individual applications and monitors are loopbacks of a sink;
    // neither is something to switch the default device to.
    function isOutput(node: PwNode): bool {
        return !!(node && node.audio && node.isSink && !node.isStream && !root.isMonitor(node) && !root.isEasyEffects(node));
    }

    function isInput(node: PwNode): bool {
        return !!(node && node.audio && !node.isSink && !node.isStream && !root.isMonitor(node) && !root.isEasyEffects(node));
    }

    function sorted(nodes: var): var {
        return nodes.slice().sort((left, right) => root.displayName(left).localeCompare(root.displayName(right)));
    }

    function showOsd(): void {
        if (!root.sink || !root.sink.audio)
            return;

        root.osdOpen = true;
        osdTimer.restart();
    }

    // Volume and mute are only readable while the node is bound.
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // Any volume change shows the OSD, including ones from keybinds outside the
    // shell — that is the point of it.
    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null

        function onVolumesChanged(): void {
            root.showOsd();
        }

        function onMutedChanged(): void {
            root.showOsd();
        }
    }

    Timer {
        id: osdTimer

        interval: 1100
        onTriggered: root.osdOpen = false
    }
}
