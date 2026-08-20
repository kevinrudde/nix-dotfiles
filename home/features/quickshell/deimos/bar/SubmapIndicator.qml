import qs
import qs.services
import qs.widgets

// Shows the active Hyprland submap. Invisible in the default submap, which is
// where the shell spends most of its time.
Pill {
    visible: Submap.name !== ""
    text: Submap.name
    foreground: Theme.success
    background: Theme.backgroundStrong
    maxTextWidth: 150
}
