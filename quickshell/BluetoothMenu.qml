// WILL OF THE CITY :: THE INDEX — Bluetooth pairing panel
// Scan / pair / connect / disconnect via bluetoothctl.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: bt
    color: "#0a0e16"
    border.color: "#5DADE2"
    border.width: 2

    signal requestClose()

    readonly property string pixel: "Perfect DOS VGA 437 Universal"
    readonly property color cyan: "#5DADE2"
    readonly property color cyanB: "#85C5E8"
    readonly property color cyanD: "#3A7CA5"
    readonly property color warn: "#FF6B6B"
    readonly property color good: "#5DE285"

    property bool powered: false
    property bool scanning: false
    property var devices: []
    property string note: ""

    Process {
        id: powerGet
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 1 || echo 0"]
        stdout: StdioCollector { onStreamFinished: bt.powered = text.trim() === "1" }
    }

    Process {
        id: devGet
        // Merge paired, discovered and connected devices. `devices Connected`
        // is reliable whereas `bluetoothctl info` without a device is not.
        command: ["sh", "-c",
            "{ bluetoothctl devices Paired 2>/dev/null | sed 's/^/P /'; " +
            "bluetoothctl devices Connected 2>/dev/null | sed 's/^/C /'; " +
            "bluetoothctl devices 2>/dev/null | sed 's/^/A /'; }"
        ]
        stdout: StdioCollector { onStreamFinished: {
            var byMac = ({})
            var order = []
            var lines = text.trim().split("\n")
            for (var i = 0; i < lines.length; i++) {
                var p = lines[i].trim().split(/\s+/)
                if (p.length < 4 || p[1] !== "Device") continue
                var kind = p[0]
                var mac = p[2]
                if (!byMac[mac]) {
                    byMac[mac] = { mac: mac, name: p.slice(3).join(" ") || mac, paired: false, connected: false }
                    order.push(mac)
                }
                if (kind === "P") byMac[mac].paired = true
                if (kind === "C") byMac[mac].connected = true
            }
            var out = []
            for (var j = 0; j < order.length; j++) out.push(byMac[order[j]])
            bt.devices = out
        } }
    }

    Timer {
        id: poll
        interval: 3000
        running: bt.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: { powerGet.running = true; devGet.running = true }
    }

    Process {
        id: actionProc
        property string successMessage: ""
        command: ["true"]
        stdout: StdioCollector {}
        onRunningChanged: if (!running) {
            if (successMessage) bt.note = successMessage
            refreshTimer.restart()
        }
    }

    Timer { id: refreshTimer; interval: 900; repeat: false; onTriggered: { powerGet.running = true; devGet.running = true } }
    Timer { id: scanStop; interval: 12500; repeat: false; onTriggered: { bt.scanning = false; devGet.running = true } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text { text: ">_ BLUETOOTH_"; font.family: bt.pixel; font.pixelSize: 16; color: bt.cyanB }
            Item { Layout.fillWidth: true }
            Text {
                text: bt.powered ? "[ON]" : "[OFF]"
                font.family: bt.pixel; font.pixelSize: 12
                color: bt.powered ? bt.good : bt.warn
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        actionProc.command = ["bluetoothctl", "power", bt.powered ? "off" : "on"]
                        actionProc.successMessage = bt.powered ? "Bluetooth powered off" : "Bluetooth powered on"
                        actionProc.running = true
                    }
                }
            }
            Text {
                text: "[X]"; font.family: bt.pixel; font.pixelSize: 12; color: bt.warn
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bt.requestClose() }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: bt.cyanD; opacity: 0.6 }

        Rectangle {
            Layout.fillWidth: true; height: 26
            color: bt.scanning ? bt.cyan : "transparent"
            border.color: bt.cyanD; border.width: 1
            Text {
                anchors.centerIn: parent
                text: bt.scanning ? "SCANNING..." : "SCAN"
                font.family: bt.pixel; font.pixelSize: 11
                color: bt.scanning ? "#04141c" : bt.cyanB
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                enabled: !bt.scanning
                onClicked: {
                    if (!bt.powered) {
                        actionProc.command = ["bluetoothctl", "power", "on"]
                        actionProc.successMessage = "Bluetooth powered on"
                        actionProc.running = true
                    }
                    bt.scanning = true
                    Quickshell.execDetached(["bluetoothctl", "--timeout", "12", "scan", "on"])
                    scanStop.restart()
                }
            }
        }

        Text {
            visible: bt.note !== ""
            Layout.fillWidth: true
            text: bt.note
            font.family: bt.pixel; font.pixelSize: 10; color: bt.cyanD
            wrapMode: Text.WordWrap
        }

        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 3
            model: bt.devices
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width; height: 42
                color: deviceArea.containsMouse ? "#143245" : (modelData.connected ? "#0c2634" : "transparent")
                border.color: modelData.connected ? bt.good : "transparent"
                border.width: 1

                Column {
                    anchors.left: parent.left; anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 100
                    Text {
                        text: modelData.name
                        font.family: bt.pixel; font.pixelSize: 13
                        color: modelData.connected ? bt.cyanB : bt.cyan
                        elide: Text.ElideRight; width: parent.width
                    }
                    Text {
                        text: (modelData.paired ? "paired" : "new") + (modelData.connected ? " · connected" : "")
                        font.family: bt.pixel; font.pixelSize: 9; color: bt.cyanD
                    }
                }

                Text {
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.connected ? "[DISCONNECT]" : (modelData.paired ? "[CONNECT]" : "[PAIR]")
                    font.family: bt.pixel; font.pixelSize: 10
                    color: modelData.connected ? bt.warn : bt.cyanB
                }

                MouseArea {
                    id: deviceArea
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var mac = modelData.mac
                        if (modelData.connected) {
                            bt.note = "disconnecting " + modelData.name
                            actionProc.command = ["bluetoothctl", "disconnect", mac]
                            actionProc.successMessage = "disconnected " + modelData.name
                        } else if (modelData.paired) {
                            bt.note = "connecting " + modelData.name
                            actionProc.command = ["bluetoothctl", "connect", mac]
                            actionProc.successMessage = "connected " + modelData.name
                        } else {
                            // The built-in no-input agent handles common headphones,
                            // mice and controllers. Devices needing a displayed PIN can
                            // be paired through the Blueman button below.
                            bt.note = "pairing " + modelData.name
                            actionProc.command = ["sh", "-c", "bluetoothctl --agent NoInputNoOutput pair '" + mac + "' && bluetoothctl trust '" + mac + "' && bluetoothctl connect '" + mac + "'"]
                            actionProc.successMessage = "paired " + modelData.name
                        }
                        actionProc.running = true
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: ">_ advanced (blueman) _<"
            font.family: bt.pixel; font.pixelSize: 10; color: bt.cyanD
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { Quickshell.execDetached(["blueman-manager"]); bt.requestClose() }
            }
        }
    }
}
