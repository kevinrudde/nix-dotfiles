import qs
import qs.services
import qs.widgets

// Collapses the right-hand group down to bare icons. Shared across monitors so
// both bars stay in the same shape.
Pill {
    text: BarState.expanded ? ">" : "<"
    horizontalPadding: Theme.pillPadCompact
    maxTextWidth: 14
    onClicked: BarState.expanded = !BarState.expanded
}
