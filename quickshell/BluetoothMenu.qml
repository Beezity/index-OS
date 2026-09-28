// WILL OF THE CITY :: THE INDEX — Bluetooth pairing/settings panel
// Reused by the bar popup and SettingsPanel.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: bt
    property bool embedded: false
    signal requestClose()
    signal requestBack()

    color: embedded ? "transparent" : "#0a0e16"
    border.color: "#5DADE2"
    border.width: embedded ? 0 : 2

    readonly property string pixel: "Perfect DOS VGA 437 Universal"
    readonly property color cyan: "#5DADE2"
    readonly property color cyanB: "#85C5E8"
    readonly property color cyanD: "#3A7CA5"
    readonly property color warn: "#FF6B6B"
    readonly property color good: "#5DE285"

    property bool ready: false
    property bool serviceOnline: false
    property bool adapterAvailable: false
    property bool powered: false
    property bool discovering: false
    property string adapterName: "NO ADAPTER"
    property string adapterAddress: "--"
    property var devices: []
    property string note: ""

    readonly property string helper: "$HOME/.local/bin/index-bluetooth"

    function refresh(): void {
        if (!snapshotProc.running) snapshotProc.running = true
    }
    function runAction(args, label): void {
        actionProc.command = ["sh", "-c", bt.helper + " " + args + " >/dev/null 2>&1"]
        actionProc.actionLabel = label
        actionProc.started = true
        actionProc.running = true
    }

    onVisibleChanged: if (visible) { ready = false; refresh() }
    Component.onCompleted: if (visible) refresh()

    Process {
        id: snapshotProc
        command: ["sh", "-c", bt.helper + " snapshot 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = text.trim().split("\n")
                var sawState = false
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue
                    var f = lines[i].split("\t")
                    if (f[0] === "STATE" && f.length >= 7) {
                        sawState = true
                        bt.serviceOnline = f[1] === "1"
                        bt.adapterAvailable = f[2] === "1"
                        bt.powered = f[3] === "1"
                        bt.discovering = f[4] === "1"
                        bt.adapterName = f[5] || "NO ADAPTER"
                        bt.adapterAddress = f[6] || "--"
                    } else if (f[0] === "DEVICE" && f.length >= 6) {
                        out.push({
                            mac: f[1], paired: f[2] === "1", connected: f[3] === "1",
                            trusted: f[4] === "1", name: f.slice(5).join("\t") || f[1]
                        })
                    }
                }
                if (!sawState) {
                    bt.serviceOnline = false
                    bt.adapterAvailable = false
                    bt.powered = false
                    bt.discovering = false
                    bt.adapterName = "NO ADAPTER"
                    bt.adapterAddress = "--"
                }
                bt.devices = out
                bt.ready = true
            }
        }
    }

    Process {
        id: actionProc
        property bool started: false
        property string actionLabel: ""
        command: ["true"]
        stdout: StdioCollector {}
        onRunningChanged: if (started && !running) {
            started = false
            bt.note = actionLabel + " — verifying state"
            delayedRefresh.restart()
        }
    }

    Process {
        id: scanProc
        property bool started: false
        command: ["sh", "-c", bt.helper + " scan >/dev/null 2>&1"]
        stdout: StdioCollector {}
        onRunningChanged: {
            if (running) {
                started = true
                bt.note = "scanning for devices..."
            } else if (started) {
                started = false
                bt.note = "scan complete"
                delayedRefresh.restart()
            }
        }
    }

    Timer { id: delayedRefresh; interval: 700; repeat: false; onTriggered: bt.refresh() }
    Timer {
        interval: 3500
        repeat: true
        running: bt.visible
        triggeredOnStart: false
        onTriggered: bt.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: bt.embedded ? 14 : 10
        spacing: bt.embedded ? 12 : 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: ">_ BLUETOOTH_"
                font.family: bt.pixel; font.pixelSize: bt.embedded ? 17 : 16; color: bt.cyanB
            }
            Text {
                visible: bt.adapterAvailable
                text: bt.powered ? "[ON]" : "[OFF]"
                font.family: bt.pixel; font.pixelSize: 12
                color: bt.powered ? bt.good : bt.warn
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: bt.serviceOnline && bt.adapterAvailable && !actionProc.running
                    onClicked: bt.runAction("power " + (bt.powered ? "off" : "on"), bt.powered ? "powering off" : "powering on")
                }
            }
            Text {
                text: bt.embedded ? "<_ BACK" : "[X]"
                font.family: bt.pixel; font.pixelSize: bt.embedded ? 11 : 12
                color: bt.embedded ? bt.cyanD : bt.warn
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (bt.embedded) bt.requestBack(); else bt.requestClose() }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: bt.cyanD; opacity: bt.embedded ? 1 : 0.6 }

        Text {
            visible: !bt.ready || !bt.serviceOnline || !bt.adapterAvailable
            Layout.fillWidth: true
            text: !bt.ready ? "CHECKING BLUETOOTH..." : (!bt.serviceOnline ? "BLUETOOTH SERVICE UNAVAILABLE" : "NO BLUETOOTH ADAPTER DETECTED")
            font.family: bt.pixel; font.pixelSize: 10
            color: bt.ready ? bt.warn : bt.cyanD
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            visible: bt.adapterAvailable
            Text { text: "ADAPTER"; font.family: bt.pixel; font.pixelSize: 11; color: bt.cyanD }
            Text {
                Layout.fillWidth: true
                text: "  " + bt.adapterName
                font.family: bt.pixel; font.pixelSize: 11; color: bt.cyanB
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: "  " + bt.adapterAddress
                font.family: bt.pixel; font.pixelSize: 9; color: bt.cyanD
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 30
            opacity: bt.serviceOnline && bt.adapterAvailable ? 1.0 : 0.45
            color: scanProc.running ? bt.cyan : (scanArea.containsMouse ? "#143245" : "transparent")
            border.color: bt.cyanD; border.width: 1
            Text {
                anchors.centerIn: parent
                text: scanProc.running ? "SCANNING..." : "SCAN FOR DEVICES"
                font.family: bt.pixel; font.pixelSize: 11
                color: scanProc.running ? "#04141c" : bt.cyanB
            }
            MouseArea {
                id: scanArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                enabled: bt.serviceOnline && bt.adapterAvailable && !scanProc.running && !actionProc.running
                onClicked: { bt.powered = true; scanProc.running = true }
            }
        }

        Text {
            visible: bt.note !== ""
            Layout.fillWidth: true
            text: bt.note
            font.family: bt.pixel; font.pixelSize: 10; color: bt.cyanD
            wrapMode: Text.WordWrap
        }

        Text {
            visible: bt.ready && bt.serviceOnline && bt.adapterAvailable && bt.devices.length === 0
            Layout.fillWidth: true
            text: bt.powered ? "NO KNOWN DEVICES — START A SCAN" : "BLUETOOTH IS OFF"
            font.family: bt.pixel; font.pixelSize: 10; color: bt.cyanD
        }

        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 4
            model: bt.devices
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width; height: 48
                opacity: bt.powered ? 1.0 : 0.55
                color: deviceArea.containsMouse ? "#143245" : (modelData.connected ? "#0c2634" : "transparent")
                border.color: modelData.connected ? bt.good : bt.cyanD
                border.width: 1

                Column {
                    anchors.left: parent.left; anchors.leftMargin: 8
                    anchors.right: actionText.left; anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        width: parent.width; text: modelData.name
                        font.family: bt.pixel; font.pixelSize: 12
                        color: modelData.connected ? bt.cyanB : bt.cyan
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: modelData.mac + "  " + (modelData.paired ? "paired" : "new") + (modelData.connected ? " · connected" : "")
                        font.family: bt.pixel; font.pixelSize: 8; color: bt.cyanD
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: actionText
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.connected ? "[OFF]" : (modelData.paired ? "[CONNECT]" : "[PAIR]")
                    font.family: bt.pixel; font.pixelSize: 9
                    color: modelData.connected ? bt.warn : bt.cyanB
                }

                MouseArea {
                    id: deviceArea
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    enabled: bt.powered && !actionProc.running && !scanProc.running
                    onClicked: {
                        if (modelData.connected) bt.runAction("disconnect " + modelData.mac, "disconnecting " + modelData.name)
                        else if (modelData.paired) bt.runAction("connect " + modelData.mac, "connecting " + modelData.name)
                        else bt.runAction("pair " + modelData.mac, "pairing " + modelData.name)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 32
            color: advancedArea.containsMouse ? "#143245" : "transparent"
            border.color: bt.cyanD; border.width: 1
            Text { anchors.centerIn: parent; text: "OPEN ADVANCED BLUETOOTH SETTINGS"; font.family: bt.pixel; font.pixelSize: 10; color: bt.cyanB }
            MouseArea {
                id: advancedArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["blueman-manager"])
            }
        }

        Text {
            visible: bt.embedded
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Common headphones, mice and controllers use BlueZ through bluetoothctl. PIN/display pairing, adapter profiles and advanced device management remain in Blueman."
            font.family: bt.pixel; font.pixelSize: 10; color: bt.cyanD
        }
    }
}
