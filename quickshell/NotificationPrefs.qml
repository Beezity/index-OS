// WILL OF THE CITY :: THE INDEX — notification preferences singleton
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool backendAvailable: false
    property bool ready: false
    property bool dnd: false
    property bool sounds: true
    property int timeoutMs: 6000

    function refresh() {
        if (!stateGet.running) stateGet.running = true
    }

    function runSetting(command) {
        Quickshell.execDetached(["sh", "-c", "exec \"$HOME/.local/bin/index-notifications\" " + command])
        actionRefresh.restart()
    }

    function setDnd(value) {
        root.dnd = value
        root.runSetting("set-dnd " + (value ? "yes" : "no"))
    }

    function setSounds(value) {
        root.sounds = value
        root.runSetting("set-sounds " + (value ? "yes" : "no"))
    }

    function setTimeoutMs(value) {
        var next = Math.round(value)
        if (next !== 0 && (next < 1000 || next > 60000)) return
        root.timeoutMs = next
        root.runSetting("set-timeout " + next)
    }

    Component.onCompleted: root.refresh()

    Process {
        id: stateGet
        command: ["sh", "-c", "exec \"$HOME/.local/bin/index-notifications\" state 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.replace(/[\r\n]+$/, "")
                var fields = line.split("\t")
                if (fields.length < 4 || (fields[0] !== "0" && fields[0] !== "1")) {
                    root.backendAvailable = false
                    root.ready = false
                    root.dnd = false
                    root.sounds = true
                    root.timeoutMs = 6000
                    return
                }

                var timeout = parseInt(fields[3])
                if (isNaN(timeout) || (timeout !== 0 && (timeout < 1000 || timeout > 60000))) {
                    root.backendAvailable = false
                    root.ready = false
                    root.dnd = false
                    root.sounds = true
                    root.timeoutMs = 6000
                    return
                }

                root.backendAvailable = fields[0] === "1"
                root.dnd = fields[1] === "yes"
                root.sounds = fields[2] === "yes"
                root.timeoutMs = timeout
                root.ready = true
            }
        }
    }

    Timer {
        id: actionRefresh
        interval: 300
        repeat: false
        onTriggered: root.refresh()
    }
}
