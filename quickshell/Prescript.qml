// WILL OF THE CITY :: THE INDEX — PRESCRIPT OF THE DAY (desktop widget)
// The content itself lives in PrescriptState so every connected monitor shows
// the same daily prescript and rerolls/toggles stay synchronized.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: pres

    visible: PrescriptState.open
    anchors { top: true; right: true }
    margins { top: 70; right: 28 }
    implicitWidth: 420
    implicitHeight: card.implicitHeight
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "index-prescript"

    readonly property string pixel: "Perfect DOS VGA 437 Universal"
    readonly property color cyan:  "#5DADE2"
    readonly property color cyanB: "#85C5E8"
    readonly property color cyanD: "#3A7CA5"
    readonly property color warn:  "#FF6B6B"

    readonly property string text_: PrescriptState.text_
    readonly property string dateKey: PrescriptState.dateKey
    property string shown: ""

    // ---- scramble reveal (same idea as the lock screen) ----
    readonly property string scrambleChars: "!<>-_\\/[]{}—=+*^?#________ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    property real scrambleTime: 0.7
    property real revealTime: 1.6
    property real elapsed: 0

    function randomChar() {
        return pres.scrambleChars.charAt(Math.floor(Math.random() * pres.scrambleChars.length))
    }

    function startScramble() {
        pres.elapsed = 0
        pres.shown = ""
        if (pres.text_ === "") return
        scrambler.restart()
    }

    Timer {
        id: scrambler
        interval: 45
        repeat: true
        running: false
        onTriggered: {
            pres.elapsed += interval / 1000
            var t = pres.text_
            var out = ""
            if (pres.elapsed < pres.scrambleTime) {
                for (var i = 0; i < t.length; i++)
                    out += (t.charAt(i) === " ") ? " " : pres.randomChar()
                pres.shown = out
                return
            }

            var progress = Math.min((pres.elapsed - pres.scrambleTime) / pres.revealTime, 1)
            var revealCount = Math.floor(progress * t.length)
            for (var j = 0; j < t.length; j++)
                out += (j < revealCount || t.charAt(j) === " ") ? t.charAt(j) : pres.randomChar()
            pres.shown = out

            if (progress >= 1) {
                pres.shown = t
                scrambler.stop()
            }
        }
    }

    Connections {
        target: PrescriptState
        function onRevisionChanged() { pres.startScramble() }
    }

    Component.onCompleted: if (pres.text_ !== "") pres.startScramble()

    Rectangle {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: col.implicitHeight + 26
        color: "#0a0e16"
        opacity: 0.0
        Component.onCompleted: opacity = 0.88
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutQuad } }
        border.color: pres.cyan
        border.width: 2

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: PrescriptState.reroll()
        }

        Text {
            id: closeButton
            z: 2
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 13
            anchors.rightMargin: 13
            text: "[X]"
            font.family: pres.pixel
            font.pixelSize: 14
            color: pres.warn

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    mouse.accepted = true
                    PrescriptState.open = false
                }
            }
        }

        Column {
            id: col
            z: 1
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 13
            spacing: 6

            Text {
                width: Math.max(0, col.width - closeButton.implicitWidth - 8)
                text: ">_ PRESCRIPT OF THE DAY_"
                font.family: pres.pixel
                font.pixelSize: 14
                color: pres.cyanD
            }
            Rectangle { width: col.width; height: 1; color: pres.cyanD; opacity: 0.5 }
            Text {
                id: presText
                width: col.width
                text: pres.text_ === ""
                    ? "no prescript data — check prescript.json"
                    : pres.shown
                font.family: pres.pixel
                font.pixelSize: 15
                color: pres.cyanB
                wrapMode: Text.WordWrap
                lineHeight: 1.15
            }
            Text {
                text: "// " + pres.dateKey + "   \u00b7   click to reroll"
                font.family: pres.pixel
                font.pixelSize: 10
                color: pres.cyanD
            }
        }
    }
}
