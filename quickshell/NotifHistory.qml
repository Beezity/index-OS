// WILL OF THE CITY :: THE INDEX — notification history (singleton)
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property var items: []          // newest first
    readonly property int maxItems: 60

    function clean(value, maxChars) {
        var text = value === undefined || value === null ? "" : String(value)
        if (text.length <= maxChars) return text
        return text.slice(0, Math.max(0, maxChars - 3)) + "..."
    }

    function add(app, summary, body, critical) {
        var list = root.items.slice()
        list.unshift({
            app: root.clean(app || "SYSTEM", 128),
            summary: root.clean(summary || "", 512),
            body: root.clean(body || "", 4096),
            critical: critical === true,
            time: Qt.formatDateTime(new Date(), "hh:mm")
        })
        if (list.length > root.maxItems) list = list.slice(0, root.maxItems)
        root.items = list
    }

    function clear() {
        root.items = []
    }
}
