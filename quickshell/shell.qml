//@ pragma UseQApplication
// ============================================================
//  WILL OF THE CITY :: THE INDEX — Quickshell entry point
//  Started by labwc/config/autostart.
//  The secure lock screen is launched separately by index-lock.
// ============================================================

import Quickshell
import "."

ShellRoot {
    // Force construction of the singleton that owns the public launcher IPC
    // endpoint. Individual bars register unique per-output targets.
    readonly property var launcherIpc: StartMenuState

    // Screen-local desktop surfaces are instantiated once per connected output.
    // Quickshell.screens updates automatically on hotplug/unplug.
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        Atmosphere {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        Prescript {
            required property var modelData
            screen: modelData
        }
    }

    // These remain single global services/popups.
    AboutPopup {}
    ClipboardPopup {}
    Notifications {}
    Osd {}
    DeviceWatch {}
}
