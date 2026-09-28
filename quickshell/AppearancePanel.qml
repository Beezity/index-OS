// WILL OF THE CITY :: THE INDEX — appearance subpanel
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    signal requestBack()
    color: "#0a0e16"
    readonly property string pixel: "Perfect DOS VGA 437 Universal"
    readonly property color cyan: "#5DADE2"
    readonly property color cyanB: "#85C5E8"
    readonly property color cyanD: "#3A7CA5"
    property string iconTheme: "Papirus-Dark"
    property string cursorTheme: "capitaine-cursors"
    property int cursorSize: 24
    property string wallpaper: ""

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    function refresh() { stateGet.running = true }
    Component.onCompleted: refresh()
    onVisibleChanged: if (visible) refresh()

    Process {
        id: stateGet
        command: ["sh","-c","a=$HOME/.local/bin/index-appearance; printf '%s|%s|%s|%s' \"$($a get ICON_THEME 2>/dev/null)\" \"$($a get CURSOR_THEME 2>/dev/null)\" \"$($a get CURSOR_SIZE 2>/dev/null)\" \"$($a get WALLPAPER 2>/dev/null)\""]
        stdout: StdioCollector { onStreamFinished: {
            var f=text.trim().split("|")
            if(f[0]) root.iconTheme=f[0]
            if(f[1]) root.cursorTheme=f[1]
            var s=parseInt(f[2]); if(!isNaN(s)) root.cursorSize=s
            root.wallpaper=f[3] || ""
        } }
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
            Repeater { model: [{t:"CHOOSE",c:"f=$(find \"$HOME/Pictures\" -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | wofi --dmenu -p 'wallpaper'); [ -n \"$f\" ] && $HOME/.local/bin/index-appearance set-wallpaper \"$f\""},{t:"DEFAULT",c:"$HOME/.local/bin/index-appearance reset-wallpaper"}]
                delegate: Rectangle { required property var modelData; Layout.fillWidth: true; height: 30; color: wma.containsMouse ? "#143245" : "transparent"; border.color: root.cyanD
                    Text { anchors.centerIn: parent; text: modelData.t; font.family: root.pixel; font.pixelSize: 11; color: root.cyanB }
                    MouseArea { id:wma; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:{root.run(modelData.c); refreshTimer.restart()} }
                }
            }
        }

        Text { text: "APP ICONS"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        Rectangle { Layout.fillWidth:true; height:34; color:"#0c1620"; border.color:root.cyanD
            Text { anchors.centerIn:parent; text:root.iconTheme + "  [CHANGE]"; font.family:root.pixel; font.pixelSize:11; color:root.cyanB }
            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{root.run("t=$($HOME/.local/bin/index-appearance list-icons | wofi --dmenu -p 'icon theme'); [ -n \"$t\" ] && $HOME/.local/bin/index-appearance set-icons \"$t\""); refreshTimer.restart()} }
        }

        Text { text: "CURSOR THEME"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        Rectangle { Layout.fillWidth:true; height:34; color:"#0c1620"; border.color:root.cyanD
            Text { anchors.centerIn:parent; text:root.cursorTheme + "  [CHANGE]"; font.family:root.pixel; font.pixelSize:11; color:root.cyanB }
            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{root.run("t=$($HOME/.local/bin/index-appearance list-cursors | wofi --dmenu -p 'cursor theme'); [ -n \"$t\" ] && $HOME/.local/bin/index-appearance set-cursor \"$t\" " + root.cursorSize); refreshTimer.restart()} }
        }

        Text { text: "CURSOR SIZE"; font.family: root.pixel; font.pixelSize: 13; color: root.cyanB }
        RowLayout { Layout.fillWidth:true; spacing:5
            Repeater { model:[16,24,32,48]
                delegate: Rectangle { required property int modelData; Layout.fillWidth:true; height:28; readonly property bool on:root.cursorSize===modelData; color:on?root.cyan:"transparent"; border.color:root.cyanD
                    Text { anchors.centerIn:parent; text:modelData; font.family:root.pixel; font.pixelSize:11; color:parent.on?"#04141c":root.cyanB }
                    MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{root.cursorSize=modelData; root.run("$HOME/.local/bin/index-appearance set-cursor-size "+modelData)} }
                }
            }
        }
        Text { Layout.fillWidth:true; wrapMode:Text.WordWrap; text:"Changes affect application icons, cursor appearance and desktop wallpaper only. THE INDEX interface theme remains unchanged. Some applications may need to be reopened; cursor theme changes may require a new session."; font.family:root.pixel; font.pixelSize:10; color:root.cyanD }
        Item { Layout.fillHeight:true }
        Timer { id:refreshTimer; interval:500; repeat:false; onTriggered:root.refresh() }
    }
}
