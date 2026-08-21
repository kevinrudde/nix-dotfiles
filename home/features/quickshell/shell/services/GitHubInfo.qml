pragma Singleton

// Pull requests that need a decision from you — nothing else. No
// notifications, no repository browser: those belong to a different tool at a
// different urgency. Fetched through a script because the GitHub search API
// and its pagination are a poor fit for QML, and because gh already owns the
// credentials.
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    property string state: "loading"
    property string message: ""
    property var reviewRequests: []
    property var teamReviewRequests: []
    property var assignedPullRequests: []
    property var warnings: []

    readonly property int reviewCount: root.reviewRequests.length
    readonly property int teamReviewCount: root.teamReviewRequests.length
    readonly property int assignedCount: root.assignedPullRequests.length
    // The team list is folded in behind an expander rather than counted here:
    // it is real work, but a request routed to five people is not yet
    // specifically yours the way a direct request or an assignment is.
    readonly property int totalCount: root.reviewCount + root.assignedCount
    // A review someone else is waiting on blocks a second person's work, not
    // just yours — that is worth a louder colour than a PR merely assigned to
    // you.
    readonly property bool urgent: root.reviewCount > 0

    // StatusCheckRollup groupings live here so a row's icon, colour and the
    // urgency they imply cannot drift apart when a state is reclassified.
    function isBrokenCheck(checks: string): bool {
        return checks === "FAILURE" || checks === "ERROR";
    }

    function isRunningCheck(checks: string): bool {
        return checks === "PENDING" || checks === "EXPECTED";
    }

    function checkIcon(checks: string): string {
        if (root.isBrokenCheck(checks))
            return Theme.iconChecksFailed;
        if (root.isRunningCheck(checks))
            return Theme.iconChecksRunning;
        if (checks === "SUCCESS")
            return Theme.iconChecksSuccess;

        // NONE (no workflows configured) and null both fall back to the plain
        // pull request glyph — neither is a check result worth a colour.
        return Theme.iconPullRequest;
    }

    function checkColor(checks: string): color {
        if (root.isBrokenCheck(checks))
            return Theme.danger;
        if (root.isRunningCheck(checks))
            return Theme.warning;
        if (checks === "SUCCESS")
            return Theme.success;

        return Theme.primary;
    }

    // Coarse on purpose: this is a subtext under a title, not a precise
    // timestamp, so it only ever carries one unit.
    function ageText(createdAt: string): string {
        const created = Date.parse(createdAt);
        if (!isFinite(created))
            return "";

        const days = Math.floor((Date.now() - created) / 86400000);
        if (days < 1)
            return "today";
        if (days < 30)
            return days + "d";

        const months = Math.floor(days / 30);
        if (months < 12)
            return months + "mo";

        return Math.floor(months / 12) + "y";
    }

    function refresh(): void {
        if (fetchProcess.running)
            return;

        fetchProcess.running = true;
    }

    function apply(raw: string): void {
        try {
            const data = JSON.parse(raw);
            root.state = String(data.state || "error");
            root.message = String(data.message || "");
            root.reviewRequests = Array.isArray(data.reviewRequests) ? data.reviewRequests : [];
            root.teamReviewRequests = Array.isArray(data.teamReviewRequests) ? data.teamReviewRequests : [];
            root.assignedPullRequests = Array.isArray(data.assignedPullRequests) ? data.assignedPullRequests : [];
            root.warnings = Array.isArray(data.warnings) ? data.warnings : [];
        } catch (error) {
            root.state = "error";
            root.message = "GitHub returned an unreadable response.";
        }
    }

    Process {
        id: fetchProcess

        command: [Quickshell.shellDir + "/scripts/github-fetch.sh"]

        stdout: StdioCollector {
            onStreamFinished: root.apply(this.text)
        }
    }

    // Search API quota is tight enough that this has to stay a slow poll —
    // fifteen minutes, the same default the Omarchy GitHub widget ships with.
    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
