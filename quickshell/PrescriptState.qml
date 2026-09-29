// WILL OF THE CITY :: THE INDEX — shared Prescript of the Day state
// One singleton owns generation, caching and IPC so every monitor renders the
// same prescript and a reroll/close action is global.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

Singleton {
    id: root

    property bool open: true
    property var bank: ({})
    property string text_: ""
    property string dateKey: ""
    property int revision: 0

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache"
    readonly property string cachePath: cacheDir + "/index-prescript"
    readonly property string bankPath: Quickshell.env("HOME") + "/.config/quickshell/prescript.json"

    IpcHandler {
        target: "prescript"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
        function reroll(): void { root.reroll() }
    }

    function pick(name, fallback) {
        var a = root.bank[name]
        if (!a || a.length === 0) return fallback || ""
        return a[Math.floor(Math.random() * a.length)]
    }

    function clean(t) {
        if (!t) return ""
        return t.replace(/\s+/g, " ")
                .replace(/\s+([,.;:!?])/g, "$1")
                .replace(/([a-z])([A-Z])/g, "$1 $2")
                .trim()
    }

    function cap(t) {
        t = clean(t)
        return t === "" ? "" : t.charAt(0).toUpperCase() + t.slice(1)
    }

    function fill(t, depth) {
        if (!t) return ""
        if (depth === undefined) depth = 0
        if (depth > 4) return t.replace(/\{[^}]*\}/g, "")
        return t.replace(/\{([a-zA-Z0-9_]+)\}/g, function(m, name) {
            var v = root.pick(name, "")
            return v === "" ? "" : root.fill(v, depth + 1)
        })
    }

    function compose() {
        var t0 = fill(pick("task0", ""))
        var st = fill(pick("starter", ""))
        var t1 = fill(pick("task1", "walk somewhere"))
        var tr = fill(pick("transition", ""))
        var fu = fill(pick("followup", ""))
        var out = ""
        if (Math.random() < 0.5 && t0 !== "") out = clean(t0)
        if (Math.random() < 0.3 && st !== "") out = clean(out + " " + st)
        out = clean(out + " " + t1)
        if (tr !== "" && fu !== "" && Math.random() < 0.7)
            out = clean(out + tr + " " + fu)

        out = cap(out)
        if (!/[.!?]$/.test(out)) out += "."
        if (Math.random() < 0.45) {
            var f2 = cap(fill(pick("follow2up", "")))
            if (f2 !== "") {
                if (!/[.!?]$/.test(f2)) f2 += "."
                out += " " + f2
            }
        }
        return clean(out)
    }

    function todayKey() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd")
    }

    function save() {
        saveProc.command = [
            "sh", "-c",
            "mkdir -p \"$1\" && printf '%s\\n%s\\n' \"$2\" \"$3\" > \"$4\"",
            "sh", root.cacheDir, root.dateKey, root.text_, root.cachePath
        ]
        saveProc.running = true
    }

    function setPrescript(value, key, playSound) {
        root.dateKey = key
        root.text_ = value
        root.revision += 1
        root.save()
        if (playSound) Sfx.play("scramble")
    }

    function reroll() {
        if (!root.bank || Object.keys(root.bank).length === 0) return
        root.setPrescript(root.compose(), root.todayKey(), true)
    }

    function regenerateIfNeeded() {
        if (root.dateKey === root.todayKey() && root.text_ !== "") return
        if (!root.bank || Object.keys(root.bank).length === 0) return
        root.setPrescript(root.compose(), root.todayKey(), true)
    }

    Process { id: saveProc; command: ["true"] }

    Process {
        id: loadProc
        command: ["sh", "-c", "cat \"$1\" 2>/dev/null", "sh", root.cachePath]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                if (lines.length >= 2) {
                    root.dateKey = lines[0].trim()
                    root.text_ = lines.slice(1).join(" ").trim()
                    if (root.text_ !== "") root.revision += 1
                }
                root.regenerateIfNeeded()
            }
        }
    }

    Process {
        id: bankProc
        command: ["sh", "-c", "cat \"$1\" 2>/dev/null", "sh", root.bankPath]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                if (t === "") {
                    root.bank = ({})
                } else {
                    try { root.bank = JSON.parse(t) }
                    catch (e) { root.bank = ({}) }
                }
                loadProc.running = true
            }
        }
    }

    Component.onCompleted: bankProc.running = true

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.regenerateIfNeeded()
    }
}
