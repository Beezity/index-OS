// ============================================================
//  WILL OF THE CITY :: THE INDEX — top bar
//  Quickshell 0.3+ / labwc. Workspaces use ext-workspace-v1
//  through Quickshell.WindowManager instead of simulated keys.
// ============================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.WindowManager
import Quickshell.Services.SystemTray
import "."

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 32
    color: "transparent"

    readonly property color cyan: "#5DADE2"
    readonly property color cyanB: "#85C5E8"
    readonly property color cyanD: "#3A7CA5"
    readonly property color warn: "#FF6B6B"
    readonly property string pixel: "Perfect DOS VGA 437 Universal"

    property bool menuOpen: false
    property bool settingsOpen: false
    property bool wifiOpen: false
    property bool btOpen: false
    property bool notifOpen: false

    Calendar { id: calPopup }

    IpcHandler {
        target: "startmenu"
        function toggle(): void { bar.menuOpen = !bar.menuOpen; Sfx.play("menu") }
        function open(): void { bar.menuOpen = true }
        function close(): void { bar.menuOpen = false }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    ScriptModel {
        id: workspaceModel
        values: WindowManager.windowsets.values
            .filter(function(ws) { return ws.shouldDisplay })
            .sort(function(a, b) {
                if (a.coordinates.length > 0 && b.coordinates.length > 0)
                    return a.coordinates[0] - b.coordinates[0]
                return a.name.localeCompare(b.name, undefined, { numeric: true })
            })
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0e16"
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: bar.cyan }

        Text {
            anchors.centerIn: parent
            z: 5
            text: Qt.formatDateTime(clock.date, "'_'hh:mm AP'._'")
            font.family: bar.pixel; font.pixelSize: 16
            color: bar.cyanB
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: calPopup.open = !calPopup.open }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: "// THE INDEX"
                font.family: bar.pixel; font.pixelSize: 15
                color: (startArea.containsMouse || bar.menuOpen) ? "#ffffff" : bar.cyanB
                MouseArea {
                    id: startArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { bar.menuOpen = !bar.menuOpen; Sfx.play("menu") }
                }
            }

            RowLayout {
                spacing: 5
                Repeater {
                    model: workspaceModel
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool active: modelData.active
                        implicitWidth: 22; implicitHeight: 20
                        color: active ? bar.cyan : "transparent"
                        border.color: modelData.urgent ? bar.warn : "transparent"
                        border.width: modelData.urgent ? 1 : 0
                        scale: active ? 1.0 : 0.9
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 140 } }
                        Text {
                            anchors.centerIn: parent
                            text: {
                                var m = modelData.name.match(/([0-9]+)$/)
                                return m ? m[1] : String(index + 1)
                            }
                            font.family: bar.pixel; font.pixelSize: 15
                            color: parent.active ? "#04141c" : bar.cyanD
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (modelData.canActivate) modelData.activate()
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.maximumWidth: bar.width * 0.32
                spacing: 4
                Repeater {
                    model: ToplevelManager.toplevels
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isActive: ToplevelManager.activeToplevel === modelData
                        Layout.preferredWidth: Math.min(160, taskLabel.implicitWidth + 18)
                        Layout.minimumWidth: 40
                        Layout.fillWidth: true
                        implicitHeight: 22
                        color: isActive ? bar.cyan : (taskMa.containsMouse ? "#143245" : "#0c1620")
                        border.color: isActive ? bar.cyanB : bar.cyanD
                        border.width: 1
                        Image {
                            id: taskIcon
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 4
                            width: 14; height: 14
                            sourceSize.width: 14; sourceSize.height: 14
                            fillMode: Image.PreserveAspectFit
                            source: Quickshell.iconPath(modelData.appId, "application-x-executable")
                            visible: status === Image.Ready
                        }
                        Text {
                            id: taskLabel
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: taskIcon.visible ? 22 : 6
                            anchors.right: parent.right; anchors.rightMargin: 6
                            text: modelData.title || modelData.appId || "window"
                            font.family: bar.pixel; font.pixelSize: 12
                            color: parent.isActive ? "#04141c" : bar.cyanB
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: taskMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.activate()
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 10

                Text {
                    id: kbText
                    property string layout: "EN"
                    text: "[" + layout + "]"
                    font.family: bar.pixel; font.pixelSize: 13; color: bar.cyanD
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { Quickshell.execDetached(["fcitx5-remote", "-t"]); kbPoll.restart() }
                    }
                }
                Process {
                    id: kbGet
                    command: ["sh", "-c", "fcitx5-remote -n 2>/dev/null || echo keyboard-us"]
                    stdout: StdioCollector { onStreamFinished: {
                        var n = text.trim().replace(/^keyboard-/, "").toUpperCase()
                        kbText.layout = n.length > 0 ? n.substring(0, 3) : "EN"
                    } }
                }
                Timer { id: kbPoll; interval: 150; repeat: false; onTriggered: kbGet.running = true }
                Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: kbGet.running = true }

                Text {
                    text: "[!]"
                    font.family: bar.pixel; font.pixelSize: 13
                    color: bar.notifOpen ? bar.cyanB : bar.cyanD
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { bar.notifOpen = !bar.notifOpen; Sfx.play("menu") } }
                }

                RowLayout {
                    spacing: 4
                    visible: mediaText.status !== ""
                    Text {
                        text: mediaText.status === "Playing" ? "[>]" : "[||]"
                        font.family: bar.pixel; font.pixelSize: 13; color: bar.cyanD
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["playerctl", "play-pause"]) }
                    }
                    Text {
                        id: mediaText
                        property string status: ""
                        property string title: ""
                        text: title
                        font.family: bar.pixel; font.pixelSize: 13; color: bar.cyanD
                        elide: Text.ElideRight; Layout.maximumWidth: 160
                    }
                }
                Process {
                    id: mediaGet
                    command: ["sh", "-c", "s=$(playerctl status 2>/dev/null || true); t=$(playerctl metadata --format '{{artist}} — {{title}}' 2>/dev/null || true); printf '%s\\n%s' \"$s\" \"$t\""]
                    stdout: StdioCollector { onStreamFinished: {
                        var lines = text.split("\n")
                        mediaText.status = (lines[0] || "").trim()
                        mediaText.title = (lines[1] || "").trim().substring(0, 42)
                    } }
                }

                Text {
                    id: netText
                    property string ssid: ""
                    text: ssid === "" ? "NET --" : "NET " + ssid
                    font.family: bar.pixel; font.pixelSize: 13
                    color: ssid === "" ? bar.warn : bar.cyanD
                    elide: Text.ElideRight; Layout.maximumWidth: 150
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { bar.wifiOpen = !bar.wifiOpen; if (bar.wifiOpen) scanProc.running = true; Sfx.play("menu") } }
                }
                Process {
                    id: netProc
                    command: ["sh", "-c", "nmcli -t -f NAME connection show --active 2>/dev/null | head -1"]
                    stdout: StdioCollector { onStreamFinished: netText.ssid = text.trim() }
                }

                Text {
                    id: btText
                    property bool powered: false
                    text: powered ? "BT ON" : "BT --"
                    font.family: bar.pixel; font.pixelSize: 13
                    color: powered ? bar.cyan : bar.cyanD
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { bar.btOpen = !bar.btOpen; Sfx.play("menu") } }
                }
                Process {
                    id: btProc
                    command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 1 || echo 0"]
                    stdout: StdioCollector { onStreamFinished: btText.powered = text.trim() === "1" }
                }

                Text {
                    id: batText
                    property int pct: -1
                    property bool charging: false
                    visible: pct >= 0
                    text: (charging ? "BAT+ " : "BAT ") + pct + "%"
                    font.family: bar.pixel; font.pixelSize: 13
                    color: pct <= 15 && !charging ? bar.warn : bar.cyanD
                }
                Process {
                    id: batProc
                    command: ["sh", "-c", "for c in /sys/class/power_supply/BAT*; do [ -f \"$c/capacity\" ] || continue; printf '%s %s' \"$(cat \"$c/capacity\")\" \"$(cat \"$c/status\")\"; exit; done; echo '-1 none'"]
                    stdout: StdioCollector { onStreamFinished: {
                        var p = text.trim().split(/\s+/)
                        batText.pct = parseInt(p[0])
                        batText.charging = p[1] === "Charging" || p[1] === "Full"
                    } }
                }

                Text {
                    id: volText
                    property int vol: 50
                    property bool muted: false
                    text: muted ? "VOL MUTE" : "VOL " + vol
                    font.family: bar.pixel; font.pixelSize: 13
                    color: muted ? bar.warn : bar.cyanD
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(m) {
                            if (m.button === Qt.RightButton) { bar.settingsOpen = !bar.settingsOpen; Sfx.play("menu"); return }
                            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                            volProc.running = true
                        }
                        onWheel: function(w) {
                            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", w.angleDelta.y > 0 ? "5%+" : "5%-"])
                            volProc.running = true
                        }
                    }
                }
                Process {
                    id: volProc
                    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
                    stdout: StdioCollector { onStreamFinished: {
                        var m = text.match(/([0-9.]+)/)
                        if (m) volText.vol = Math.round(parseFloat(m[1]) * 100)
                        volText.muted = text.indexOf("MUTED") >= 0
                    } }
                }

                Repeater {
                    model: SystemTray.items
                    delegate: Image {
                        id: trayIcon
                        required property var modelData
                        source: modelData.icon
                        width: 16; height: 16; sourceSize.width: 16; sourceSize.height: 16
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(m) {
                                if (m.button === Qt.LeftButton) modelData.activate()
                                else if (modelData.hasMenu) modelData.display(bar, trayIcon.mapToItem(null, 8, 16).x, bar.implicitHeight)
                            }
                        }
                    }
                }

                Text { text: Qt.formatDateTime(clock.date, "ddd dd MMM").toUpperCase(); font.family: bar.pixel; font.pixelSize: 13; color: bar.cyanD }

                Timer {
                    interval: 5000; running: true; repeat: true; triggeredOnStart: true
                    onTriggered: { netProc.running = true; btProc.running = true; batProc.running = true; mediaGet.running = true; volProc.running = true }
                }
            }
        }
    }

    PanelWindow {
        id: menuDismiss
        visible: bar.menuOpen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"; exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "index-menu-dismiss"
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: bar.menuOpen = false }
    }

    PanelWindow {
        id: wifiMenu
        visible: bar.wifiOpen
        anchors { top: true; right: true }
        margins { top: bar.implicitHeight; right: 8 }
        implicitWidth: 320; implicitHeight: 380
        color: "transparent"; exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "index-wifi"
        property var nets: []
        property string pending: ""

        Process {
            id: scanProc
            command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "yes"]
            stdout: StdioCollector { onStreamFinished: {
                var out = []
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length && out.length < 20; i++) {
                    if (!lines[i]) continue
                    var f = lines[i].split(":")
                    if (f.length < 4) continue
                    var ssid = f.slice(3).join(":").replace(/\\:/g, ":").replace(/\\\\/g, "\\")
                    if (!ssid) continue
                    out.push({ active: f[0] === "*", signal: parseInt(f[1]) || 0, secure: (f[2] || "").trim() !== "", ssid: ssid })
                }
                wifiMenu.nets = out
            } }
        }

        Rectangle {
            anchors.fill: parent; color: "#0a0e16"; border.color: bar.cyan; border.width: 2
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: ">_ NETWORKS_"; font.family: bar.pixel; font.pixelSize: 16; color: bar.cyanB }
                    Item { Layout.fillWidth: true }
                    Text { text: "[SCAN]"; font.family: bar.pixel; font.pixelSize: 12; color: bar.cyan; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: scanProc.running = true } }
                    Text { text: "[X]"; font.family: bar.pixel; font.pixelSize: 12; color: bar.warn; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bar.wifiOpen = false } }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: bar.cyanD }
                Rectangle {
                    Layout.fillWidth: true; height: 34; visible: wifiMenu.pending !== ""
                    color: "#0c1620"; border.color: bar.cyan; border.width: 1
                    TextInput {
                        id: wifiPass
                        anchors.fill: parent; anchors.margins: 7
                        font.family: bar.pixel; font.pixelSize: 13; color: bar.cyanB
                        echoMode: TextInput.Password
                        onAccepted: {
                            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", wifiMenu.pending, "password", text])
                            wifiMenu.pending = ""; text = ""
                            rescanTimer.restart()
                        }
                    }
                    Text { anchors.left: parent.left; anchors.leftMargin: 7; anchors.verticalCenter: parent.verticalCenter; visible: wifiPass.text === ""; text: "password for " + wifiMenu.pending; font.family: bar.pixel; font.pixelSize: 12; color: bar.cyanD }
                }
                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 3
                    model: wifiMenu.nets
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width; height: 30
                        color: netArea.containsMouse ? "#143245" : (modelData.active ? "#0c2634" : "transparent")
                        Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 80; elide: Text.ElideRight; text: (modelData.active ? "* " : "  ") + modelData.ssid; font.family: bar.pixel; font.pixelSize: 13; color: modelData.active ? bar.cyanB : bar.cyan }
                        Text { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: (modelData.secure ? "[#] " : "") + modelData.signal; font.family: bar.pixel; font.pixelSize: 11; color: bar.cyanD }
                        MouseArea {
                            id: netArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.active) return
                                if (modelData.secure) { wifiMenu.pending = modelData.ssid; wifiPass.forceActiveFocus() }
                                else { Quickshell.execDetached(["nmcli", "device", "wifi", "connect", modelData.ssid]); rescanTimer.restart() }
                            }
                        }
                    }
                }
            }
        }
        Timer { id: rescanTimer; interval: 2000; repeat: false; onTriggered: { scanProc.running = true; netProc.running = true } }
        Keys.onEscapePressed: bar.wifiOpen = false
    }

    PanelWindow {
        visible: bar.notifOpen
        anchors { top: true; right: true }
        margins { top: bar.implicitHeight; right: 8 }
        implicitWidth: 360; implicitHeight: 440
        color: "transparent"; exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "index-notif-history"
        Rectangle {
            anchors.fill: parent; color: "#0a0e16"; border.color: bar.cyan; border.width: 2
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: ">_ NOTIFICATIONS_"; font.family: bar.pixel; font.pixelSize: 16; color: bar.cyanB }
                    Item { Layout.fillWidth: true }
                    Text { text: "[CLEAR]"; font.family: bar.pixel; font.pixelSize: 11; color: bar.cyanD; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: NotifHistory.clear() } }
                    Text { text: "[X]"; font.family: bar.pixel; font.pixelSize: 12; color: bar.warn; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bar.notifOpen = false } }
                }
                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
                    model: NotifHistory.items
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width; height: notifCol.implicitHeight + 12
                        color: "#0c1620"; border.color: modelData.critical ? bar.warn : bar.cyanD; border.width: 1
                        Column {
                            id: notifCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 7; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Text { text: modelData.time + "  " + modelData.app; font.family: bar.pixel; font.pixelSize: 9; color: bar.cyanD }
                            Text { width: parent.width; text: modelData.summary; font.family: bar.pixel; font.pixelSize: 13; color: modelData.critical ? bar.warn : bar.cyanB; wrapMode: Text.WordWrap }
                            Text { width: parent.width; visible: (modelData.body || "") !== ""; text: modelData.body; font.family: bar.pixel; font.pixelSize: 11; color: bar.cyan; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        visible: bar.btOpen
        anchors { top: true; right: true }
        margins { top: bar.implicitHeight; right: 8 }
        implicitWidth: 340; implicitHeight: 420
        color: "transparent"; exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "index-bluetooth"
        BluetoothMenu { anchors.fill: parent; onRequestClose: bar.btOpen = false }
    }

    PanelWindow {
        id: startMenu
        visible: bar.menuOpen
        anchors { top: true; left: true }
        margins { top: bar.implicitHeight; left: 8 }
        implicitWidth: 340; implicitHeight: 480
        color: "transparent"; exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "index-startmenu"
        property string query: ""
        property var shownApps: {
            var all = DesktopEntries.applications.values || []
            var q = query.toLowerCase()
            return q.length === 0 ? all : all.filter(function(a) { return (a.name || "").toLowerCase().indexOf(q) >= 0 })
        }
        onVisibleChanged: if (visible) { search.text = ""; query = ""; appList.currentIndex = 0; search.forceActiveFocus() }
        function launchCurrent(): void {
            if (shownApps.length === 0) return
            var i = Math.max(0, Math.min(appList.currentIndex, shownApps.length - 1))
            shownApps[i].execute(); bar.menuOpen = false
        }

        Rectangle {
            anchors.fill: parent; color: "#05080d"; border.color: bar.cyan; border.width: 2
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 8
                Text { text: ">_ THE INDEX // START_"; font.family: bar.pixel; font.pixelSize: 16; color: bar.cyanB }
                Rectangle { Layout.fillWidth: true; height: 1; color: bar.cyanD }
                Rectangle {
                    Layout.fillWidth: true; height: 32; color: "#0a0e16"; border.color: bar.cyanD; border.width: 1
                    TextInput {
                        id: search
                        anchors.fill: parent; anchors.margins: 8
                        font.family: bar.pixel; font.pixelSize: 15; color: bar.cyanB
                        onTextChanged: { startMenu.query = text; appList.currentIndex = 0 }
                        Keys.onEscapePressed: bar.menuOpen = false
                        Keys.onDownPressed: appList.incrementCurrentIndex()
                        Keys.onUpPressed: appList.decrementCurrentIndex()
                        Keys.onReturnPressed: startMenu.launchCurrent()
                        Keys.onEnterPressed: startMenu.launchCurrent()
                        Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; visible: search.text.length === 0; text: "search._"; color: bar.cyanD; font.family: bar.pixel; font.pixelSize: 15 }
                    }
                }
                ListView {
                    id: appList
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    model: startMenu.shownApps; currentIndex: 0; keyNavigationWraps: true
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool selected: appList.currentIndex === index
                        width: appList.width; height: 30
                        color: (appArea.containsMouse || selected) ? bar.cyanD : "transparent"
                        Image { id: appIcon; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; width: 18; height: 18; sourceSize.width: 18; sourceSize.height: 18; source: Quickshell.iconPath(modelData.icon, "application-x-executable"); visible: status === Image.Ready }
                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: appIcon.visible ? 32 : 8; width: parent.width - 40; text: modelData.name; font.family: bar.pixel; font.pixelSize: 15; color: (appArea.containsMouse || parent.selected) ? "#04141c" : bar.cyanB; elide: Text.ElideRight }
                        MouseArea { id: appArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: appList.currentIndex = index; onClicked: { modelData.execute(); bar.menuOpen = false } }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Repeater {
                        model: [
                            { label: "LOGOUT", cmd: ["sh", "-c", "$HOME/.config/labwc/index-logout"] },
                            { label: "SLEEP", cmd: ["systemctl", "suspend"], laptop: true },
                            { label: "REBOOT", cmd: ["systemctl", "reboot"] },
                            { label: "OFF", cmd: ["systemctl", "poweroff"] }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            visible: !modelData.laptop || batText.pct >= 0
                            Layout.fillWidth: true; height: 30; color: powerArea.containsMouse ? bar.warn : "transparent"; border.color: bar.warn; border.width: 1
                            Text { anchors.centerIn: parent; text: modelData.label; font.family: bar.pixel; font.pixelSize: 12; color: powerArea.containsMouse ? "#04141c" : bar.warn }
                            MouseArea { id: powerArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(modelData.cmd); bar.menuOpen = false } }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        visible: bar.settingsOpen
        anchors { top: true; right: true }
        margins { top: bar.implicitHeight; right: 8 }
        implicitWidth: 340; implicitHeight: 920
        color: "transparent"; exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "index-settings"
        SettingsPanel { anchors.fill: parent; onRequestClose: bar.settingsOpen = false }
    }
}
