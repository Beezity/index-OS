// WILL OF THE CITY :: THE INDEX — network settings subpanel
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
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/index-network"

    property bool ready: false
    property bool serviceOnline: false
    property bool networkingEnabled: false
    property bool wifiAvailable: false
    property bool wifiEnabled: false
    property string connectionName: "NO CONNECTION"
    property string connectionType: "unknown"
    property string deviceName: ""
    property string connectivity: "unknown"
    property int signalStrength: 0
    property string ipv4Address: "--"
    property bool scanRequested: false
    property bool scanning: false

    readonly property bool connected: serviceOnline && deviceName !== "" && connectionName !== "NO CONNECTION"
    readonly property bool wifiConnected: connected && connectionType === "wifi"

    function run(args) { Quickshell.execDetached([root.helper].concat(args)) }
    function refresh() { if (!stateGet.running) stateGet.running = true }
    function maybeScan() {
        if (root.visible && root.ready && root.serviceOnline && root.networkingEnabled && root.wifiAvailable && root.wifiEnabled && !root.scanRequested) {
            root.scanRequested = true
            if (!scanProc.running) scanProc.running = true
        }
    }

    onVisibleChanged: {
        if (visible) {
            ready = false
            scanRequested = false
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
                if (f.length >= 10) {
                    root.serviceOnline = f[0] === "1"
                    root.networkingEnabled = f[1] === "1"
                    root.wifiAvailable = f[2] === "1"
                    root.wifiEnabled = f[3] === "1"
                    root.connectionName = f[4] || "NO CONNECTION"
                    root.connectionType = f[5] || "unknown"
                    root.deviceName = f[6] || ""
                    root.connectivity = f[7] || "unknown"
                    var s = parseInt(f[8]); root.signalStrength = isNaN(s) ? 0 : s
                    root.ipv4Address = f.slice(9).join("\t") || "--"
                } else {
                    root.serviceOnline = false
                    root.networkingEnabled = false
                    root.wifiAvailable = false
                    root.wifiEnabled = false
                    root.connectionName = "NO CONNECTION"
                    root.connectionType = "unknown"
                    root.deviceName = ""
                    root.connectivity = "unknown"
                    root.signalStrength = 0
                    root.ipv4Address = "--"
                }
                root.ready = true
                root.maybeScan()
            }
        }
    }

    Process {
        id: scanProc
        property bool started: false
        command: [root.helper, "scan-wifi"]
        stdout: StdioCollector {}
        onRunningChanged: {
            if (running) {
                started = true
                root.scanning = true
            } else if (started) {
                started = false
                root.scanning = false
                delayedRefresh.restart()
            }
        }
    }
    Process {
        id: wifiChooser
        property bool started: false
        command: [root.helper, "choose-wifi"]
        stdout: StdioCollector {}
        onRunningChanged: {
            if (running) started = true
            else if (started) {
                started = false
                delayedRefresh.restart()
            }
        }
    }

    Timer {
        interval: 6000
        repeat: true
        running: root.visible
        onTriggered: root.refresh()
    }
    Timer {
        id: delayedRefresh
        interval: 700
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
                text: ">_ NETWORK_"
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
            text: !root.ready ? "CHECKING NETWORK..." : "NETWORKMANAGER UNAVAILABLE"
            font.family: root.pixel; font.pixelSize: 10
            color: root.ready ? root.warn : root.cyanD
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "NETWORKING"
                font.family: root.pixel; font.pixelSize: 13; color: root.cyanB
            }
            Rectangle {
                width: 78; height: 28
                opacity: root.serviceOnline ? 1.0 : 0.45
                color: root.networkingEnabled ? root.cyan : "transparent"
                border.color: root.cyanD; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: root.networkingEnabled ? "ON" : "OFF"
                    font.family: root.pixel; font.pixelSize: 11
                    color: root.networkingEnabled ? "#04141c" : root.cyanB
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: root.serviceOnline
                    onClicked: {
                        root.networkingEnabled = !root.networkingEnabled
                        root.run(["toggle-networking"])
                        delayedRefresh.restart()
                    }
                }
            }
        }

        Text {
            visible: root.serviceOnline && !root.networkingEnabled
            Layout.fillWidth: true
            text: "NETWORKING IS DISABLED"
            font.family: root.pixel; font.pixelSize: 10; color: root.warn
        }

        Text { text: "CONNECTION"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        Text {
            Layout.fillWidth: true
            text: "  " + root.connectionName
            elide: Text.ElideRight
            font.family: root.pixel; font.pixelSize: 11
            color: root.connected ? root.cyanB : root.cyanD
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8; rowSpacing: 5
            Text { text: "TYPE"; font.family: root.pixel; font.pixelSize: 10; color: root.cyanD }
            Text { Layout.fillWidth: true; text: root.connectionType.toUpperCase(); font.family: root.pixel; font.pixelSize: 10; color: root.cyanB; horizontalAlignment: Text.AlignRight }
            Text { text: "DEVICE"; font.family: root.pixel; font.pixelSize: 10; color: root.cyanD }
            Text { Layout.fillWidth: true; text: root.deviceName || "--"; font.family: root.pixel; font.pixelSize: 10; color: root.cyanB; horizontalAlignment: Text.AlignRight }
            Text { text: "STATUS"; font.family: root.pixel; font.pixelSize: 10; color: root.cyanD }
            Text { Layout.fillWidth: true; text: root.connectivity.toUpperCase(); font.family: root.pixel; font.pixelSize: 10; color: root.connectivity === "full" ? root.cyanB : root.cyanD; horizontalAlignment: Text.AlignRight }
            Text { text: "IPv4"; font.family: root.pixel; font.pixelSize: 10; color: root.cyanD }
            Text { Layout.fillWidth: true; text: root.ipv4Address; font.family: root.pixel; font.pixelSize: 10; color: root.cyanB; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.wifiConnected
            Text {
                text: "WI-FI SIGNAL  " + root.signalStrength + "%"
                font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
            }
            Rectangle {
                Layout.fillWidth: true; height: 14
                color: "#04141c"; border.color: root.cyanD; border.width: 1
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    anchors.margins: 2
                    width: Math.max(0, (parent.width - 4) * root.signalStrength / 100)
                    color: root.cyan
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        RowLayout {
            Layout.fillWidth: true
            visible: root.wifiAvailable
            Text {
                Layout.fillWidth: true
                text: "WI-FI"
                font.family: root.pixel; font.pixelSize: 13; color: root.cyanB
            }
            Rectangle {
                width: 78; height: 28
                opacity: root.serviceOnline && root.networkingEnabled ? 1.0 : 0.45
                color: root.wifiEnabled ? root.cyan : "transparent"
                border.color: root.cyanD; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: root.wifiEnabled ? "ON" : "OFF"
                    font.family: root.pixel; font.pixelSize: 11
                    color: root.wifiEnabled ? "#04141c" : root.cyanB
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: root.serviceOnline && root.networkingEnabled
                    onClicked: {
                        root.wifiEnabled = !root.wifiEnabled
                        root.run(["toggle-wifi"])
                        delayedRefresh.restart()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 6
            visible: root.wifiAvailable
            Rectangle {
                Layout.fillWidth: true; height: 34
                opacity: root.serviceOnline && root.networkingEnabled && root.wifiEnabled ? 1.0 : 0.45
                color: wifiArea.containsMouse ? "#143245" : "#0c1620"
                border.color: root.cyanD; border.width: 1
                Text { anchors.centerIn: parent; text: root.scanning ? "SCANNING WI-FI..." : (root.wifiConnected ? "CHANGE WI-FI" : "CONNECT WI-FI"); font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                MouseArea {
                    id: wifiArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    enabled: root.serviceOnline && root.networkingEnabled && root.wifiEnabled && !root.scanning && !wifiChooser.running
                    onClicked: if (!wifiChooser.running) wifiChooser.running = true
                }
            }
            Rectangle {
                width: 96; height: 34
                opacity: root.wifiConnected ? 1.0 : 0.45
                color: disconnectArea.containsMouse ? "#143245" : "transparent"
                border.color: root.cyanD; border.width: 1
                Text { anchors.centerIn: parent; text: "DISCONNECT"; font.family: root.pixel; font.pixelSize: 10; color: root.cyanB }
                MouseArea {
                    id: disconnectArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    enabled: root.wifiConnected
                    onClicked: { root.run(["disconnect"]); delayedRefresh.restart() }
                }
            }
        }

        Text {
            visible: root.ready && root.serviceOnline && !root.wifiAvailable
            Layout.fillWidth: true
            text: root.connected ? "NO WI-FI ADAPTER DETECTED — USING WIRED/OTHER NETWORK" : "NO WI-FI ADAPTER DETECTED"
            wrapMode: Text.WordWrap
            font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        Rectangle {
            Layout.fillWidth: true; height: 34
            color: advancedArea.containsMouse ? "#143245" : "transparent"
            border.color: root.cyanD; border.width: 1
            Text { anchors.centerIn: parent; text: "OPEN ADVANCED NETWORK SETTINGS"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
            MouseArea {
                id: advancedArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Wi-Fi, simple connections and live status use NetworkManager through nmcli. VPNs, enterprise Wi-Fi, static addressing and custom authentication remain in the advanced editor."
            font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
        }

        Item { Layout.fillHeight: true }
    }
}
