// WILL OF THE CITY :: THE INDEX — display settings subpanel
// Uses wlroots output management through wlr-randr. State is refreshed on
// open and after writes; there is no permanent output polling loop.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    signal requestBack()
    color: "transparent"

    readonly property string pixel: "Perfect DOS VGA 437 Universal"
    readonly property color cyan: "#5DADE2"
    readonly property color cyanB: "#85C5E8"
    readonly property color cyanD: "#3A7CA5"
    readonly property color warn: "#FF6B6B"
    readonly property string saveHelper: Quickshell.env("HOME") + "/.config/labwc/index-display-save"

    property var outputs: []
    property int selectedIndex: -1
    property string statusText: ""
    property bool backendAvailable: true

    property bool draftEnabled: true
    property int draftWidth: 0
    property int draftHeight: 0
    property real draftRefresh: 0
    property int draftX: 0
    property int draftY: 0
    property real draftScale: 1
    property string draftTransform: "normal"

    readonly property var scaleChoices: [1.0, 1.25, 1.5, 1.75, 2.0]
    readonly property var transformChoices: ["normal", "90", "180", "270"]

    function selectedOutput() {
        if (selectedIndex < 0 || selectedIndex >= outputs.length) return null
        return outputs[selectedIndex]
    }

    function parseState(raw) {
        var result = []
        var lines = raw.split(/\r?\n/)
        var current = null
        var readingModes = false
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line.length > 0 && !/^\s/.test(line)) {
                var h = line.match(/^(\S+)\s+"(.*)"$/)
                if (!h) h = line.match(/^(\S+)(?:\s+(.*))?$/)
                if (!h) continue
                current = {
                    name: h[1],
                    description: h[2] || h[1],
                    enabled: false,
                    x: 0,
                    y: 0,
                    scale: 1.0,
                    transform: "normal",
                    modes: []
                }
                result.push(current)
                readingModes = false
                continue
            }
            if (!current) continue
            var t = line.trim()
            if (t.indexOf("Enabled:") === 0) {
                current.enabled = t.slice(8).trim() === "yes"
                readingModes = false
            } else if (t === "Modes:") {
                readingModes = true
            } else if (readingModes) {
                var m = t.match(/^(\d+)x(\d+)\s+px(?:,\s*([0-9.]+)\s+Hz)?(?:\s+\(([^)]*)\))?$/)
                if (m) {
                    var flags = m[4] || ""
                    current.modes.push({
                        width: parseInt(m[1]),
                        height: parseInt(m[2]),
                        refresh: m[3] ? parseFloat(m[3]) : 0,
                        preferred: flags.indexOf("preferred") >= 0,
                        current: flags.indexOf("current") >= 0
                    })
                    continue
                }
                readingModes = false
            }
            if (t.indexOf("Position:") === 0) {
                var p = t.slice(9).trim().split(",")
                if (p.length === 2) {
                    current.x = parseInt(p[0]) || 0
                    current.y = parseInt(p[1]) || 0
                }
            } else if (t.indexOf("Transform:") === 0) {
                current.transform = t.slice(10).trim() || "normal"
            } else if (t.indexOf("Scale:") === 0) {
                var s = parseFloat(t.slice(6).trim())
                current.scale = isNaN(s) ? 1.0 : s
            }
        }
        return result
    }

    function currentMode(output) {
        if (!output) return null
        for (var i = 0; i < output.modes.length; i++)
            if (output.modes[i].current) return output.modes[i]
        for (var j = 0; j < output.modes.length; j++)
            if (output.modes[j].preferred) return output.modes[j]
        return output.modes.length > 0 ? output.modes[0] : null
    }

    function loadDraft() {
        var o = selectedOutput()
        if (!o) return
        var m = currentMode(o)
        draftEnabled = o.enabled
        draftWidth = m ? m.width : 0
        draftHeight = m ? m.height : 0
        draftRefresh = m ? m.refresh : 0
        draftX = o.x
        draftY = o.y
        draftScale = o.scale || 1.0
        draftTransform = o.transform || "normal"
    }

    function selectOutput(i) {
        if (i < 0 || i >= outputs.length) return
        selectedIndex = i
        loadDraft()
    }

    function resolutionChoices() {
        var o = selectedOutput()
        if (!o) return []
        var out = []
        var seen = ({})
        for (var i = 0; i < o.modes.length; i++) {
            var key = o.modes[i].width + "x" + o.modes[i].height
            if (!seen[key]) {
                seen[key] = true
                out.push({ width: o.modes[i].width, height: o.modes[i].height, label: key })
            }
        }
        return out
    }

    function refreshChoices() {
        var o = selectedOutput()
        if (!o) return []
        var out = []
        var seen = ({})
        for (var i = 0; i < o.modes.length; i++) {
            var m = o.modes[i]
            if (m.width !== draftWidth || m.height !== draftHeight || m.refresh <= 0) continue
            var key = m.refresh.toFixed(3)
            if (!seen[key]) {
                seen[key] = true
                out.push(m.refresh)
            }
        }
        out.sort(function(a, b) { return b - a })
        return out
    }

    function cycleResolution(step) {
        var choices = resolutionChoices()
        if (choices.length === 0) return
        var idx = 0
        for (var i = 0; i < choices.length; i++)
            if (choices[i].width === draftWidth && choices[i].height === draftHeight) { idx = i; break }
        idx = (idx + step + choices.length) % choices.length
        draftWidth = choices[idx].width
        draftHeight = choices[idx].height
        var rates = refreshChoices()
        if (rates.length > 0) draftRefresh = rates[0]
    }

    function cycleRefresh(step) {
        var choices = refreshChoices()
        if (choices.length === 0) return
        var idx = 0
        var best = 999
        for (var i = 0; i < choices.length; i++) {
            var d = Math.abs(choices[i] - draftRefresh)
            if (d < best) { best = d; idx = i }
        }
        idx = (idx + step + choices.length) % choices.length
        draftRefresh = choices[idx]
    }

    function cycleScale(step) {
        var idx = 0
        var best = 999
        for (var i = 0; i < scaleChoices.length; i++) {
            var d = Math.abs(scaleChoices[i] - draftScale)
            if (d < best) { best = d; idx = i }
        }
        idx = (idx + step + scaleChoices.length) % scaleChoices.length
        draftScale = scaleChoices[idx]
    }

    function cycleTransform(step) {
        var idx = transformChoices.indexOf(draftTransform)
        if (idx < 0) idx = 0
        idx = (idx + step + transformChoices.length) % transformChoices.length
        draftTransform = transformChoices[idx]
    }

    function enabledCount() {
        var n = 0
        for (var i = 0; i < outputs.length; i++) if (outputs[i].enabled) n++
        return n
    }

    function applySelected() {
        var o = selectedOutput()
        if (!o || applyProc.running) return
        if (!draftEnabled && o.enabled && enabledCount() <= 1) {
            statusText = "CANNOT DISABLE THE LAST ACTIVE DISPLAY"
            return
        }
        var args = ["wlr-randr", "--output", o.name]
        if (!draftEnabled) {
            args.push("--off")
        } else {
            args.push("--on")
            if (draftWidth > 0 && draftHeight > 0) {
                var mode = draftWidth + "x" + draftHeight
                if (draftRefresh > 0) mode += "@" + draftRefresh.toFixed(3) + "Hz"
                args.push("--mode", mode)
            } else {
                args.push("--preferred")
            }
            args.push("--pos", draftX + "," + draftY)
            args.push("--scale", draftScale.toFixed(2))
            args.push("--transform", draftTransform)
        }
        statusText = "APPLYING..."
        applyProc.exec(args)
    }

    function setMain() {
        var selected = selectedOutput()
        if (!selected || !selected.enabled || mainProc.running) return
        var dx = selected.x
        var dy = selected.y
        var args = ["wlr-randr"]
        for (var i = 0; i < outputs.length; i++) {
            var o = outputs[i]
            if (!o.enabled) continue
            args.push("--output", o.name, "--pos", (o.x - dx) + "," + (o.y - dy))
        }
        statusText = "SETTING MAIN DISPLAY..."
        mainProc.exec(args)
    }

    function refresh() {
        if (!stateProc.running) {
            statusText = "READING OUTPUTS..."
            stateProc.running = true
        }
    }

    Component.onCompleted: if (visible) refresh()
    onVisibleChanged: if (visible) refresh()

    Process {
        id: stateProc
        command: ["wlr-randr"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parsed = root.parseState(text)
                root.backendAvailable = parsed.length > 0
                root.outputs = parsed
                if (parsed.length === 0) {
                    root.selectedIndex = -1
                    root.statusText = "WLR OUTPUT BACKEND UNAVAILABLE"
                } else {
                    if (root.selectedIndex < 0 || root.selectedIndex >= parsed.length) root.selectedIndex = 0
                    root.loadDraft()
                    root.statusText = ""
                }
            }
        }
    }

    Process {
        id: applyProc
        command: ["true"]
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.statusText = "DISPLAY UPDATED"
                saveProc.exec([root.saveHelper])
                refreshDelay.restart()
            } else {
                root.statusText = "DISPLAY UPDATE FAILED"
            }
        }
    }

    Process {
        id: mainProc
        command: ["true"]
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.statusText = "MAIN DISPLAY UPDATED"
                saveProc.exec([root.saveHelper])
                refreshDelay.restart()
            } else {
                root.statusText = "MAIN DISPLAY UPDATE FAILED"
            }
        }
    }

    Process { id: saveProc; command: [root.saveHelper] }
    Timer { id: refreshDelay; interval: 450; repeat: false; onTriggered: root.refresh() }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: ">_ DISPLAYS_"; font.family: root.pixel; font.pixelSize: 17; color: root.cyanB }
            Text {
                text: "<_ BACK"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.requestBack() }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        Text {
            Layout.fillWidth: true
            text: "SELECT OUTPUT"
            font.family: root.pixel; font.pixelSize: 12; color: root.cyanB
        }

        ListView {
            id: outputList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(176, Math.max(44, root.outputs.length * 44))
            clip: true
            spacing: 5
            model: root.outputs
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: outputList.width; height: 39
                readonly property bool selected: index === root.selectedIndex
                readonly property bool main: modelData.enabled && modelData.x === 0 && modelData.y === 0
                color: selected ? root.cyanD : (outMa.containsMouse ? "#143245" : "#0c1620")
                border.color: selected ? root.cyan : root.cyanD; border.width: 1
                Column {
                    anchors.left: parent.left; anchors.right: statusLabel.left
                    anchors.leftMargin: 8; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text { width: parent.width; text: modelData.name; font.family: root.pixel; font.pixelSize: 12; color: parent.parent.selected ? "#04141c" : root.cyanB; elide: Text.ElideRight }
                    Text { width: parent.width; text: modelData.description; font.family: root.pixel; font.pixelSize: 9; color: parent.parent.selected ? "#082b3c" : root.cyanD; elide: Text.ElideRight }
                }
                Text {
                    id: statusLabel
                    anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter
                    text: parent.main ? "MAIN" : (modelData.enabled ? "ON" : "OFF")
                    font.family: root.pixel; font.pixelSize: 9
                    color: parent.selected ? "#04141c" : (parent.main ? root.cyanB : root.cyanD)
                }
                MouseArea { id: outMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectOutput(index) }
            }
        }

        Text {
            visible: !root.backendAvailable
            Layout.fillWidth: true
            text: "wlr-randr could not read outputs."
            font.family: root.pixel; font.pixelSize: 11; color: root.warn
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            visible: root.selectedOutput() !== null
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Rectangle {
                    Layout.fillWidth: true; height: 30
                    color: root.draftEnabled ? root.cyan : "transparent"
                    border.color: root.cyanD; border.width: 1
                    Text { anchors.centerIn: parent; text: root.draftEnabled ? "ENABLED" : "DISABLED"; font.family: root.pixel; font.pixelSize: 11; color: root.draftEnabled ? "#04141c" : root.cyanB }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.draftEnabled = !root.draftEnabled }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 30
                    readonly property bool isMain: {
                        var o = root.selectedOutput(); return o && o.enabled && o.x === 0 && o.y === 0
                    }
                    color: isMain ? root.cyan : "transparent"
                    border.color: root.cyanD; border.width: 1
                    Text { anchors.centerIn: parent; text: parent.isMain ? "MAIN" : "SET MAIN"; font.family: root.pixel; font.pixelSize: 11; color: parent.isMain ? "#04141c" : root.cyanB }
                    MouseArea { anchors.fill: parent; enabled: root.selectedOutput() && root.selectedOutput().enabled; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.setMain() }
                }
            }

            Text { text: "RESOLUTION"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Repeater {
                    model: ["<", root.draftWidth > 0 ? (root.draftWidth + "x" + root.draftHeight) : "preferred", ">"]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: index === 1
                        width: index === 1 ? 180 : 34; height: 28
                        color: index === 1 ? "#0c1620" : (resMa.containsMouse ? "#143245" : "transparent")
                        border.color: root.cyanD; border.width: 1
                        Text { anchors.centerIn: parent; text: modelData; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                        MouseArea { id: resMa; anchors.fill: parent; hoverEnabled: index !== 1; enabled: index !== 1; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.cycleResolution(index === 0 ? -1 : 1) }
                    }
                }
            }

            Text { text: "REFRESH RATE"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Repeater {
                    model: ["<", root.draftRefresh > 0 ? (root.draftRefresh.toFixed(3) + " Hz") : "default", ">"]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: index === 1
                        width: index === 1 ? 180 : 34; height: 28
                        color: index === 1 ? "#0c1620" : (rateMa.containsMouse ? "#143245" : "transparent")
                        border.color: root.cyanD; border.width: 1
                        Text { anchors.centerIn: parent; text: modelData; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                        MouseArea { id: rateMa; anchors.fill: parent; hoverEnabled: index !== 1; enabled: index !== 1; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.cycleRefresh(index === 0 ? -1 : 1) }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Text { text: "SCALE"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
                    RowLayout {
                        spacing: 4
                        Text { text: "<"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleScale(-1) } }
                        Text { text: root.draftScale.toFixed(2) + "x"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                        Text { text: ">"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleScale(1) } }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Text { text: "ROTATION"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
                    RowLayout {
                        spacing: 4
                        Text { text: "<"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleTransform(-1) } }
                        Text { text: root.draftTransform; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                        Text { text: ">"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleTransform(1) } }
                    }
                }
            }

            Text { text: "POSITION"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text { text: "X"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                Rectangle {
                    Layout.fillWidth: true; height: 28; color: "#0c1620"; border.color: root.cyanD; border.width: 1
                    TextInput {
                        anchors.fill: parent; anchors.margins: 6
                        text: String(root.draftX); selectByMouse: true
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        font.family: root.pixel; font.pixelSize: 11; color: root.cyanB
                        onEditingFinished: { var v = parseInt(text); if (!isNaN(v)) root.draftX = v; text = String(root.draftX) }
                    }
                }
                Text { text: "Y"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                Rectangle {
                    Layout.fillWidth: true; height: 28; color: "#0c1620"; border.color: root.cyanD; border.width: 1
                    TextInput {
                        anchors.fill: parent; anchors.margins: 6
                        text: String(root.draftY); selectByMouse: true
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        font.family: root.pixel; font.pixelSize: 11; color: root.cyanB
                        onEditingFinished: { var v = parseInt(text); if (!isNaN(v)) root.draftY = v; text = String(root.draftY) }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "MAIN is the output at 0,0. SET MAIN rebases every active display while preserving their relative layout."
                font.family: root.pixel; font.pixelSize: 9; color: root.cyanD
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Rectangle {
                    Layout.fillWidth: true; height: 32
                    color: applyMa.containsMouse ? root.cyan : "transparent"
                    border.color: root.cyan; border.width: 1
                    Text { anchors.centerIn: parent; text: "APPLY + SAVE"; font.family: root.pixel; font.pixelSize: 11; color: applyMa.containsMouse ? "#04141c" : root.cyanB }
                    MouseArea { id: applyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applySelected() }
                }
                Rectangle {
                    width: 82; height: 32
                    color: refreshMa.containsMouse ? "#143245" : "transparent"
                    border.color: root.cyanD; border.width: 1
                    Text { anchors.centerIn: parent; text: "REFRESH"; font.family: root.pixel; font.pixelSize: 10; color: root.cyanB }
                    MouseArea { id: refreshMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.refresh() }
                }
            }
        }

        Item { Layout.fillHeight: true }
        Text {
            Layout.fillWidth: true
            visible: root.statusText !== ""
            text: root.statusText
            font.family: root.pixel; font.pixelSize: 10
            color: root.statusText.indexOf("FAILED") >= 0 || root.statusText.indexOf("CANNOT") >= 0 || root.statusText.indexOf("UNAVAILABLE") >= 0 ? root.warn : root.cyanD
            wrapMode: Text.WordWrap
        }
    }
}
