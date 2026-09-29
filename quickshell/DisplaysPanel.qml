// WILL OF THE CITY :: THE INDEX — display settings subpanel
// The QML layer stays compositor-neutral. index-displays is authoritative for
// reading/applying/persisting outputs on both labwc and niri.
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
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/index-displays"

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
        return selectedIndex >= 0 && selectedIndex < outputs.length ? outputs[selectedIndex] : null
    }

    function parseState(raw) {
        var result = []
        var current = null
        var lines = raw.split(/\r?\n/)
        for (var i = 0; i < lines.length; i++) {
            if (lines[i] === "") continue
            var p = lines[i].split("\t")
            if (p[0] === "@output" && p.length >= 8) {
                current = {
                    name: p[1], description: p[2] || p[1], enabled: p[3] === "1",
                    x: parseInt(p[4]) || 0, y: parseInt(p[5]) || 0,
                    scale: parseFloat(p[6]) || 1.0, transform: p[7] || "normal", modes: []
                }
                result.push(current)
            } else if (p[0] === "@mode" && current && p.length >= 6) {
                current.modes.push({
                    width: parseInt(p[1]) || 0, height: parseInt(p[2]) || 0,
                    refresh: parseFloat(p[3]) || 0, preferred: p[4] === "1", current: p[5] === "1"
                })
            }
        }
        return result
    }

    function currentMode(output) {
        if (!output) return null
        for (var i = 0; i < output.modes.length; i++) if (output.modes[i].current) return output.modes[i]
        for (var j = 0; j < output.modes.length; j++) if (output.modes[j].preferred) return output.modes[j]
        return output.modes.length ? output.modes[0] : null
    }

    function loadDraft() {
        var o = selectedOutput(); if (!o) return
        var m = currentMode(o)
        draftEnabled = o.enabled
        draftWidth = m ? m.width : 0
        draftHeight = m ? m.height : 0
        draftRefresh = m ? m.refresh : 0
        draftX = o.x; draftY = o.y; draftScale = o.scale || 1.0; draftTransform = o.transform || "normal"
    }

    function selectOutput(i) { if (i >= 0 && i < outputs.length) { selectedIndex = i; loadDraft() } }

    function resolutionChoices() {
        var o = selectedOutput(); if (!o) return []
        var out = [], seen = ({})
        for (var i = 0; i < o.modes.length; i++) {
            var key = o.modes[i].width + "x" + o.modes[i].height
            if (!seen[key]) { seen[key] = true; out.push({ width: o.modes[i].width, height: o.modes[i].height }) }
        }
        return out
    }

    function refreshChoices() {
        var o = selectedOutput(); if (!o) return []
        var out = [], seen = ({})
        for (var i = 0; i < o.modes.length; i++) {
            var m = o.modes[i]
            if (m.width !== draftWidth || m.height !== draftHeight || m.refresh <= 0) continue
            var key = m.refresh.toFixed(3)
            if (!seen[key]) { seen[key] = true; out.push(m.refresh) }
        }
        out.sort(function(a, b) { return b - a })
        return out
    }

    function cycleResolution(step) {
        var c = resolutionChoices(); if (!c.length) return
        var idx = 0
        for (var i = 0; i < c.length; i++) if (c[i].width === draftWidth && c[i].height === draftHeight) { idx = i; break }
        idx = (idx + step + c.length) % c.length
        draftWidth = c[idx].width; draftHeight = c[idx].height
        var rates = refreshChoices(); draftRefresh = rates.length ? rates[0] : 0
    }

    function cycleRefresh(step) {
        var c = refreshChoices(); if (!c.length) return
        var idx = 0, best = 999999
        for (var i = 0; i < c.length; i++) { var d = Math.abs(c[i] - draftRefresh); if (d < best) { best = d; idx = i } }
        draftRefresh = c[(idx + step + c.length) % c.length]
    }

    function cycleScale(step) {
        var idx = 0, best = 999
        for (var i = 0; i < scaleChoices.length; i++) { var d = Math.abs(scaleChoices[i] - draftScale); if (d < best) { best = d; idx = i } }
        draftScale = scaleChoices[(idx + step + scaleChoices.length) % scaleChoices.length]
    }

    function cycleTransform(step) {
        var idx = transformChoices.indexOf(draftTransform); if (idx < 0) idx = 0
        draftTransform = transformChoices[(idx + step + transformChoices.length) % transformChoices.length]
    }

    function enabledCount() { var n = 0; for (var i = 0; i < outputs.length; i++) if (outputs[i].enabled) n++; return n }

    function applySelected() {
        var o = selectedOutput(); if (!o || applyProc.running) return
        if (!draftEnabled && o.enabled && enabledCount() <= 1) { statusText = "CANNOT DISABLE THE LAST ACTIVE DISPLAY"; return }
        statusText = "APPLYING + SAVING..."
        applyProc.exec([helper, "apply", o.name, draftEnabled ? "1" : "0",
            String(draftWidth), String(draftHeight), draftRefresh.toFixed(3),
            String(draftX), String(draftY), draftScale.toFixed(4), draftTransform])
    }

    function setMain() {
        var o = selectedOutput(); if (!o || !o.enabled || mainProc.running) return
        statusText = "SETTING MAIN DISPLAY..."
        mainProc.exec([helper, "set-main", o.name])
    }

    function refresh() { if (!stateProc.running) { statusText = "READING OUTPUTS..."; stateProc.running = true } }
    Component.onCompleted: if (visible) refresh()
    onVisibleChanged: if (visible) refresh()

    Process {
        id: stateProc
        command: [root.helper, "state"]
        stdout: StdioCollector {
            onStreamFinished: {
                var previousName = root.selectedOutput() ? root.selectedOutput().name : ""
                var parsed = root.parseState(text)
                root.outputs = parsed; root.backendAvailable = parsed.length > 0
                if (!parsed.length) { root.selectedIndex = -1; root.statusText = "DISPLAY BACKEND UNAVAILABLE"; return }
                var next = 0
                if (previousName !== "") for (var i = 0; i < parsed.length; i++) if (parsed[i].name === previousName) { next = i; break }
                root.selectedIndex = next; root.loadDraft(); root.statusText = ""
            }
        }
    }

    Process {
        id: applyProc; command: ["true"]
        onExited: function(exitCode, exitStatus) {
            root.statusText = exitCode === 0 ? "DISPLAY UPDATED + SAVED" : "DISPLAY UPDATE FAILED"
            if (exitCode === 0) refreshDelay.restart()
        }
    }
    Process {
        id: mainProc; command: ["true"]
        onExited: function(exitCode, exitStatus) {
            root.statusText = exitCode === 0 ? "MAIN DISPLAY UPDATED" : "MAIN DISPLAY UPDATE FAILED"
            if (exitCode === 0) refreshDelay.restart()
        }
    }
    Process { id: advancedProc; command: ["true"] }
    Timer { id: refreshDelay; interval: 450; repeat: false; onTriggered: root.refresh() }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: ">_ DISPLAYS_"; font.family: root.pixel; font.pixelSize: 17; color: root.cyanB }
            Text { text: "<_ BACK"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.requestBack() } }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }
        Text { text: "SELECT OUTPUT"; font.family: root.pixel; font.pixelSize: 12; color: root.cyanB }

        ListView {
            id: outputList; Layout.fillWidth: true
            Layout.preferredHeight: Math.min(176, Math.max(44, root.outputs.length * 44)); clip: true; spacing: 5; model: root.outputs
            delegate: Rectangle {
                required property var modelData; required property int index
                width: outputList.width; height: 39
                readonly property bool selected: index === root.selectedIndex
                readonly property bool main: modelData.enabled && modelData.x === 0 && modelData.y === 0
                color: selected ? root.cyanD : (outMa.containsMouse ? "#143245" : "#0c1620")
                border.color: selected ? root.cyan : root.cyanD; border.width: 1
                Column {
                    anchors.left: parent.left; anchors.right: statusLabel.left; anchors.leftMargin: 8; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; spacing: 1
                    Text { width: parent.width; text: modelData.name; font.family: root.pixel; font.pixelSize: 12; color: parent.parent.selected ? "#04141c" : root.cyanB; elide: Text.ElideRight }
                    Text { width: parent.width; text: modelData.description; font.family: root.pixel; font.pixelSize: 9; color: parent.parent.selected ? "#082b3c" : root.cyanD; elide: Text.ElideRight }
                }
                Text { id: statusLabel; anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter; text: parent.main ? "MAIN" : (modelData.enabled ? "ON" : "OFF"); font.family: root.pixel; font.pixelSize: 9; color: parent.selected ? "#04141c" : root.cyanD }
                MouseArea { id: outMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectOutput(index) }
            }
        }

        Text { visible: !root.backendAvailable; Layout.fillWidth: true; text: "The active compositor could not report any outputs."; font.family: root.pixel; font.pixelSize: 11; color: root.warn; wrapMode: Text.WordWrap }

        ColumnLayout {
            visible: root.selectedOutput() !== null; Layout.fillWidth: true; spacing: 8
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Rectangle {
                    Layout.fillWidth: true; height: 30; color: root.draftEnabled ? root.cyan : "transparent"; border.color: root.cyanD; border.width: 1
                    Text { anchors.centerIn: parent; text: root.draftEnabled ? "ENABLED" : "DISABLED"; font.family: root.pixel; font.pixelSize: 11; color: root.draftEnabled ? "#04141c" : root.cyanB }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.draftEnabled = !root.draftEnabled }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 30
                    readonly property bool isMain: { var o = root.selectedOutput(); return o && o.enabled && o.x === 0 && o.y === 0 }
                    color: isMain ? root.cyan : "transparent"; border.color: root.cyanD; border.width: 1
                    Text { anchors.centerIn: parent; text: parent.isMain ? "MAIN" : "SET MAIN"; font.family: root.pixel; font.pixelSize: 11; color: parent.isMain ? "#04141c" : root.cyanB }
                    MouseArea { anchors.fill: parent; enabled: root.selectedOutput() && root.selectedOutput().enabled; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.setMain() }
                }
            }

            Text { text: "RESOLUTION"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Rectangle { width: 34; height: 28; color: resLeft.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD; Text { anchors.centerIn: parent; text: "<"; font.family: root.pixel; color: root.cyanB } MouseArea { id: resLeft; anchors.fill: parent; hoverEnabled: true; onClicked: root.cycleResolution(-1) } }
                Rectangle { Layout.fillWidth: true; height: 28; color: "#0c1620"; border.color: root.cyanD; Text { anchors.centerIn: parent; text: root.draftWidth > 0 ? root.draftWidth + "x" + root.draftHeight : "preferred"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB } }
                Rectangle { width: 34; height: 28; color: resRight.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD; Text { anchors.centerIn: parent; text: ">"; font.family: root.pixel; color: root.cyanB } MouseArea { id: resRight; anchors.fill: parent; hoverEnabled: true; onClicked: root.cycleResolution(1) } }
            }

            Text { text: "REFRESH RATE"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Rectangle { width: 34; height: 28; color: rateLeft.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD; Text { anchors.centerIn: parent; text: "<"; font.family: root.pixel; color: root.cyanB } MouseArea { id: rateLeft; anchors.fill: parent; hoverEnabled: true; onClicked: root.cycleRefresh(-1) } }
                Rectangle { Layout.fillWidth: true; height: 28; color: "#0c1620"; border.color: root.cyanD; Text { anchors.centerIn: parent; text: root.draftRefresh > 0 ? root.draftRefresh.toFixed(3) + " Hz" : "default"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB } }
                Rectangle { width: 34; height: 28; color: rateRight.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD; Text { anchors.centerIn: parent; text: ">"; font.family: root.pixel; color: root.cyanB } MouseArea { id: rateRight; anchors.fill: parent; hoverEnabled: true; onClicked: root.cycleRefresh(1) } }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "SCALE"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
                    RowLayout { Text { text: "<"; font.family: root.pixel; color: root.cyanB; MouseArea { anchors.fill: parent; onClicked: root.cycleScale(-1) } } Text { text: root.draftScale.toFixed(2) + "x"; font.family: root.pixel; color: root.cyanB } Text { text: ">"; font.family: root.pixel; color: root.cyanB; MouseArea { anchors.fill: parent; onClicked: root.cycleScale(1) } } }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "ROTATION"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
                    RowLayout { Text { text: "<"; font.family: root.pixel; color: root.cyanB; MouseArea { anchors.fill: parent; onClicked: root.cycleTransform(-1) } } Text { text: root.draftTransform; font.family: root.pixel; color: root.cyanB } Text { text: ">"; font.family: root.pixel; color: root.cyanB; MouseArea { anchors.fill: parent; onClicked: root.cycleTransform(1) } } }
                }
            }

            Text { text: "POSITION"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text { text: "X"; font.family: root.pixel; color: root.cyanB }
                Rectangle { Layout.fillWidth: true; height: 28; color: "#0c1620"; border.color: root.cyanD; TextInput { anchors.fill: parent; anchors.margins: 6; text: String(root.draftX); selectByMouse: true; font.family: root.pixel; color: root.cyanB; onEditingFinished: { var v=parseInt(text); if (!isNaN(v)) root.draftX=v; text=String(root.draftX) } } }
                Text { text: "Y"; font.family: root.pixel; color: root.cyanB }
                Rectangle { Layout.fillWidth: true; height: 28; color: "#0c1620"; border.color: root.cyanD; TextInput { anchors.fill: parent; anchors.margins: 6; text: String(root.draftY); selectByMouse: true; font.family: root.pixel; color: root.cyanB; onEditingFinished: { var v=parseInt(text); if (!isNaN(v)) root.draftY=v; text=String(root.draftY) } } }
            }

            Text { Layout.fillWidth: true; text: "MAIN is the output at 0,0. SET MAIN preserves relative placement. Advanced compositor-specific options stay in the native config/tool."; font.family: root.pixel; font.pixelSize: 9; color: root.cyanD; wrapMode: Text.WordWrap }

            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Rectangle { Layout.fillWidth: true; height: 32; color: applyMa.containsMouse ? root.cyan : "transparent"; border.color: root.cyan; Text { anchors.centerIn: parent; text: "APPLY + SAVE"; font.family: root.pixel; font.pixelSize: 11; color: applyMa.containsMouse ? "#04141c" : root.cyanB } MouseArea { id: applyMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.applySelected() } }
                Rectangle { width: 82; height: 32; color: refreshMa.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD; Text { anchors.centerIn: parent; text: "REFRESH"; font.family: root.pixel; font.pixelSize: 10; color: root.cyanB } MouseArea { id: refreshMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.refresh() } }
            }
        }

        Item { Layout.fillHeight: true }
        Text { Layout.fillWidth: true; visible: root.statusText !== ""; text: root.statusText; font.family: root.pixel; font.pixelSize: 10; color: root.statusText.indexOf("FAILED") >= 0 || root.statusText.indexOf("CANNOT") >= 0 || root.statusText.indexOf("UNAVAILABLE") >= 0 ? root.warn : root.cyanD; wrapMode: Text.WordWrap }
    }
}
