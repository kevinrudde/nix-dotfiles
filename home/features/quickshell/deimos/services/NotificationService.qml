pragma Singleton

// The notification server plus the two views on it: short-lived toasts and the
// grouped notification centre.
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs

Singleton {
    id: root

    property bool dnd: false

    // Toasts are a separate list from the tracked notifications: they expire on
    // their own while the notification stays in the centre.
    property var toasts: []
    property var toastDeadlines: ({})

    // Group key -> true. Absent means collapsed.
    property var expandedGroups: ({})

    // Notification id -> the time it arrived. The freedesktop protocol gives
    // us no such field, so the centre has to stamp it itself, on the way in.
    property var receivedAt: ({})

    // Live filter for the centre's search field. Applied in `groups` below so
    // a query narrows the same list the cards render from, not a separate copy.
    property string searchQuery: ""

    readonly property int count: server.trackedNotifications ? server.trackedNotifications.values.length : 0

    readonly property string icon: root.dnd
        ? (root.count > 0 ? Theme.iconBellDnd : Theme.iconBellDndEmpty)
        : (root.count > 0 ? Theme.iconBell : Theme.iconBellEmpty)

    readonly property string label: root.count > 0 ? root.count + " " + root.icon : root.icon

    // Toasts are rendered from a ScriptModel so the stack animates per item
    // instead of rebuilding whenever the list changes.
    readonly property alias toastModel: toastList

    readonly property var groups: {
        const all = server.trackedNotifications ? server.trackedNotifications.values : [];
        const query = root.searchQuery.trim().toLowerCase();
        const notifications = query === "" ? all : all.filter(notification => root.matches(notification, query));
        const byKey = {};
        const groups = [];

        for (const notification of notifications) {
            const key = root.groupKey(notification);
            let group = byKey[key];

            if (!group) {
                group = {
                    key: key,
                    appName: root.appName(notification),
                    critical: false,
                    latestId: 0,
                    notifications: []
                };
                byKey[key] = group;
                groups.push(group);
            }

            group.notifications.push(notification);
            group.latestId = Math.max(group.latestId, notification ? notification.id : 0);
            group.critical = group.critical || !!(notification && notification.urgency === NotificationUrgency.Critical);
        }

        // Critical first, then most recent activity first.
        groups.sort((left, right) => {
            if (left.critical !== right.critical)
                return left.critical ? -1 : 1;

            return right.latestId - left.latestId;
        });

        for (const group of groups)
            group.notifications = group.notifications.slice().sort((left, right) => (right ? right.id : 0) - (left ? left.id : 0));

        return groups;
    }

    // Matches app name, summary and body as one blob rather than field-by-field:
    // the search box has no way to scope a query, so it should find a word
    // wherever it appears.
    function matches(notification: var, query: string): bool {
        if (!notification)
            return false;

        const haystack = [root.appName(notification), notification.summary, notification.body].join(" ").toLowerCase();
        return haystack.includes(query);
    }

    // "12:43", stamped by `receivedAt` on arrival. Empty for a notification
    // this run never saw arrive (there is none — every tracked notification
    // passed through `onNotification` first).
    function timeLabel(notification: var): string {
        const ms = notification ? root.receivedAt[notification.id] : undefined;
        return ms ? Qt.formatDateTime(new Date(ms), "hh:mm") : "";
    }

    function appName(notification: var): string {
        const name = notification ? String(notification.appName || "").trim() : "";
        if (name !== "")
            return name;

        const entry = notification ? String(notification.desktopEntry || "").trim() : "";
        if (entry !== "")
            return entry;

        return "Notifications";
    }

    // Desktop entry over app name: the same application can announce itself
    // under different names between notifications.
    function groupKey(notification: var): string {
        const entry = notification ? String(notification.desktopEntry || "").trim().toLowerCase() : "";
        if (entry !== "")
            return entry;

        return root.appName(notification).toLowerCase();
    }

    function timeout(notification: var): int {
        if (!notification)
            return 6000;
        if (notification.expireTimeout > 0)
            return Math.max(1000, notification.expireTimeout);
        if (notification.urgency === NotificationUrgency.Critical)
            return 10000;
        if (notification.urgency === NotificationUrgency.Low)
            return 4000;

        return 6000;
    }

    function addToast(notification: var): void {
        const deadlines = Object.assign({}, root.toastDeadlines);
        deadlines[notification.id] = Date.now() + root.timeout(notification);
        root.toastDeadlines = deadlines;

        // Appended, not unshifted: an existing toast must never change
        // position just because a new one arrived. Unshifting pushed every
        // visible toast down a slot on each new arrival, so a click timed
        // against what was on screen a moment ago could land on whatever
        // had just slid into that spot instead — clicking one notification
        // and triggering a different one's action. Capping from the front
        // (oldest first) keeps the same "4 most recent" behaviour without
        // that reshuffle.
        const next = root.toasts.filter(item => item !== notification);
        next.push(notification);
        root.toasts = next.slice(-4);
    }

    function removeToast(notification: var): void {
        root.toasts = root.toasts.filter(item => item !== notification);
    }

    function dismiss(notification: var): void {
        if (!notification)
            return;

        root.removeToast(notification);
        notification.dismiss();
    }

    function dismissGroup(group: var): void {
        const notifications = group && group.notifications ? group.notifications.slice() : [];

        for (const notification of notifications)
            root.dismiss(notification);

        if (group && group.key)
            root.setGroupExpanded(group.key, false);
    }

    function clear(): void {
        for (const notification of Array.from(server.trackedNotifications.values))
            notification.dismiss();

        root.toasts = [];
        Popups.close();
    }

    function toggleDnd(): void {
        root.dnd = !root.dnd;
        root.toasts = [];
    }

    function groupExpanded(key: string): bool {
        return !!(key && root.expandedGroups[key]);
    }

    function setGroupExpanded(key: string, expanded: bool): void {
        if (!key)
            return;

        const next = Object.assign({}, root.expandedGroups);

        if (expanded)
            next[key] = true;
        else
            delete next[key];

        root.expandedGroups = next;
    }

    function toggleGroup(group: var): void {
        if (!group || !group.notifications || group.notifications.length < 2)
            return;

        root.setGroupExpanded(group.key, !root.groupExpanded(group.key));
    }

    NotificationServer {
        id: server

        actionsSupported: true
        actionIconsSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: false
        bodySupported: true
        imageSupported: true
        inlineReplySupported: false
        keepOnReload: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const times = Object.assign({}, root.receivedAt);
            times[notification.id] = Date.now();
            root.receivedAt = times;

            notification.closed.connect(function () {
                root.removeToast(notification);

                const next = Object.assign({}, root.receivedAt);
                delete next[notification.id];
                root.receivedAt = next;
            });

            if (!root.dnd)
                root.addToast(notification);
        }
    }

    ScriptModel {
        id: toastList

        values: root.toasts
    }

    // Expiry is swept centrally rather than per card so a toast that is added
    // while another is expiring does not reset anyone else's timer.
    Timer {
        interval: 500
        repeat: true
        running: true

        onTriggered: {
            const now = Date.now();
            root.toasts = root.toasts.filter(notification => (root.toastDeadlines[notification.id] || 0) > now);
        }
    }

    // Collapsing on close: an expanded group left over from last time is
    // disorienting when the centre is reopened.
    Connections {
        target: Popups

        function onNameChanged(): void {
            if (Popups.name !== "notifications") {
                root.expandedGroups = ({});
                root.searchQuery = "";
            }
        }
    }
}
