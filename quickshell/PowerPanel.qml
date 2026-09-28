// WILL OF THE CITY :: THE INDEX — power settings subpanel
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

    property bool profileAvailable: false
    property string activeProfile: "unavailable"
    property var profiles: []
    property bool batteryPresent: false
    property int batteryPct: -1
    property string batteryState: "none"
    property int batteryTimeMin: -1
    property bool brightnessAvailable: false
    property int brightness: 50
    property bool lidPresent: false
    property string lidAction: "suspend"
    property int screenSeconds: 600
    property bool ready: false

    function run(args) {
        Quickshell.execDetached(["sh", "-c", "$HOME/.local/bin/index-power " + args])
        actionRefresh.restart()
    }

    function refresh() {
        if (!stateGet.running) stateGet.running = true
    }

    function hasProfile(name) {
        return root.profiles.indexOf(name) >= 0
    }

    Component.onCompleted: refresh()
    onVisibleChanged: if (visible) refresh()

    Process {
        id: stateGet
        command: ["sh", "-c", "$HOME/.local/bin/index-power state 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.replace(/[\r\n]+$/, "")
                var f = line.split("\t")
                if (f.length < 7) {
                    root.ready = false
                    return
                }
                root.profileAvailable = f[0] === "1"
                root.activeProfile = f[1] || "unavailable"
                root.profiles = f[2] ? f[2].split(",").filter(function(x) { return x !== "" }) : []

                var b = f[3].split("|")
                root.batteryPresent = b[0] === "1"
                var bp = parseInt(b[1]); root.batteryPct = isNaN(bp) ? -1 : bp
                root.batteryState = b[2] || "none"
                var bt = parseInt(b[3]); root.batteryTimeMin = isNaN(bt) ? -1 : bt

                var br = f[4].split("|")
                root.brightnessAvailable = br[0] === "1"
                var bv = parseInt(br[1]); if (!isNaN(bv)) root.brightness = bv

                var l = f[5].split("|")
                root.lidPresent = l[0] === "1"
                root.lidAction = l[1] || "suspend"

                var sec = parseInt(f[6]); if (!isNaN(sec)) root.screenSeconds = sec
                root.ready = true
            }
        }
    }

    Timer { id: actionRefresh; interval: 700; repeat: false; onTriggered: root.refresh() }
    Timer { interval: 5000; running: root.visible; repeat: true; onTriggered: root.refresh() }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 11

        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: ">_ POWER_"; font.family: root.pixel; font.pixelSize: 17; color: root.cyanB }
            Text {
                text: "<_ BACK"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.requestBack() }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        Text {
            visible: !root.ready
            text: "POWER STATE UNAVAILABLE"
            font.family: root.pixel; font.pixelSize: 11; color: root.warn
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 5
            Text { text: "POWER PROFILE"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
            Text {
                visible: !root.profileAvailable
                text: "  profile backend unavailable"
                font.family: root.pixel; font.pixelSize: 10; color: root.warn
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Repeater {
                    model: [
                        { id: "power-saver", label: "SAVER" },
                        { id: "balanced", label: "BALANCED" },
                        { id: "performance", label: "PERFORMANCE" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; height: 30
                        readonly property bool supported: root.hasProfile(modelData.id)
                        readonly property bool on: root.activeProfile === modelData.id
                        color: on ? root.cyan : (profileMa.containsMouse && supported ? "#143245" : "transparent")
                        border.color: supported ? root.cyanD : "#24313a"; border.width: 1
                        Text {
                            anchors.centerIn: parent; text: modelData.label
                            font.family: root.pixel; font.pixelSize: 9
                            color: parent.on ? "#04141c" : (parent.supported ? root.cyanB : "#42515c")
                        }
                        MouseArea {
                            id: profileMa; anchors.fill: parent; hoverEnabled: true
                            enabled: parent.supported
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: { root.activeProfile = modelData.id; root.run("set-profile " + modelData.id) }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            visible: root.batteryPresent
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "BATTERY  " + root.batteryPct + "%"
                    font.family: root.pixel; font.pixelSize: 13
                    color: root.batteryPct <= 15 && root.batteryState !== "charging" ? root.warn : root.cyanB
                }
                Text {
                    text: root.batteryState === "charging" ? "CHARGING" :
                          (root.batteryTimeMin > 0 ? Math.floor(root.batteryTimeMin / 60) + "h " + (root.batteryTimeMin % 60) + "m" : root.batteryState.toUpperCase())
                    font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
                }
            }
            Rectangle {
                Layout.fillWidth: true; height: 14; color: "#05080d"; border.color: root.cyanD
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 2
                    width: Math.max(0, (parent.width - 4) * Math.max(0, root.batteryPct) / 100)
                    color: root.batteryPct <= 15 && root.batteryState !== "charging" ? root.warn : root.cyan
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            visible: root.brightnessAvailable
            Text { text: "BRIGHTNESS  " + root.brightness + "%"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
            Rectangle {
                Layout.fillWidth: true; height: 18; color: "#04141c"; border.color: root.cyanD; border.width: 1
                Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 2; width: (parent.width - 4) * root.brightness / 100; color: root.cyanB }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    function setFromX(mx) { root.brightness = Math.max(5, Math.min(100, Math.round(mx / width * 100))) }
                    onPressed: function(m) { setFromX(m.x) }
                    onPositionChanged: function(m) { if (pressed) setFromX(m.x) }
                    onReleased: root.run("set-brightness " + root.brightness)
                    onWheel: function(w) { root.brightness = Math.max(5, Math.min(100, root.brightness + (w.angleDelta.y > 0 ? 5 : -5))); root.run("set-brightness " + root.brightness) }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            Text { text: "SCREEN OFF AFTER"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Repeater {
                    model: [ {s:60,l:"1m"}, {s:300,l:"5m"}, {s:600,l:"10m"}, {s:1800,l:"30m"}, {s:0,l:"NEVER"} ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; height: 27
                        readonly property bool on: root.screenSeconds === modelData.s
                        color: on ? root.cyan : (screenMa.containsMouse ? "#143245" : "transparent")
                        border.color: root.cyanD; border.width: 1
                        Text { anchors.centerIn: parent; text: modelData.l; font.family: root.pixel; font.pixelSize: 10; color: parent.on ? "#04141c" : root.cyanB }
                        MouseArea { id: screenMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.screenSeconds = modelData.s; root.run("set-screen-seconds " + modelData.s) } }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            visible: root.lidPresent
            Text { text: "WHEN LID CLOSES"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
            Text { text: "  applies after next login/reboot"; font.family: root.pixel; font.pixelSize: 10; color: root.cyanD }
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                Repeater {
                    model: [ {id:"suspend",l:"SLEEP"}, {id:"lock",l:"LOCK"}, {id:"ignore",l:"NOTHING"} ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; height: 28
                        readonly property bool on: root.lidAction === modelData.id
                        color: on ? root.cyan : (lidMa.containsMouse ? "#143245" : "transparent")
                        border.color: root.cyanD
                        Text { anchors.centerIn: parent; text: modelData.l; font.family: root.pixel; font.pixelSize: 10; color: parent.on ? "#04141c" : root.cyanB }
                        MouseArea { id: lidMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.lidAction = modelData.id; root.run("set-lid-action " + modelData.id) } }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Rectangle {
                Layout.fillWidth: true; height: 34; color: suspendMa.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD
                Text { anchors.centerIn: parent; text: "SUSPEND"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                MouseArea { id: suspendMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.run("suspend") }
            }
            Rectangle {
                Layout.fillWidth: true; height: 34; color: statsMa.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD
                Text { anchors.centerIn: parent; text: "BATTERY STATS"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                MouseArea { id: statsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["gnome-power-statistics"]) }
            }
        }

        Text {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "Power profiles use the system Power Profiles backend. Battery state comes from UPower; screen blanking remains controlled by THE INDEX swayidle policy."
            font.family: root.pixel; font.pixelSize: 9; color: root.cyanD
        }
        Item { Layout.fillHeight: true }
    }
}
