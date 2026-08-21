pragma Singleton

// Which bar popup is open, and on which screen. Exactly one at a time: every
// widget asks here instead of clearing its neighbours' flags, so adding a popup
// no longer means touching every other widget.
import Quickshell

Singleton {
    id: root

    // Empty means nothing is open.
    property string name: ""
    property var screen: null

    function isOpen(popupName: string, popupScreen: var): bool {
        return root.name === popupName && root.screen === popupScreen;
    }

    function open(popupName: string, popupScreen: var): void {
        root.screen = popupScreen;
        root.name = popupName;
    }

    function toggle(popupName: string, popupScreen: var): void {
        if (root.isOpen(popupName, popupScreen))
            root.close();
        else
            root.open(popupName, popupScreen);
    }

    function close(): void {
        root.name = "";
        root.screen = null;
    }

    // Used by a popup window that lost its surface: only the owner may clear
    // the shared state, otherwise a stale window closes its successor.
    function closeIf(popupName: string, popupScreen: var): void {
        if (root.isOpen(popupName, popupScreen))
            root.close();
    }
}
