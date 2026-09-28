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
        values: WindowManager.windowsets
            .filter(function(ws) { return ws.shouldDisplay })
            .sort(function(a, b) {
                if (a.coordinates.length > 0 && b.coordinates.length > 0)
                    return a.coordinates[0] - b.coordinates[0]
                return a.name.localeCompare(b.name)
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
                color: startArea.containsMouse || bar.menuOpen ? "#ffffff" : bar.cyanB
                MouseArea {
                    id: startArea
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: if (modelData.canActivate) modelData.activate()
                        }
                    }
                }
            }

            RowLayout {
                Layout.maximumWidth: bar.width * 0.32
                spacing: 4
                Repeater {
                    model: ToplevelManager.toplevels
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isActive: ToplevelManager.activeToplevel === modelData
                        readonly property string rawTitle: modelData.title || modelData.appId || "window"
                        readonly property string displayTitle: rawTitle.length > 18 ? rawTitle.slice(0, 15) + "..." : rawTitle
                        Layout.preferredWidth: Math.min(160, taskLabel.implicitWidth + 26)
                        Layout.minimumWidth: 40
                        implicitHeight: 22
                        color: isActive ? bar.cyan : (taskArea.containsMouse ? "#143245" : "#0c1620")
                        border.color: isActive ? bar.cyanB : bar.cyanD; border.width: 1
                        Image {
                            id: taskIcon
                            anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
                            width: 14; height: 14; sourceSize.width: 14; sourceSize.height: 14
                            source: Quickshell.iconPath(modelData.appId, "application-x-executable")
                            visible: status === Image.Ready
                        }
                        Text {
                            id: taskLabel
                            anchors.left: parent.left; anchors.leftMargin: taskIcon.visible ? 22 : 6
                            anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                            text: parent.displayTitle
                            font.family: bar.pixel; font.pixelSize: 12
                            color: parent.isActive ? "#04141c" : bar.cyanB
                            clip: true
                        }
                        MouseArea { id: taskArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.activate() }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 10

                Text {
                    text: "[!]"
                    font.family: bar.pixel; font.pixelSize: 13
                    color: bar.notifOpen ? bar.cyanB : bar.cyanD
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { bar.notifOpen = !bar.notifOpen; Sfx.play("menu") } }
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
                        batText.pct = parseInt(p[0]); batText.charging = p[1] === "Charging" || p[1] === "Full"
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
                            anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(m) {
                                if (m.button === Qt.LeftButton) modelData.activate()
                                else if (modelData.hasMenu) {
                                    var p = trayIcon.mapToItem(null, 8, 16)
                                    modelData.display(bar, p.x, bar.implicitHeight)
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "SET"
                    font.family: bar.pixel; font.pixelSize: 13
                    color: settingsArea.containsMouse || bar.settingsOpen ? bar.cyanB : bar.cyanD
                    MouseArea {
                        id: settingsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { bar.settingsOpen = !bar.settingsOpen; Sfx.play("menu") }
                    }
                }

                Timer {
                    interval: 5000; running: !bar.settingsOpen; repeat: true; triggeredOnStart: true
                    onTriggered: {
                        if (!batProc.running) batProc.running = true
                    }
                }
            }
        }
    }

    PanelWindow {
        visible: bar.menuOpen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"; exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "index-menu-dismiss"
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: bar.menuOpen = false }
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
                            Text { text: modelData.time + "  " + modelData.app; textFormat: Text.PlainText; font.family: bar.pixel; font.pixelSize: 9; color: bar.cyanD }
                            Text { width: parent.width; text: modelData.summary; textFormat: Text.PlainText; font.family: bar.pixel; font.pixelSize: 13; color: modelData.critical ? bar.warn : bar.cyanB; wrapMode: Text.WordWrap }
                            Text { width: parent.width; visible: (modelData.body || "") !== ""; text: modelData.body; textFormat: Text.PlainText; font.family: bar.pixel; font.pixelSize: 11; color: bar.cyan; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight }
                        }
                    }
                }
            }
        }
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
                        color: appArea.containsMouse || selected ? bar.cyanD : "transparent"
                        Image { id: appIcon; anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; sourceSize.width: 18; sourceSize.height: 18; source: Quickshell.iconPath(modelData.icon, "application-x-executable"); visible: status === Image.Ready }
                        Text { anchors.left: parent.left; anchors.leftMargin: appIcon.visible ? 32 : 8; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 40; text: modelData.name; font.family: bar.pixel; font.pixelSize: 15; color: appArea.containsMouse || parent.selected ? "#04141c" : bar.cyanB; elide: Text.ElideRight }
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
                            Layout.fillWidth: true; height: 30
                            color: powerArea.containsMouse ? bar.warn : "transparent"; border.color: bar.warn; border.width: 1
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
