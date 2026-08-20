import QtQuick
import qs
import qs.popups
import qs.services
import qs.widgets

// Pull requests waiting on you: reviews requested from you, and PRs assigned
// to you. The count rides on the icon's corner, the same convention
// NotificationWidget's bell follows — see BadgedIcon.qml.
Pill {
    id: root

    required property var barScreen

    readonly property color tint: GitHubInfo.urgent ? Theme.warning : (GitHubInfo.totalCount > 0 ? Theme.primary : Theme.muted)

    text: ""
    horizontalPadding: Theme.pillPadIcon
    minPillWidth: 0
    implicitWidth: pulls.implicitWidth + root.horizontalPadding * 2
    tooltip: GitHubInfo.totalCount > 0
        ? GitHubInfo.reviewCount + " review requests · " + GitHubInfo.assignedCount + " assigned PRs"
        : "No pull requests waiting"

    onClicked: Popups.toggle("github", root.barScreen)

    BadgedIcon {
        id: pulls

        anchors.centerIn: parent
        icon: Theme.iconPullRequest
        count: GitHubInfo.totalCount
        color: root.tint
        surface: root.hovered ? Theme.barHoverSolid : Theme.barBackground
    }

    GitHubPopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
