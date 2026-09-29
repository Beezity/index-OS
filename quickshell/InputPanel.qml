// WILL OF THE CITY :: THE INDEX — input settings subpanel
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
    readonly property bool niriSession: Quickshell.env("NIRI_SOCKET") !== ""

    property bool backendAvailable: false
    property real pointerSpeed: 0.0
    property bool naturalScroll: false
    property bool touchpadPresent: false
    property bool tapClick: true
    property int cursorSize: 24
    property bool ready: false

    function refresh() {
        if (!stateGet.running) stateGet.running = true
    }

    function runInput(args) {
        Quickshell.execDetached(["sh", "-c", "exec \"$HOME/.local/bin/index-input\" " + args])
        actionRefresh.restart()
    }

    function setCursorSize(size) {
        root.cursorSize = size
        Quickshell.execDetached(["sh", "-c", "exec \"$HOME/.local/bin/index-appearance\" set-cursor-size " + size])
        actionRefresh.restart()
    }

    Component.onCompleted: refresh()
    onVisibleChanged: if (visible) refresh()

    Process {
        id: stateGet
        command: ["sh", "-c",
            "i=$(\"$HOME/.local/bin/index-input\" state 2>/dev/null) || i='0\t0.00\tno\t0\tyes'; " +
            "c=$(\"$HOME/.local/bin/index-appearance\" get CURSOR_SIZE 2>/dev/null || true); " +
            "[ -n \"$c\" ] || c=24; printf '%s\\t%s\\n' \"$i\" \"$c\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.replace(/[\r\n]+$/, "")
                var f = line.split("\t")
                if (f.length < 6) {
                    root.backendAvailable = false
                    root.touchpadPresent = false
                    root.ready = false
                    return
                }
                root.backendAvailable = f[0] === "1"
                var speed = parseFloat(f[1])
                root.pointerSpeed = isNaN(speed) ? 0.0 : Math.max(-1.0, Math.min(1.0, speed))
                root.naturalScroll = f[2] === "yes"
                root.touchpadPresent = f[3] === "1"
                root.tapClick = f[4] === "yes"
                var size = parseInt(f[5])
                root.cursorSize = isNaN(size) ? 24 : size
                root.ready = true
            }
        }
    }

    Timer { id: actionRefresh; interval: 350; repeat: false; onTriggered: root.refresh() }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 11

        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: ">_ INPUT_"; font.family: root.pixel; font.pixelSize: 17; color: root.cyanB }
            Text {
                text: "<_ BACK"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.requestBack() }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        Text {
            visible: !root.ready || !root.backendAvailable
            text: root.ready ? "COMPOSITOR INPUT BACKEND UNAVAILABLE" : "INPUT STATE UNAVAILABLE"
            font.family: root.pixel; font.pixelSize: 11; color: root.warn
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 6
            enabled: root.backendAvailable
            opacity: enabled ? 1.0 : 0.45

            Text { text: "POINTER"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
            Text {
                text: "  speed  " + root.pointerSpeed.toFixed(2)
                font.family: root.pixel; font.pixelSize: 11; color: root.cyanD
            }
            Rectangle {
                Layout.fillWidth: true; height: 18
                color: "#05080d"; border.color: root.cyanD; border.width: 1
                Rectangle {
                    x: 2; y: 2; height: parent.height - 4
                    width: Math.max(2, (parent.width - 4) * ((root.pointerSpeed + 1) / 2))
                    color: root.cyan
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function setFromX(mx) {
                        var f = Math.max(0, Math.min(1, mx / width))
                        root.pointerSpeed = Math.round((f * 2 - 1) * 100) / 100
                    }
                    onPressed: function(m) { setFromX(m.x) }
                    onPositionChanged: function(m) { if (pressed) setFromX(m.x) }
                    onReleased: root.runInput("set-speed " + root.pointerSpeed.toFixed(2))
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 30
                readonly property bool on: root.naturalScroll
                color: on ? root.cyan : (naturalMa.containsMouse ? "#143245" : "transparent")
                border.color: root.cyanD; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "NATURAL SCROLL  " + (parent.on ? "ON" : "OFF")
                    font.family: root.pixel; font.pixelSize: 10
                    color: parent.on ? "#04141c" : root.cyanB
                }
                MouseArea {
                    id: naturalMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.naturalScroll = !root.naturalScroll
                        root.runInput("set-natural-scroll " + (root.naturalScroll ? "yes" : "no"))
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 6
            visible: root.touchpadPresent
            enabled: root.backendAvailable
            opacity: enabled ? 1.0 : 0.45

            Text { text: "TOUCHPAD"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
            Rectangle {
                Layout.fillWidth: true; height: 30
                readonly property bool on: root.tapClick
                color: on ? root.cyan : (tapMa.containsMouse ? "#143245" : "transparent")
                border.color: root.cyanD; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "TAP TO CLICK  " + (parent.on ? "ON" : "OFF")
                    font.family: root.pixel; font.pixelSize: 10
                    color: parent.on ? "#04141c" : root.cyanB
                }
                MouseArea {
                    id: tapMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.tapClick = !root.tapClick
                        root.runInput("set-tap " + (root.tapClick ? "yes" : "no"))
                    }
                }
            }
        }

        Text {
            visible: root.ready && !root.touchpadPresent
            text: "NO TOUCHPAD DETECTED — TOUCHPAD OPTIONS HIDDEN"
            font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: "CURSOR SIZE"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Repeater {
                    model: [16, 24, 32, 48]
                    delegate: Rectangle {
                        required property int modelData
                        Layout.fillWidth: true; height: 28
                        readonly property bool on: root.cursorSize === modelData
                        color: on ? root.cyan : (cursorMa.containsMouse ? "#143245" : "transparent")
                        border.color: root.cyanD; border.width: 1
                        Text {
                            anchors.centerIn: parent; text: modelData
                            font.family: root.pixel; font.pixelSize: 11
                            color: parent.on ? "#04141c" : root.cyanB
                        }
                        MouseArea {
                            id: cursorMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setCursorSize(modelData)
                        }
                    }
                }
            }
            Text {
                text: "  cursor theme is managed in Appearance"
                font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }
        Text {
            Layout.fillWidth: true
            text: root.niriSession ? "ADVANCED PER-DEVICE RULES: ~/.config/niri/config.kdl" : "ADVANCED PER-DEVICE RULES: ~/.config/labwc/rc.xml"
            wrapMode: Text.Wrap
            font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
        }
        Text {
            Layout.fillWidth: true
            text: root.niriSession
                ? "Changes here update THE INDEX's managed niri input include. Advanced per-device rules remain in niri configuration."
                : "Changes here apply to labwc device categories. Per-device overrides remain in labwc configuration."
            wrapMode: Text.Wrap
            font.family: root.pixel; font.pixelSize: 9; color: root.cyanD
        }

        Item { Layout.fillHeight: true }
    }
}
