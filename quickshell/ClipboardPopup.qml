// WILL OF THE CITY :: THE INDEX — transient clipboard history popup
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: popup

    property bool open: false
    property bool backendAvailable: false
    property int historyCount: 0
    property string query: ""
    property var allItems: []

    visible: open
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "index-clipboard"

    function showPopup() {
        open = true
        query = ""
        refresh()
        Qt.callLater(function() { searchInput.forceActiveFocus() })
        Sfx.play("menu")
    }

    function hidePopup() {
        open = false
        query = ""
    }

    function togglePopup() {
        if (open) hidePopup()
        else showPopup()
    }

    function refresh() {
        if (!historyGet.running) historyGet.running = true
    }

    function rebuild() {
        visibleModel.clear()
        var needle = query.trim().toLowerCase()
        for (var i = 0; i < allItems.length; ++i) {
            var item = allItems[i]
            var haystack = (item.preview + " " + item.mime + " " + item.kind).toLowerCase()
            if (needle.length === 0 || haystack.indexOf(needle) !== -1)
                visibleModel.append(item)
        }
        historyList.currentIndex = visibleModel.count > 0 ? 0 : -1
    }

    function activateCurrent() {
        if (historyList.currentIndex < 0 || historyList.currentIndex >= visibleModel.count)
            return
        var item = visibleModel.get(historyList.currentIndex)
        if (!/^\d+$/.test(item.itemId))
            return
        Quickshell.execDetached(["sh", "-c", "exec \"$HOME/.local/bin/index-clipboard\" select " + item.itemId])
        hidePopup()
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { popup.togglePopup() }
        function open(): void { popup.showPopup() }
        function close(): void { popup.hidePopup() }
        function refresh(): void { popup.refresh() }
    }

    ListModel { id: visibleModel }

    Process {
        id: historyGet
        command: ["sh", "-c", "exec \"$HOME/.local/bin/index-clipboard\" dump"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split(/\r?\n/)
                var parsed = []
                var available = false
                var count = 0
                if (lines.length > 0 && lines[0].indexOf("@status\t") === 0) {
                    var status = lines[0].split("\t")
                    available = status.length >= 2 && status[1] === "1"
                    count = status.length >= 3 ? parseInt(status[2]) : 0
                    if (isNaN(count)) count = 0
                }
                for (var i = 1; i < lines.length; ++i) {
                    if (lines[i].length === 0) continue
                    var f = lines[i].split("\t")
                    if (f.length < 5 || !/^\d+$/.test(f[0])) continue
                    parsed.push({
                        itemId: f[0],
                        kind: f[1],
                        mime: f[2],
                        preview: f[3],
                        thumbnail: f[4]
                    })
                }
                popup.backendAvailable = available
                popup.historyCount = count
                popup.allItems = parsed
                popup.rebuild()
            }
        }
    }

    Timer {
        id: clearRefresh
        interval: 250
        repeat: false
        onTriggered: popup.refresh()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: popup.hidePopup()
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 460
        height: 520
        color: IndexTheme.background
        border.color: IndexTheme.cyan
        border.width: IndexTheme.panelBorderWidth

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: function(mouse) { mouse.accepted = true }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: IndexTheme.panelMargin
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: ">_ CLIPBOARD_"
                    font.family: IndexTheme.pixel
                    font.pixelSize: IndexTheme.titleSize
                    color: IndexTheme.cyanBright
                }
                Text {
                    text: popup.backendAvailable ? (popup.historyCount + "/50") : "OFFLINE"
                    font.family: IndexTheme.pixel
                    font.pixelSize: IndexTheme.tinySize
                    color: popup.backendAvailable ? IndexTheme.cyanDark : IndexTheme.warning
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: IndexTheme.cyanDark }

            Rectangle {
                Layout.fillWidth: true
                height: 34
                color: IndexTheme.backgroundDeep
                border.color: searchInput.activeFocus ? IndexTheme.cyan : IndexTheme.cyanDark
                border.width: 1

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: IndexTheme.cyanBright
                    selectionColor: IndexTheme.cyan
                    selectedTextColor: IndexTheme.ink
                    font.family: IndexTheme.pixel
                    font.pixelSize: IndexTheme.smallSize
                    clip: true
                    text: popup.query
                    onTextChanged: {
                        if (popup.query !== text) {
                            popup.query = text
                            popup.rebuild()
                        }
                    }
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Down) {
                            if (visibleModel.count > 0)
                                historyList.currentIndex = Math.min(visibleModel.count - 1, historyList.currentIndex + 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            if (visibleModel.count > 0)
                                historyList.currentIndex = Math.max(0, historyList.currentIndex - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            popup.activateCurrent()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            popup.hidePopup()
                            event.accepted = true
                        }
                    }
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    visible: searchInput.text.length === 0
                    text: "SEARCH HISTORY..."
                    font.family: IndexTheme.pixel
                    font.pixelSize: IndexTheme.smallSize
                    color: IndexTheme.cyanDark
                }
            }

            Text {
                visible: !popup.backendAvailable
                Layout.fillWidth: true
                text: "CLIPBOARD BACKEND UNAVAILABLE"
                horizontalAlignment: Text.AlignHCenter
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.smallSize
                color: IndexTheme.warning
            }

            Text {
                visible: popup.backendAvailable && visibleModel.count === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: popup.query.length > 0 ? "NO MATCHING HISTORY" : "CLIPBOARD HISTORY IS EMPTY"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.smallSize
                color: IndexTheme.cyanDark
            }

            ListView {
                id: historyList
                visible: popup.backendAvailable && visibleModel.count > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5
                model: visibleModel
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property string itemId
                    required property string kind
                    required property string mime
                    required property string preview
                    required property string thumbnail

                    width: ListView.view.width
                    height: 66
                    color: ListView.isCurrentItem ? IndexTheme.cyan : (itemMouse.containsMouse ? IndexTheme.surfaceHover : IndexTheme.surface)
                    border.color: IndexTheme.cyanDark
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 52
                            color: parent.parent.ListView.isCurrentItem ? IndexTheme.cyanBright : IndexTheme.backgroundDeep
                            border.color: parent.parent.ListView.isCurrentItem ? IndexTheme.ink : IndexTheme.cyanDark
                            border.width: 1
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                visible: kind === "image" && thumbnail.length > 0
                                source: thumbnail
                                asynchronous: true
                                cache: true
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: kind !== "image" || thumbnail.length === 0
                                text: kind === "image" ? "IMG" : "TXT"
                                font.family: IndexTheme.pixel
                                font.pixelSize: IndexTheme.tinySize
                                color: parent.parent.parent.ListView.isCurrentItem ? IndexTheme.ink : IndexTheme.cyanDark
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                Layout.fillWidth: true
                                text: preview
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                font.family: IndexTheme.pixel
                                font.pixelSize: IndexTheme.smallSize
                                color: parent.parent.parent.ListView.isCurrentItem ? IndexTheme.ink : IndexTheme.cyanBright
                            }
                            Text {
                                Layout.fillWidth: true
                                text: kind.toUpperCase() + (mime.length > 0 ? "  " + mime : "")
                                elide: Text.ElideRight
                                font.family: IndexTheme.pixel
                                font.pixelSize: IndexTheme.tinySize
                                color: parent.parent.parent.ListView.isCurrentItem ? IndexTheme.ink : IndexTheme.cyanDark
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: historyList.currentIndex = index
                        onClicked: {
                            historyList.currentIndex = index
                            popup.activateCurrent()
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: IndexTheme.cyanDark }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 120
                    height: 28
                    color: clearMouse.containsMouse ? IndexTheme.surfaceHover : "transparent"
                    border.color: IndexTheme.cyanDark
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "CLEAR"
                        font.family: IndexTheme.pixel
                        font.pixelSize: IndexTheme.tinySize
                        color: IndexTheme.cyanBright
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: popup.backendAvailable && popup.historyCount > 0
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", "exec \"$HOME/.local/bin/index-clipboard\" clear"])
                            popup.allItems = []
                            popup.historyCount = 0
                            popup.rebuild()
                            clearRefresh.restart()
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "↑↓ SELECT   ENTER PASTE   ESC CLOSE"
                    font.family: IndexTheme.pixel
                    font.pixelSize: 9
                    color: IndexTheme.cyanDark
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: popup.open
        onActivated: popup.hidePopup()
    }
}
