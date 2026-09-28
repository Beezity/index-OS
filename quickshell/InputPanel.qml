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

    property bool ready: false
    property real pointerSpeed: 0.0
    property bool naturalScroll: false
    property bool tapClick: true
    property bool touchpadPresent: false

    function refresh() {
        if (!stateGet.running) stateGet.running = true
    }

    function run(action) {
        Quickshell.execDetached(["sh", "-c", "$HOME/.local/bin/index-input " + action])
        actionRefresh.restart()
    }

    Component.onCompleted: refresh()
    onVisibleChanged: if (visible) refresh()

    Process {
        id: stateGet
        command: ["sh", "-c", "$HOME/.local/bin/index-input state 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.replace(/[\r\n]+$/, "")
                var f = line.split("\t")
                if (f.length < 5 || f[0] !== "1") {
                    root.ready = false
                    return
                }
                var speed = parseFloat(f[1])
                if (isNaN(speed)) {
                    root.ready = false
                    return
                }
                root.pointerSpeed = Math.max(-1, Math.min(1, speed))
                root.naturalScroll = f[2] === "yes"
                root.tapClick = f[3] === "yes"
                root.touchpadPresent = f[4] === "1"
                root.ready = true
            }
        }
    }

    Timer {
        id: actionRefresh
        interval: 450
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
                text: ">_ INPUT_"
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
            visible: !root.ready
            Layout.fillWidth: true
            text: "LABWC INPUT STATE UNAVAILABLE"
            font.family: root.pixel; font.pixelSize: 11; color: root.warn
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            enabled: root.ready
            opacity: enabled ? 1 : 0.45

            Text {
                text: "POINTER SPEED  " + root.pointerSpeed.toFixed(2)
                font.family: root.pixel; font.pixelSize: 13; color: root.cyanB
            }
            Text {
                text: "  -1.00 slower        0.00 default        1.00 faster"
                font.family: root.pixel; font.pixelSize: 9; color: root.cyanD
            }
            Rectangle {
                Layout.fillWidth: true
                height: 18
                color: "#05080d"
                border.color: root.cyanD
                border.width: 1
                Rectangle {
                    x: 2; y: 2
                    height: parent.height - 4
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
                    onReleased: root.run("set-pointer-speed " + root.pointerSpeed.toFixed(2))
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            enabled: root.ready
            opacity: enabled ? 1 : 0.45

            Text {
                text: "SCROLLING"
                font.family: root.pixel; font.pixelSize: 13; color: root.cyanB
            }
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: root.naturalScroll ? root.cyan : (naturalMa.containsMouse ? "#143245" : "transparent")
                border.color: root.cyanD
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "NATURAL SCROLL  " + (root.naturalScroll ? "ON" : "OFF")
                    font.family: root.pixel; font.pixelSize: 11
                    color: root.naturalScroll ? "#04141c" : root.cyanB
                }
                MouseArea {
                    id: naturalMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.naturalScroll = !root.naturalScroll
                        root.run("set-natural-scroll " + (root.naturalScroll ? "yes" : "no"))
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            enabled: root.ready && root.touchpadPresent
            opacity: enabled ? 1 : 0.45

            Text {
                text: "TOUCHPAD"
                font.family: root.pixel; font.pixelSize: 13; color: root.cyanB
            }
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: root.tapClick ? root.cyan : (tapMa.containsMouse && parent.enabled ? "#143245" : "transparent")
                border.color: root.cyanD
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "TAP TO CLICK  " + (root.tapClick ? "ON" : "OFF")
                    font.family: root.pixel; font.pixelSize: 11
                    color: root.tapClick ? "#04141c" : root.cyanB
                }
                MouseArea {
                    id: tapMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: parent.parent.enabled
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        root.tapClick = !root.tapClick
                        root.run("set-tap " + (root.tapClick ? "yes" : "no"))
                    }
                }
            }
            Text {
                visible: root.ready && !root.touchpadPresent
                text: "  no touchpad detected; saved defaults are left unchanged"
                font.family: root.pixel; font.pixelSize: 9; color: root.cyanD
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        Rectangle {
            Layout.fillWidth: true
            height: 34
            color: resetMa.containsMouse ? "#143245" : "transparent"
            border.color: root.cyanD
            border.width: 1
            Text {
                anchors.centerIn: parent
                text: "RESET INPUT DEFAULTS"
                font.family: root.pixel; font.pixelSize: 11; color: root.cyanB
            }
            MouseArea {
                id: resetMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.ready
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.run("reset")
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "These controls write THE INDEX input preferences and apply them to labwc immediately. Cursor theme and size remain under APPEARANCE. Device-specific and advanced libinput rules can still be configured directly in labwc."
            font.family: root.pixel; font.pixelSize: 9; color: root.cyanD
        }

        Item { Layout.fillHeight: true }
    }
}
