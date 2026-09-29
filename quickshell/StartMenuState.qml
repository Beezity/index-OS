// WILL OF THE CITY :: THE INDEX — global launcher IPC router
// Bar instances use unique per-output IPC targets. The public `startmenu`
// target chooses the screen containing the active application, falling back to
// the logical main display (0,0), so Super+Space opens only one launcher.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    function targetScreenName() {
        var active = ToplevelManager.activeToplevel
        if (active && active.screens && active.screens.length > 0 && active.screens[0])
            return active.screens[0].name

        var screens = Quickshell.screens || []
        for (var i = 0; i < screens.length; i++)
            if (screens[i].x === 0 && screens[i].y === 0) return screens[i].name
        return screens.length > 0 ? screens[0].name : ""
    }

    function dispatch(action) {
        var name = targetScreenName()
        if (name === "") return
        Quickshell.execDetached(["qs", "ipc", "call", "startmenu-" + name, action])
    }

    IpcHandler {
        target: "startmenu"
        function toggle(): void { root.dispatch("toggle") }
        function open(): void { root.dispatch("open") }
        function close(): void { root.dispatch("close") }
    }
}
