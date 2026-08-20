import qs
import qs.popups
import qs.services
import qs.widgets

// Pull requests waiting on you: reviews requested from you, and PRs assigned
// to you. The count is the point of this pill, so it shows regardless of
// BarState.expanded — the same convention NotificationWidget's bell follows.
Pill {
    id: root

    required property var barScreen

    text: GitHubInfo.totalCount > 0 ? GitHubInfo.totalCount + " " + Theme.iconPullRequest : Theme.iconPullRequest
    foreground: GitHubInfo.urgent ? Theme.warning : (GitHubInfo.totalCount > 0 ? Theme.primary : Theme.muted)
    horizontalPadding: BarState.expanded ? Theme.pillPad : Theme.pillPadCompact
    maxTextWidth: 40

    onClicked: Popups.toggle("github", root.barScreen)

    GitHubPopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
