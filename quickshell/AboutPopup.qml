// WILL OF THE CITY :: THE INDEX — standalone About/System popup
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popup
    property bool open: false
    visible: open
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "index-about-system"

    IpcHandler {
        target: "aboutsystem"
        function toggle(): void { popup.open = !popup.open; Sfx.play("menu") }
        function open(): void { popup.open = true; Sfx.play("menu") }
        function close(): void { popup.open = false }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: popup.open = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 420
        height: 500
        color: IndexTheme.background
        border.color: IndexTheme.cyan
        border.width: IndexTheme.panelBorderWidth

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: function(mouse) { mouse.accepted = true }
        }

        AboutSystem {
            anchors.fill: parent
            anchors.margins: IndexTheme.panelMargin
            onRequestBack: popup.open = false
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: popup.open
        onActivated: popup.open = false
    }
}
