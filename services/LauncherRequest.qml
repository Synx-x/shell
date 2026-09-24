pragma Singleton

import Quickshell

// Hands a search string from the launcher IPC to the launcher on the focused screen.
Singleton {
    property string pendingText: ""
    property string currentText: ""

    signal requested
}
