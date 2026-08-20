import qs
import qs.popups
import qs.services
import qs.widgets

// Token usage from Claude Code's own local session transcripts — no plan
// quota percentage, since nothing on this machine knows what that quota is.
Pill {
    id: root

    required property var barScreen

    text: Theme.iconClaude
    foreground: Theme.claudeAccent
    horizontalPadding: Theme.pillPadIcon
    tooltip: ClaudeUsage.sessionActive
        ? ClaudeUsage.formatTokens(ClaudeUsage.session.tokens) + " tokens this session"
        : (ClaudeUsage.byDay.length > 0 ? ClaudeUsage.formatTokens(ClaudeUsage.byDay[ClaudeUsage.byDay.length - 1].tokens) + " tokens today" : "Claude Code usage")

    onClicked: Popups.toggle("claude-usage", root.barScreen)

    ClaudeUsagePopup {
        anchorItem: root
        popupScreen: root.barScreen
    }
}
