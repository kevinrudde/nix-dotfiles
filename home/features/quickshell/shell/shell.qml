//@ pragma UseQApplication

import Quickshell
import qs.bar
import qs.notifications
import qs.osd
import qs.services

// Entry point. Everything visible lives in bar/, popups/, notifications/ and
// osd/; state and data live in services/, and all design tokens in Theme.qml.
ShellRoot {
    // One bar and one toast overlay per monitor.
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        ToastLayer {}
    }

    // Only built while a volume change is on screen.
    LazyLoader {
        active: Audio.osdOpen

        VolumeOsd {}
    }
}
