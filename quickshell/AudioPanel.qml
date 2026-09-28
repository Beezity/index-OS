// WILL OF THE CITY :: THE INDEX — audio settings subpanel
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
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/index-audio"

    property int outputVolume: 50
    property bool outputMuted: false
    property int inputVolume: 50
    property bool inputMuted: false
    property string outputName: "NO OUTPUT"
    property string inputName: "NO INPUT"
    property bool serviceOnline: false
    property bool ready: false
    readonly property bool outputAvailable: serviceOnline && outputName !== "NO OUTPUT"
    readonly property bool inputAvailable: serviceOnline && inputName !== "NO INPUT"

    function run(args) { Quickshell.execDetached([root.helper].concat(args)) }
    function refresh() { if (!stateGet.running) stateGet.running = true }

    onVisibleChanged: {
        if (visible) {
            ready = false
            refresh()
        }
    }
    Component.onCompleted: if (visible) refresh()

    Process {
        id: stateGet
        command: [root.helper, "state"]
        stdout: StdioCollector {
            onStreamFinished: {
                var f = text.trim().split("\t")
                if (f.length >= 5) {
                    root.serviceOnline = f[0] === "1"
                    var outState = f[1].split("|")
                    var inState = f[2].split("|")
                    var ov = parseInt(outState[0]); if (!isNaN(ov)) root.outputVolume = ov
                    root.outputMuted = outState[1] === "1"
                    var iv = parseInt(inState[0]); if (!isNaN(iv)) root.inputVolume = iv
                    root.inputMuted = inState[1] === "1"
                    root.outputName = f[3] || "NO OUTPUT"
                    root.inputName = f.slice(4).join("\t") || "NO INPUT"
                } else {
                    root.serviceOnline = false
                    root.outputName = "NO OUTPUT"
                    root.inputName = "NO INPUT"
                }
                root.ready = true
            }
        }
    }

    Process {
        id: outputChooser
        property bool started: false
        command: [root.helper, "choose-output"]
        stdout: StdioCollector {}
        onRunningChanged: {
            if (running) started = true
            else if (started) { started = false; root.refresh() }
        }
    }
    Process {
        id: inputChooser
        property bool started: false
        command: [root.helper, "choose-input"]
        stdout: StdioCollector {}
        onRunningChanged: {
            if (running) started = true
            else if (started) { started = false; root.refresh() }
        }
    }

    Timer {
        id: refreshTimer
        interval: 5000
        repeat: true
        running: root.visible
        triggeredOnStart: false
        onTriggered: root.refresh()
    }
    Timer {
        id: delayedRefresh
        interval: 500
        repeat: false
        onTriggered: root.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: ">_ AUDIO_"
                font.family: root.pixel; font.pixelSize: 17; color: root.cyanB
            }
            Text {
                text: "<_ BACK"
                font.family: root.pixel; font.pixelSize: 11; color: root.cyanD
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.requestBack() }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        Text {
            visible: !root.ready || !root.serviceOnline
            Layout.fillWidth: true
            text: !root.ready ? "CHECKING AUDIO..." : "PIPEWIRE / WIREPLUMBER UNAVAILABLE"
            font.family: root.pixel; font.pixelSize: 10
            color: root.ready ? root.warn : root.cyanD
        }

        Text { text: "OUTPUT"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        Text {
            Layout.fillWidth: true
            text: "  " + root.outputName
            elide: Text.ElideRight
            font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Rectangle {
                Layout.fillWidth: true; height: 32
                opacity: root.serviceOnline ? 1.0 : 0.45
                color: outDevArea.containsMouse ? "#143245" : "#0c1620"
                border.color: root.cyanD; border.width: 1
                Text { anchors.centerIn: parent; text: "CHANGE OUTPUT"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                MouseArea {
                    id: outDevArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    enabled: root.serviceOnline
                    onClicked: if (!outputChooser.running) outputChooser.running = true
                }
            }
            Rectangle {
                width: 82; height: 32
                opacity: root.outputAvailable ? 1.0 : 0.45
                color: root.outputMuted ? root.warn : "transparent"
                border.color: root.outputMuted ? root.warn : root.cyanD; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: root.outputMuted ? "UNMUTE" : "MUTE"
                    font.family: root.pixel; font.pixelSize: 11
                    color: root.outputMuted ? "#04141c" : root.cyanB
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: root.outputAvailable
                    onClicked: { root.run(["toggle-output-mute"]); root.outputMuted = !root.outputMuted; delayedRefresh.restart() }
                }
            }
        }

        Text {
            text: "OUTPUT VOLUME  " + root.outputVolume + "%"
            font.family: root.pixel; font.pixelSize: 11; color: root.cyanD
        }
        Rectangle {
            Layout.fillWidth: true; height: 18
            opacity: root.outputAvailable ? 1.0 : 0.45
            color: "#04141c"; border.color: root.cyanD; border.width: 1
            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.margins: 2
                width: Math.max(0, (parent.width - 4) * root.outputVolume / 100)
                color: root.outputMuted ? root.cyanD : root.cyan
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                enabled: root.outputAvailable
                function setFromX(mx) {
                    root.outputVolume = Math.max(0, Math.min(100, Math.round(mx / width * 100)))
                }
                onPressed: function(m) { setFromX(m.x) }
                onPositionChanged: function(m) { if (pressed) setFromX(m.x) }
                onReleased: { root.run(["set-output-volume", String(root.outputVolume)]); delayedRefresh.restart() }
                onWheel: function(w) {
                    root.outputVolume = Math.max(0, Math.min(100, root.outputVolume + (w.angleDelta.y > 0 ? 5 : -5)))
                    root.run(["set-output-volume", String(root.outputVolume)])
                    delayedRefresh.restart()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        Text { text: "INPUT"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        Text {
            Layout.fillWidth: true
            text: "  " + root.inputName
            elide: Text.ElideRight
            font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Rectangle {
                Layout.fillWidth: true; height: 32
                opacity: root.serviceOnline ? 1.0 : 0.45
                color: inDevArea.containsMouse ? "#143245" : "#0c1620"
                border.color: root.cyanD; border.width: 1
                Text { anchors.centerIn: parent; text: "CHANGE INPUT"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                MouseArea {
                    id: inDevArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    enabled: root.serviceOnline
                    onClicked: if (!inputChooser.running) inputChooser.running = true
                }
            }
            Rectangle {
                width: 82; height: 32
                opacity: root.inputAvailable ? 1.0 : 0.45
                color: root.inputMuted ? root.warn : "transparent"
                border.color: root.inputMuted ? root.warn : root.cyanD; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: root.inputMuted ? "UNMUTE" : "MUTE"
                    font.family: root.pixel; font.pixelSize: 11
                    color: root.inputMuted ? "#04141c" : root.cyanB
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: root.inputAvailable
                    onClicked: { root.run(["toggle-input-mute"]); root.inputMuted = !root.inputMuted; delayedRefresh.restart() }
                }
            }
        }

        Text {
            text: "INPUT VOLUME  " + root.inputVolume + "%"
            font.family: root.pixel; font.pixelSize: 11; color: root.cyanD
        }
        Rectangle {
            Layout.fillWidth: true; height: 18
            opacity: root.inputAvailable ? 1.0 : 0.45
            color: "#04141c"; border.color: root.cyanD; border.width: 1
            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.margins: 2
                width: Math.max(0, (parent.width - 4) * root.inputVolume / 100)
                color: root.inputMuted ? root.cyanD : root.cyanB
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                enabled: root.inputAvailable
                function setFromX(mx) {
                    root.inputVolume = Math.max(0, Math.min(100, Math.round(mx / width * 100)))
                }
                onPressed: function(m) { setFromX(m.x) }
                onPositionChanged: function(m) { if (pressed) setFromX(m.x) }
                onReleased: { root.run(["set-input-volume", String(root.inputVolume)]); delayedRefresh.restart() }
                onWheel: function(w) {
                    root.inputVolume = Math.max(0, Math.min(100, root.inputVolume + (w.angleDelta.y > 0 ? 5 : -5)))
                    root.run(["set-input-volume", String(root.inputVolume)])
                    delayedRefresh.restart()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        Rectangle {
            Layout.fillWidth: true; height: 34
            color: advancedArea.containsMouse ? "#143245" : "transparent"
            border.color: root.cyanD; border.width: 1
            Text { anchors.centerIn: parent; text: "OPEN ADVANCED MIXER"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
            MouseArea {
                id: advancedArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["pavucontrol"])
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Default output/input and volume changes use PipeWire through wpctl. Per-app routing and advanced profiles remain available in pavucontrol."
            font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
        }

        Item { Layout.fillHeight: true }
    }
}
