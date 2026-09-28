// WILL OF THE CITY :: THE INDEX — dedicated settings launcher
import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: launcher
    anchors { top: true; right: true }
    // labwc reserves the 32px bar as an exclusive top zone. Pull this small
    // overlay back into that zone so the icon is visually part of the bar,
    // rather than floating in the desktop below it. The right margin leaves
    // breathing room between the icon and the date block.
    margins { top: -32; right: 96 }
    implicitWidth: 26
    implicitHeight: 32
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "index-settings-launcher"

    property bool settingsOpen: false

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Image {
            id: settingsIcon
            anchors.centerIn: parent
            width: 17; height: 17
            sourceSize.width: 17; sourceSize.height: 17
            source: Quickshell.iconPath("preferences-system", "applications-system")
            opacity: settingsArea.containsMouse || launcher.settingsOpen ? 1.0 : 0.72
        }

        Text {
            anchors.centerIn: parent
            visible: settingsIcon.status !== Image.Ready
            text: "[*]"
            font.family: "Perfect DOS VGA 437 Universal"
            font.pixelSize: 12
            color: "#3A7CA5"
        }

        MouseArea {
            id: settingsArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                launcher.settingsOpen = !launcher.settingsOpen
                Sfx.play("menu")
            }
        }
    }

    PanelWindow {
        visible: launcher.settingsOpen
        anchors { top: true; right: true }
        margins { top: 32; right: 8 }
        implicitWidth: 340
        implicitHeight: 920
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "index-settings-launcher-popup"
        SettingsPanel { anchors.fill: parent; onRequestClose: launcher.settingsOpen = false }
    }
}
