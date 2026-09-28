// WILL OF THE CITY :: THE INDEX — appearance subpanel
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
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/index-appearance"
    property string iconTheme: "Papirus-Dark"
    property string cursorTheme: "Adwaita"
    property int cursorSize: 24
    property string wallpaper: ""

    function refresh() { if (!stateGet.running) stateGet.running = true }
    function direct(args) { Quickshell.execDetached([root.helper].concat(args)) }
    Component.onCompleted: if (visible) { refresh(); choiceWarm.running = true }
    onVisibleChanged: if (visible) {
        refresh()
        if (!choiceWarm.running) choiceWarm.running = true
    }

    Process {
        id: stateGet
        command: [root.helper, "state"]
        stdout: StdioCollector { onStreamFinished: {
            var f=text.replace(/[\r\n]+$/, "").split("\t")
            if(f[0]) root.iconTheme=f[0]
            if(f[1]) root.cursorTheme=f[1]
            var s=parseInt(f[2]); if(!isNaN(s)) root.cursorSize=s
            root.wallpaper=f.slice(3).join("\t") || ""
        } }
    }
    Process { id: choiceWarm; command: [root.helper, "refresh-choices"]; stdout: StdioCollector {} }
    Process {
        id: wallpaperChooser
        property bool started: false
        command: [root.helper, "choose-wallpaper"]
        stdout: StdioCollector {}
        onRunningChanged: { if (running) started = true; else if (started) { started = false; root.refresh() } }
    }
    Process {
        id: iconChooser
        property bool started: false
        command: [root.helper, "choose-icons"]
        stdout: StdioCollector {}
        onRunningChanged: { if (running) started = true; else if (started) { started = false; root.refresh() } }
    }
    Process {
        id: cursorChooser
        property bool started: false
        command: [root.helper, "choose-cursor", String(root.cursorSize)]
        stdout: StdioCollector {}
        onRunningChanged: { if (running) started = true; else if (started) { started = false; root.refresh() } }
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: ">_ APPEARANCE_"; font.family: root.pixel; font.pixelSize: 17; color: root.cyanB }
            Text { text: "<_ BACK"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanD
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.requestBack() } }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: root.cyanD }

        Text { text: "WALLPAPER"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        Text {
            Layout.fillWidth: true
            text: "  " + ((!root.wallpaper || root.wallpaper.endsWith("/.config/labwc/wall.png")) ? "THE INDEX DEFAULT" : root.wallpaper)
            elide: Text.ElideMiddle; font.family: root.pixel; font.pixelSize: 10; color: root.cyanD
        }
        RowLayout { Layout.fillWidth: true; spacing: 6
            Rectangle {
                Layout.fillWidth: true; height: 30; color: wallpaperArea.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD
                Text { anchors.centerIn: parent; text: choiceWarm.running ? "PREPARING..." : (wallpaperChooser.running ? "CHOOSING..." : "CHOOSE"); font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                MouseArea { id: wallpaperArea; anchors.fill: parent; hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; enabled: !choiceWarm.running && !wallpaperChooser.running; onClicked: wallpaperChooser.running = true }
            }
            Rectangle {
                Layout.fillWidth: true; height: 30; color: defaultArea.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD
                Text { anchors.centerIn: parent; text: "DEFAULT"; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                MouseArea { id: defaultArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.direct(["reset-wallpaper"]); refreshTimer.restart() } }
            }
        }

        Text { text: "APP ICONS"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        Rectangle { Layout.fillWidth:true; height:34; color:"#0c1620"; border.color:root.cyanD
            Text { anchors.centerIn:parent; text:root.iconTheme + (choiceWarm.running ? "  [PREPARING]" : (iconChooser.running ? "  [LOADING]" : "  [CHANGE]")); font.family:root.pixel; font.pixelSize:11; color:root.cyanB }
            MouseArea { anchors.fill:parent; cursorShape:enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; enabled:!choiceWarm.running && !iconChooser.running; onClicked:iconChooser.running=true }
        }

        Text { text: "CURSOR THEME"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        Rectangle { Layout.fillWidth:true; height:34; color:"#0c1620"; border.color:root.cyanD
            Text { anchors.centerIn:parent; text:root.cursorTheme + (choiceWarm.running ? "  [PREPARING]" : (cursorChooser.running ? "  [LOADING]" : "  [CHANGE]")); font.family:root.pixel; font.pixelSize:11; color:root.cyanB }
            MouseArea { anchors.fill:parent; cursorShape:enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; enabled:!choiceWarm.running && !cursorChooser.running; onClicked:cursorChooser.running=true }
        }

        Text { text: "CURSOR SIZE"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        RowLayout { Layout.fillWidth:true; spacing:5
            Repeater { model:[16,24,32,48]
                delegate: Rectangle { required property int modelData; Layout.fillWidth:true; height:28; readonly property bool on:root.cursorSize===modelData; color:on?root.cyan:"transparent"; border.color:root.cyanD
                    Text { anchors.centerIn:parent; text:modelData; font.family:root.pixel; font.pixelSize:11; color:parent.on?"#04141c":root.cyanB }
                    MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{root.cursorSize=modelData; root.direct(["set-cursor-size", String(modelData)])} }
                }
            }
        }
        Text { Layout.fillWidth:true; wrapMode:Text.WordWrap; text:"Changes affect application icons, cursor appearance and desktop wallpaper only. THE INDEX interface theme remains unchanged. Some applications may need to be reopened; cursor theme changes may require a new session."; font.family:root.pixel; font.pixelSize:10; color:root.cyanD }
        Item { Layout.fillHeight:true }
        Timer { id:refreshTimer; interval:500; repeat:false; onTriggered:root.refresh() }
    }
}
