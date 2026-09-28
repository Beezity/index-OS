// WILL OF THE CITY :: THE INDEX — notifications
// Top-right stacked popups backed by Quickshell's freedesktop notification server.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "."

PanelWindow {
    id: notifRoot
    anchors { top: true; right: true }
    margins { top: 40; right: 12 }
    implicitWidth: 390
    implicitHeight: Math.max(1, col.implicitHeight)
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "index-notifications"
    visible: server.trackedNotifications.values.length > 0

    function asciiElide(text, maxChars) {
        var value = text === undefined || text === null ? "" : String(text)
        return value.length > maxChars ? value.slice(0, Math.max(0, maxChars - 3)) + "..." : value
    }

    function iconSource(notification) {
        var image = notification.image || ""
        if (image.length > 0) return image

        var icon = notification.appIcon || ""
        if (icon.length === 0) return ""
        if (icon.indexOf("file:") === 0 || icon.indexOf("image:") === 0 ||
                icon.indexOf("qrc:") === 0 || icon.indexOf("/") === 0)
            return icon
        return Quickshell.iconPath(icon, "application-x-executable")
    }

    function dismissVisible() {
        var current = server.trackedNotifications.values
        for (var i = current.length - 1; i >= 0; --i) {
            if (current[i]) current[i].dismiss()
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true

        onNotification: function(notification) {
            var carried = notification.lastGeneration === true
            var appName = notification.appName || ""

            // Transient notifications explicitly request no persistence. DND
            // suppresses delivery but does not suppress normal history.
            if (!carried && !notification.transient) {
                NotifHistory.add(notification.appName, notification.summary, notification.body,
                                 notification.urgency === NotificationUrgency.Critical)
            }

            if (!carried && !NotificationPrefs.dnd && NotificationPrefs.sounds &&
                    appName.indexOf("DEVICE") < 0) {
                Sfx.play(notification.urgency === NotificationUrgency.Critical ? "error" : "notify")
            }

            if (!NotificationPrefs.dnd)
                notification.tracked = true
        }
    }

    Connections {
        target: NotificationPrefs
        function onDndChanged() {
            if (NotificationPrefs.dnd)
                notifRoot.dismissVisible()
        }
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 8

        Repeater {
            model: server.trackedNotifications

            delegate: Rectangle {
                id: notificationDelegate
                required property var modelData
                readonly property var notification: modelData
                readonly property string icon: notifRoot.iconSource(notification)

                Layout.fillWidth: true
                implicitHeight: inner.implicitHeight + 20
                color: IndexTheme.background
                border.color: notification.urgency === NotificationUrgency.Critical ? IndexTheme.warning : IndexTheme.cyan
                border.width: IndexTheme.panelBorderWidth
                opacity: 0.0
                property real slide: 70
                transform: Translate { x: notificationDelegate.slide }
                Component.onCompleted: { opacity = 0.97; slide = 0 }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
                Behavior on slide { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: notificationDelegate.notification.dismiss()
                    z: 0
                }

                ColumnLayout {
                    id: inner
                    z: 1
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: ">_"
                            font.family: IndexTheme.pixel
                            font.pixelSize: IndexTheme.bodySize
                            color: IndexTheme.cyanDark
                        }
                        Text {
                            Layout.fillWidth: true
                            text: notifRoot.asciiElide(notificationDelegate.notification.appName || "SYSTEM", 36)
                            textFormat: Text.PlainText
                            font.family: IndexTheme.pixel
                            font.pixelSize: 12
                            color: IndexTheme.cyanDark
                            clip: true
                        }
                        Text {
                            text: "[X]"
                            font.family: IndexTheme.pixel
                            font.pixelSize: 12
                            color: IndexTheme.warning
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: notificationDelegate.notification.dismiss()
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Image {
                            Layout.preferredWidth: visible ? 48 : 0
                            Layout.preferredHeight: visible ? 48 : 0
                            sourceSize.width: 48
                            sourceSize.height: 48
                            source: notificationDelegate.icon
                            visible: notificationDelegate.icon.length > 0
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                Layout.fillWidth: true
                                text: notifRoot.asciiElide(notificationDelegate.notification.summary || "", 140)
                                textFormat: Text.PlainText
                                font.family: IndexTheme.pixel
                                font.pixelSize: 16
                                color: notificationDelegate.notification.urgency === NotificationUrgency.Critical ? IndexTheme.warning : IndexTheme.cyanBright
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: (notificationDelegate.notification.body || "") !== ""
                                text: notifRoot.asciiElide(notificationDelegate.notification.body, 220)
                                textFormat: Text.PlainText
                                font.family: IndexTheme.pixel
                                font.pixelSize: IndexTheme.bodySize
                                color: IndexTheme.cyan
                                wrapMode: Text.WordWrap
                                maximumLineCount: 4
                                clip: true
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 5
                        visible: notificationDelegate.notification.actions.length > 0

                        Repeater {
                            model: Math.min(notificationDelegate.notification.actions.length, 4)
                            delegate: Rectangle {
                                required property int index
                                readonly property var notificationAction: notificationDelegate.notification.actions[index]
                                width: Math.min(150, actionText.implicitWidth + 18)
                                height: 26
                                color: actionMouse.containsMouse ? IndexTheme.cyan : "transparent"
                                border.color: IndexTheme.cyanDark
                                border.width: 1
                                Text {
                                    id: actionText
                                    anchors.centerIn: parent
                                    text: notifRoot.asciiElide(parent.notificationAction.text || "ACTION", 24)
                                    textFormat: Text.PlainText
                                    font.family: IndexTheme.pixel
                                    font.pixelSize: IndexTheme.tinySize
                                    color: actionMouse.containsMouse ? IndexTheme.ink : IndexTheme.cyanBright
                                }
                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: parent.notificationAction.invoke()
                                }
                            }
                        }
                    }
                }

                Timer {
                    interval: Math.max(1000, NotificationPrefs.timeoutMs)
                    running: NotificationPrefs.timeoutMs > 0 &&
                             notificationDelegate.notification.urgency !== NotificationUrgency.Critical
                    repeat: false
                    onTriggered: notificationDelegate.notification.expire()
                }
            }
        }
    }
}
