import QtQuick
import QtQuick.Layouts
import qs
import qs.popups
import qs.services
import qs.widgets

// Pull requests waiting on you: reviews requested from you, and PRs assigned
// to you. The count is always shown — the same convention NotificationWidget's
// bell follows, including keeping it and the icon as two separately-centred
// items in a RowLayout rather than one combined string in a plain Row — see
// CenteredGlyph.qml and NotificationWidget.qml for why each of those matters.
Pill {
    id: root

    required property var barScreen

    readonly property color tint: GitHubInfo.urgent ? Theme.warning : (GitHubInfo.totalCount > 0 ? Theme.primary : Theme.muted)

    text: ""
    horizontalPadding: Theme.pillPadIcon
    minPillWidth: 0
    implicitWidth: contentRow.implicitWidth + root.horizontalPadding * 2
    tooltip: GitHubInfo.totalCount > 0
        ? GitHubInfo.reviewCount + " review requests · " + GitHubInfo.assignedCount + " assigned PRs"
        : "No pull requests waiting"

    onClicked: Popups.toggle("github", root.barScreen)

    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: 4

        CenteredGlyph {
            Layout.alignment: Qt.AlignVCenter
            visible: GitHubInfo.totalCount > 0
            text: String(GitHubInfo.totalCount)
            font.pixelSize: Theme.fontSizeSmall
            color: root.tint
        }

        CenteredGlyph {
            Layout.alignment: Qt.AlignVCenter
            text: Theme.iconPullRequest
            color: root.tint
        }
    }

    GitHubPopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
