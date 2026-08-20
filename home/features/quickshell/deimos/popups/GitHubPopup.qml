import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.widgets

// Two lists, in the order that matches who is waiting on what: reviews
// requested from you block someone else, PRs assigned to you only block
// yourself. A third, collapsed by default, catches requests routed to a team
// you belong to rather than to you by name — real, but not yet specifically
// yours the way the other two are.
BarPopup {
    id: root

    popupName: "github"
    body: surface

    PopupSurface {
        id: surface

        surfaceWidth: 380

        SectionHeader {
            width: parent.width
            title: "GitHub"

            TextButton {
                text: "refresh"
                onClicked: GitHubInfo.refresh()
            }
        }

        EmptyHint {
            width: parent.width
            visible: GitHubInfo.state !== "ready"
            text: GitHubInfo.message !== "" ? GitHubInfo.message : "Loading…"
        }

        Column {
            width: parent.width
            visible: GitHubInfo.state === "ready"
            spacing: Theme.popupSpacing

            Caption {
                width: parent.width
                label: "Review requests"
            }

            EmptyHint {
                width: parent.width
                visible: GitHubInfo.reviewRequests.length === 0
                text: "Nobody is waiting on you"
            }

            Repeater {
                model: GitHubInfo.reviewRequests

                ListRow {
                    required property var modelData

                    width: parent.width
                    minHeight: 34
                    icon: GitHubInfo.checkIcon(modelData.checks)
                    iconColor: GitHubInfo.checkColor(modelData.checks)
                    title: "#" + modelData.number + " " + modelData.title
                    detail: modelData.repository + " · " + GitHubInfo.ageText(modelData.createdAt)
                    onActivated: {
                        Actions.openUrl(modelData.url);
                        Popups.close();
                    }
                }
            }

            Expander {
                id: teamReviewExpander

                width: parent.width
                visible: GitHubInfo.teamReviewCount > 0

                header: [
                    StyledText {
                        text: Theme.iconPullRequest
                        color: Theme.muted
                        font.pixelSize: Theme.fontSizeNormal
                    },
                    StyledText {
                        Layout.fillWidth: true
                        text: "Team review requests"
                        color: Theme.muted
                        elide: Text.ElideRight
                    },
                    StyledText {
                        text: GitHubInfo.teamReviewCount + (teamReviewExpander.expanded ? " · less" : " · more")
                        color: Theme.muted
                        font.bold: false
                        font.pixelSize: Theme.fontSizeTiny
                    }
                ]

                Repeater {
                    model: GitHubInfo.teamReviewRequests

                    ListRow {
                        required property var modelData

                        width: parent.width
                        minHeight: 34
                        icon: GitHubInfo.checkIcon(modelData.checks)
                        iconColor: GitHubInfo.checkColor(modelData.checks)
                        title: "#" + modelData.number + " " + modelData.title
                        detail: modelData.repository + " · " + GitHubInfo.ageText(modelData.createdAt)
                        onActivated: {
                            Actions.openUrl(modelData.url);
                            Popups.close();
                        }
                    }
                }
            }

            Divider {}

            Caption {
                width: parent.width
                label: "Assigned to you"
            }

            EmptyHint {
                width: parent.width
                visible: GitHubInfo.assignedPullRequests.length === 0
                text: "No pull requests assigned"
            }

            Repeater {
                model: GitHubInfo.assignedPullRequests

                ListRow {
                    required property var modelData

                    width: parent.width
                    minHeight: 34
                    icon: GitHubInfo.checkIcon(modelData.checks)
                    iconColor: GitHubInfo.checkColor(modelData.checks)
                    title: "#" + modelData.number + " " + modelData.title
                    detail: modelData.repository + " · " + GitHubInfo.ageText(modelData.createdAt) + (modelData.draft ? " · draft" : "")
                    onActivated: {
                        Actions.openUrl(modelData.url);
                        Popups.close();
                    }
                }
            }
        }
    }
}
