import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.widgets

// Local token usage plus real server-side rate limits, read-only against
// the existing Claude Code sign-in — see ClaudeUsage.qml.
BarPopup {
    id: root

    popupName: "claude-usage"
    body: surface

    // A full transcript scan is cheap, but still not worth repeating on a
    // timer while nobody has this open.
    onOpenChanged: ClaudeUsage.watching = root.open

    PopupSurface {
        id: surface

        surfaceWidth: 360

        RowLayout {
            width: parent.width
            spacing: 10

            StyledText {
                text: Theme.iconClaude
                color: Theme.claudeAccent
                font.pixelSize: Theme.fontSizeDisplay
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: "Claude Code"
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeLarge
                }

                StyledText {
                    visible: ClaudeUsage.tierLabel !== ""
                    text: ClaudeUsage.tierLabel.toUpperCase()
                    color: Theme.muted
                    font.bold: true
                    font.pixelSize: Theme.fontSizeTiny
                    font.letterSpacing: 1
                }
            }
        }

        Divider {}

        Column {
            width: parent.width
            spacing: Theme.popupSpacing

            Caption {
                width: parent.width
                label: "Limits"
            }

            EmptyHint {
                width: parent.width
                visible: ClaudeUsage.limits.length === 0 && ClaudeUsage.usageStatusText === ""
                text: "No limits available"
            }

            StyledText {
                width: parent.width
                visible: ClaudeUsage.usageStatusText !== ""
                text: ClaudeUsage.usageStatusText
                color: Theme.muted
                font.bold: true
                font.pixelSize: Theme.fontSizeTiny
            }

            StyledText {
                width: parent.width
                visible: ClaudeUsage.usageStatusText !== "" && ClaudeUsage.authHelpText !== ""
                text: ClaudeUsage.authHelpText
                wrapMode: Text.WordWrap
                color: Theme.muted
                font.bold: false
                font.pixelSize: Theme.fontSizeTiny
            }

            Repeater {
                model: ClaudeUsage.limits

                ColumnLayout {
                    required property var modelData

                    width: parent.width
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.label
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: modelData.percent + "%"
                            color: Theme.muted
                            font.bold: false
                        }
                    }

                    ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        percent: Theme.clampPercent(modelData.percent)
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: (modelData.resetsAt ?? "") !== ""
                        text: "Resets in " + ClaudeUsage.formatDuration(ClaudeUsage.minutesUntil(modelData.resetsAt))
                        color: Theme.muted
                        font.bold: false
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }
            }
        }

        Divider {}

        Column {
            width: parent.width
            visible: ClaudeUsage.session !== null
            spacing: 3

            Caption {
                width: parent.width
                label: "Current session"
            }

            EmptyHint {
                width: parent.width
                visible: !ClaudeUsage.sessionActive
                text: "No active session"
            }

            StyledText {
                width: parent.width
                visible: ClaudeUsage.sessionActive
                text: ClaudeUsage.session ? ClaudeUsage.formatTokens(ClaudeUsage.session.tokens) + " tokens · " + ClaudeUsage.session.messages + " messages" : ""
            }

            StyledText {
                width: parent.width
                visible: ClaudeUsage.sessionActive
                text: ClaudeUsage.session ? "Resets in " + ClaudeUsage.formatDuration(ClaudeUsage.minutesUntil(ClaudeUsage.session.resetsAt)) : ""
                color: Theme.muted
                font.bold: false
                font.pixelSize: Theme.fontSizeTiny
            }
        }

        Divider {
            visible: ClaudeUsage.session !== null
        }

        Column {
            width: parent.width
            spacing: Theme.popupSpacing

            Caption {
                width: parent.width
                label: "Tokens by day"
            }

            EmptyHint {
                width: parent.width
                visible: ClaudeUsage.byDay.length === 0
                text: "No usage in the last 7 days"
            }

            Repeater {
                model: ClaudeUsage.byDay

                RowLayout {
                    required property var modelData

                    readonly property string label: ClaudeUsage.dayLabel(modelData.date)

                    width: parent.width
                    height: 20
                    spacing: 8

                    StyledText {
                        Layout.preferredWidth: 56
                        text: label
                        font.bold: label === "Today"
                    }

                    ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        percent: ClaudeUsage.maxDayTokens > 0 ? Theme.clampPercent(modelData.tokens / ClaudeUsage.maxDayTokens * 100) : 0
                    }

                    StyledText {
                        Layout.preferredWidth: 56
                        horizontalAlignment: Text.AlignRight
                        text: ClaudeUsage.formatTokens(modelData.tokens)
                        color: Theme.muted
                        font.bold: false
                    }
                }
            }
        }

        Divider {}

        Column {
            width: parent.width
            spacing: Theme.popupSpacing

            Caption {
                width: parent.width
                label: "Tokens by model"
            }

            EmptyHint {
                width: parent.width
                visible: ClaudeUsage.byModel.length === 0
                text: "No usage in the last 7 days"
            }

            Repeater {
                model: ClaudeUsage.byModel

                Rectangle {
                    required property var modelData

                    width: parent.width
                    height: Theme.rowHeight
                    color: Theme.background
                    radius: Theme.rowRadius
                    clip: true

                    Rectangle {
                        width: parent.width * (ClaudeUsage.maxModelTokens > 0 ? modelData.tokens / ClaudeUsage.maxModelTokens : 0)
                        height: parent.height
                        radius: parent.radius
                        color: Theme.activeBackground
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        StyledText {
                            Layout.fillWidth: true
                            text: ClaudeUsage.friendlyModelName(modelData.model)
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: ClaudeUsage.formatTokens(modelData.tokens)
                            color: Theme.muted
                            font.bold: false
                        }
                    }
                }
            }
        }
    }
}
