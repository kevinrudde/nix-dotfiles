pragma Singleton

// Token usage from Claude Code's own local session transcripts, plus the
// real rate-limit percentages from Anthropic's OAuth usage endpoint — the
// same one Claude Code's own client reads. Read-only: the access token in
// `.credentials.json` is only ever read here, never refreshed or written
// back. An expired token degrades to "Sign-in expired" plus whatever the
// last successful probe cached, not a guess.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Set by the popup: true only while it is open, the same convention
    // WifiStats uses — a full transcript scan is cheap but still not worth
    // repeating on a timer nobody is looking at.
    property bool watching: false

    property var byDay: []
    property var byModel: []
    // {tokens, messages, startedAt, resetsAt, active} or null once there is
    // any usage at all in the scanned window.
    property var session: null

    // Server-side rate limits: [{label, percent, resetsAt}], oldest-first as
    // the script emits them (session window, then weekly, then any
    // model-scoped window). Empty while unauthenticated, degraded, or not
    // yet fetched — never filled with a guess.
    property var limits: []
    property string tierLabel: ""
    // Set only when something is off (no auth, expired auth, fetch
    // failure) so the popup has a one-line reason to show next to
    // whatever cached limits it still has, if any.
    property string usageStatusText: ""
    property string authHelpText: ""

    readonly property int maxDayTokens: root.byDay.reduce((max, day) => Math.max(max, day.tokens), 0)
    readonly property int maxModelTokens: root.byModel.reduce((max, entry) => Math.max(max, entry.tokens), 0)

    function refresh(): void {
        if (!fetchProcess.running)
            fetchProcess.running = true;
    }

    function apply(raw: string): void {
        try {
            const data = JSON.parse(raw);
            root.byDay = Array.isArray(data.byDay) ? data.byDay : [];
            root.byModel = Array.isArray(data.byModel) ? data.byModel : [];
            root.session = data.session || null;
            root.limits = Array.isArray(data.limits) ? data.limits : [];
            root.tierLabel = String(data.tierLabel || "");
            root.usageStatusText = String(data.usageStatusText || "");
            root.authHelpText = String(data.authHelpText || "");
        } catch (error) {
            root.byDay = [];
            root.byModel = [];
            root.session = null;
            root.limits = [];
            root.tierLabel = "";
            root.usageStatusText = "";
            root.authHelpText = "";
        }
    }

    // "claude-opus-4-8" -> "Opus 4.8", "claude-haiku-4-5-20251001" -> "Haiku
    // 4.5". The family name is the first segment; version numbers are the
    // short numeric segments right after it, stopped by the first segment
    // that is not a plausible version component (a release-date suffix is
    // eight digits, a version component never is).
    function friendlyModelName(raw: string): string {
        if (!raw || raw === "<synthetic>")
            return "Other";

        const parts = String(raw).replace(/^claude-/, "").split("-");
        if (parts.length === 0)
            return raw;

        const family = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
        const version = [];

        for (let i = 1; i < parts.length; i++) {
            if (!/^\d{1,2}$/.test(parts[i]))
                break;
            version.push(parts[i]);
        }

        return version.length > 0 ? family + " " + version.join(".") : family;
    }

    function formatTokens(tokens: real): string {
        const value = Math.max(0, Number(tokens) || 0);

        if (value >= 1e9)
            return (value / 1e9).toFixed(1) + "B";
        if (value >= 1e6)
            return (value / 1e6).toFixed(1) + "M";
        if (value >= 1e3)
            return (value / 1e3).toFixed(1) + "K";

        return String(Math.round(value));
    }

    // "Today"/"Yesterday" read faster than a repeated year in a 7-day list;
    // anything older falls back to a short weekday name.
    function dayLabel(dateString: string): string {
        const date = new Date(dateString + "T00:00:00");
        const today = new Date();
        const todayString = today.toISOString().slice(0, 10);

        if (dateString === todayString)
            return "Today";

        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);
        if (dateString === yesterday.toISOString().slice(0, 10))
            return "Yesterday";

        return date.toLocaleDateString(Qt.locale(), "ddd");
    }

    // A block only means "the current session" while it is still within its
    // own 5-hour window — once that has elapsed with nothing to replace it
    // (no message sent since), it is just the last thing that happened, not
    // an active session.
    readonly property bool sessionActive: !!(root.session && root.session.active)

    function minutesUntil(isoTime: string): int {
        const target = Date.parse(isoTime);
        if (!isFinite(target))
            return 0;

        return Math.max(0, Math.round((target - Date.now()) / 60000));
    }

    function formatDuration(minutes: int): string {
        const hours = Math.floor(minutes / 60);
        const remainder = minutes % 60;

        if (hours <= 0)
            return remainder + "m";

        return hours + "h " + remainder + "m";
    }

    Process {
        id: fetchProcess

        command: [Quickshell.shellDir + "/scripts/claude-usage.sh", "7"]

        stdout: StdioCollector {
            onStreamFinished: root.apply(this.text)
        }
    }

    // Once at startup regardless of `watching`, so the bar pill's own
    // tooltip has real numbers to show even before the popup is ever
    // opened — only the recurring refresh below is worth gating.
    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.watching
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
