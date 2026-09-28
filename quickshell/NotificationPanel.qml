// WILL OF THE CITY :: THE INDEX — notification settings subpanel
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    signal requestBack()
    color: "transparent"

    Component.onCompleted: NotificationPrefs.refresh()
    onVisibleChanged: if (visible) NotificationPrefs.refresh()

    function testNotification() {
        Quickshell.execDetached([
            "notify-send",
            "-a", "THE INDEX",
            "NOTIFICATION TEST",
            "notification service is active"
        ])
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: IndexTheme.panelMargin
        spacing: 11

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: ">_ NOTIFICATIONS_"
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.titleSize
                color: IndexTheme.cyanBright
            }
            Text {
                text: "<_ BACK"
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.smallSize
                color: IndexTheme.cyanDark
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestBack()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: IndexTheme.cyanDark }

        Text {
            visible: !NotificationPrefs.ready || !NotificationPrefs.backendAvailable
            text: NotificationPrefs.ready ? "NOTIFICATION SETTINGS BACKEND UNAVAILABLE" : "NOTIFICATION SETTINGS UNAVAILABLE"
            font.family: IndexTheme.pixel
            font.pixelSize: IndexTheme.smallSize
            color: IndexTheme.warning
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7
            enabled: NotificationPrefs.backendAvailable
            opacity: enabled ? 1.0 : 0.45

            Text {
                text: "DELIVERY"
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.bodySize
                color: IndexTheme.cyanBright
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                readonly property bool on: NotificationPrefs.dnd
                color: on ? IndexTheme.cyan : (dndMouse.containsMouse ? IndexTheme.surfaceHover : "transparent")
                border.color: IndexTheme.cyanDark
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "DO NOT DISTURB  " + (parent.on ? "ON" : "OFF")
                    font.family: IndexTheme.pixel
                    font.pixelSize: IndexTheme.smallSize
                    color: parent.on ? IndexTheme.ink : IndexTheme.cyanBright
                }
                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationPrefs.setDnd(!NotificationPrefs.dnd)
                }
            }

            Text {
                Layout.fillWidth: true
                text: "  DND suppresses popups and notification chimes. New notifications still appear in history."
                wrapMode: Text.Wrap
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.tinySize
                color: IndexTheme.cyanDark
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                readonly property bool on: NotificationPrefs.sounds
                color: on ? IndexTheme.cyan : (soundsMouse.containsMouse ? IndexTheme.surfaceHover : "transparent")
                border.color: IndexTheme.cyanDark
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "NOTIFICATION SOUNDS  " + (parent.on ? "ON" : "OFF")
                    font.family: IndexTheme.pixel
                    font.pixelSize: IndexTheme.smallSize
                    color: parent.on ? IndexTheme.ink : IndexTheme.cyanBright
                }
                MouseArea {
                    id: soundsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationPrefs.setSounds(!NotificationPrefs.sounds)
                }
            }

            Text {
                Layout.fillWidth: true
                text: "  The global UI SOUNDS switch still applies."
                wrapMode: Text.Wrap
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.tinySize
                color: IndexTheme.cyanDark
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            enabled: NotificationPrefs.backendAvailable
            opacity: enabled ? 1.0 : 0.45

            Text {
                text: "POPUP TIME"
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.bodySize
                color: IndexTheme.cyanBright
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                Repeater {
                    model: [
                        { ms: 3000, label: "3s" },
                        { ms: 6000, label: "6s" },
                        { ms: 10000, label: "10s" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 28
                        readonly property bool on: NotificationPrefs.timeoutMs === modelData.ms
                        color: on ? IndexTheme.cyan : (timeoutMouse.containsMouse ? IndexTheme.surfaceHover : "transparent")
                        border.color: IndexTheme.cyanDark
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: IndexTheme.pixel
                            font.pixelSize: IndexTheme.smallSize
                            color: parent.on ? IndexTheme.ink : IndexTheme.cyanBright
                        }
                        MouseArea {
                            id: timeoutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationPrefs.setTimeoutMs(modelData.ms)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "  Critical notifications stay until dismissed."
                wrapMode: Text.Wrap
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.tinySize
                color: IndexTheme.cyanDark
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: IndexTheme.cyanDark }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "HISTORY"
                    font.family: IndexTheme.pixel
                    font.pixelSize: IndexTheme.bodySize
                    color: IndexTheme.cyanBright
                }
                Text {
                    text: NotifHistory.items.length + " / " + NotifHistory.maxItems
                    font.family: IndexTheme.pixel
                    font.pixelSize: IndexTheme.tinySize
                    color: IndexTheme.cyanDark
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: clearMouse.containsMouse ? IndexTheme.surfaceHover : "transparent"
                    border.color: IndexTheme.cyanDark
                    border.width: 1
                    opacity: NotifHistory.items.length > 0 ? 1.0 : 0.45
                    Text {
                        anchors.centerIn: parent
                        text: "CLEAR HISTORY"
                        font.family: IndexTheme.pixel
                        font.pixelSize: IndexTheme.smallSize
                        color: IndexTheme.cyanBright
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        enabled: NotifHistory.items.length > 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotifHistory.clear()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: testMouse.containsMouse ? IndexTheme.surfaceHover : "transparent"
                    border.color: IndexTheme.cyanDark
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "SEND TEST"
                        font.family: IndexTheme.pixel
                        font.pixelSize: IndexTheme.smallSize
                        color: IndexTheme.cyanBright
                    }
                    MouseArea {
                        id: testMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.testNotification()
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: IndexTheme.cyanDark }

        Text {
            Layout.fillWidth: true
            text: "BACKEND: Quickshell org.freedesktop.Notifications"
            wrapMode: Text.Wrap
            font.family: IndexTheme.pixel
            font.pixelSize: IndexTheme.tinySize
            color: IndexTheme.cyanDark
        }
        Text {
            Layout.fillWidth: true
            text: "PREFERENCES: ~/.config/the-index/notifications.conf"
            wrapMode: Text.Wrap
            font.family: IndexTheme.pixel
            font.pixelSize: IndexTheme.tinySize
            color: IndexTheme.cyanDark
        }

        Item { Layout.fillHeight: true }
    }
}
