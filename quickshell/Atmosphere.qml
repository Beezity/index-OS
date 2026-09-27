// ============================================================
//  WILL OF THE CITY :: THE INDEX — atmosphere
//  Full-screen background layer: drifting cyan motes, glow and
//  subtitle ticker over the wallpaper, behind normal windows.
// ============================================================

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: atmo
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "index-atmosphere"

    readonly property string pixel: "Perfect DOS VGA 437 Universal"
    readonly property color cyan: "#5DADE2"
    readonly property color cyanB: "#85C5E8"
    readonly property color cyanD: "#3A7CA5"
    property string hostname: "unknown"

    Process {
        running: true
        command: ["sh", "-c", "hostname | LC_ALL=C tr -cd 'A-Za-z0-9._-' | cut -c1-63"]
        stdout: StdioCollector {
            onStreamFinished: {
                var value = text.trim()
                if (value.length > 0)
                    atmo.hostname = value
            }
        }
    }

    Text {
        anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 14
        text: "// THE INDEX - district: " + atmo.hostname
        font.family: atmo.pixel; font.pixelSize: 13
        color: atmo.cyanD
        renderType: Text.NativeRendering
    }
    Text {
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
        text: "... I hear the waves."
        font.family: atmo.pixel; font.pixelSize: 13
        color: "#FF6B6B"
        renderType: Text.NativeRendering
    }
    Text {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 14
        text: "> standby_"
        font.family: atmo.pixel; font.pixelSize: 13
        color: atmo.cyanD
        renderType: Text.NativeRendering
    }

    // This is a full-screen software Canvas, so keep its redraw rate modest.
    // 20 FPS is smooth enough for slow ambient particles while cutting the
    // continuous paint workload substantially, especially on VMware where
    // Quickshell deliberately uses Qt's software renderer.
    Canvas {
        id: cv
        anchors.fill: parent
        property var parts: []
        Component.onCompleted: {
            for (var i = 0; i < 40; i++)
                parts.push({
                    x: Math.random() * width,
                    y: Math.random() * height,
                    r: Math.random() * 1.6 + 0.4,
                    s: Math.random() * 0.6 + 0.18,
                    a: Math.random() * 0.5 + 0.18,
                    d: Math.random() * 0.6 - 0.3
                });
        }
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.shadowBlur = 4;
            ctx.shadowColor = "rgba(93,173,226,0.85)";
            for (var i = 0; i < parts.length; i++) {
                var p = parts[i];
                p.y -= p.s;
                p.x += p.d * 0.3;
                if (p.y < -5) { p.x = Math.random() * width; p.y = height + 5; }
                ctx.beginPath();
                ctx.arc(p.x, p.y, p.r, 0, 6.283);
                ctx.fillStyle = "rgba(93,173,226," + p.a + ")";
                ctx.fill();
            }
        }
        Timer { interval: 50; running: true; repeat: true; onTriggered: cv.requestPaint() }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(640, parent.width * 0.5)
        height: width
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#145DADE2" }
            GradientStop { position: 1.0; color: "transparent" }
        }
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 0.35; to: 0.75; duration: 2500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.75; to: 0.35; duration: 2500; easing.type: Easing.InOutSine }
        }
    }

    Column {
        id: ticker
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        spacing: 3

        property var lines: [
            "The City remembers every name it is given.",
            "By the geometry of inevitability, the prey gathers here.",
            "Speak your name, and the door will know you.",
            "The Index keeps what the City forgets."
        ]
        property int idx: 0

        Text {
            id: subMain
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: atmo.pixel; font.pixelSize: 19
            font.kerning: false
            color: "#f0f8fc"
            opacity: 0
            renderType: Text.NativeRendering
            style: Text.Raised
            styleColor: "#3A7CA5"
            Behavior on opacity { NumberAnimation { duration: 600 } }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "// THE INDEX"
            font.family: atmo.pixel; font.pixelSize: 13
            font.kerning: false
            color: atmo.cyan
            opacity: subMain.opacity
            renderType: Text.NativeRendering
        }

        Timer {
            interval: 6500; running: true; repeat: true; triggeredOnStart: true
            onTriggered: { subMain.opacity = 0; swap.restart(); }
        }
        Timer {
            id: swap; interval: 650
            onTriggered: {
                subMain.text = ticker.lines[ticker.idx];
                subMain.opacity = 1
                ticker.idx = (ticker.idx + 1) % ticker.lines.length
            }
        }
    }
}
