// WILL OF THE CITY :: THE INDEX — local system information page
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var info: ({ distro: "...", kernel: "...", arch: "...", labwc: "...", quickshell: "..." })
    signal requestBack()

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    function refresh() { systemInfo.running = true }

    Component.onCompleted: refresh()

    Process {
        id: systemInfo
        command: ["sh", "-c",
            ". /etc/os-release 2>/dev/null || true; " +
            "printf '%s\\n' \"${PRETTY_NAME:-Unknown Linux}\"; " +
            "uname -r 2>/dev/null || echo unknown; " +
            "uname -m 2>/dev/null || echo unknown; " +
            "labwc --version 2>/dev/null | head -1 || echo unavailable; " +
            "quickshell --version 2>/dev/null | head -1 || echo unavailable"]
        stdout: StdioCollector {
            onStreamFinished: {
                var l = text.trim().split("\n")
                root.info = {
                    distro: l[0] || "unknown",
                    kernel: l[1] || "unknown",
                    arch: l[2] || "unknown",
                    labwc: l[3] || "unavailable",
                    quickshell: l[4] || "unavailable"
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: IndexTheme.sectionSpacing

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "< BACK"
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.smallSize
                color: IndexTheme.cyanDark
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.requestBack() }
            }
            Text {
                Layout.fillWidth: true
                text: "ABOUT / SYSTEM_"
                horizontalAlignment: Text.AlignRight
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.titleSize
                color: IndexTheme.cyanBright
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: IndexTheme.cyanDark }

        Text { text: "THE INDEX"; font.family: IndexTheme.pixel; font.pixelSize: 18; color: IndexTheme.cyan }
        Text {
            Layout.fillWidth: true
            text: "A labwc desktop environment"
            font.family: IndexTheme.pixel; font.pixelSize: IndexTheme.smallSize; color: IndexTheme.cyanDark
        }

        Repeater {
            model: [
                ["DISTRO", root.info.distro],
                ["KERNEL", root.info.kernel],
                ["ARCH", root.info.arch],
                ["LABWC", root.info.labwc],
                ["QUICKSHELL", root.info.quickshell]
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Text { text: modelData[0]; font.family: IndexTheme.pixel; font.pixelSize: IndexTheme.smallSize; color: IndexTheme.cyanDark }
                Item { Layout.fillWidth: true }
                Text {
                    Layout.maximumWidth: 210
                    text: modelData[1]
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    font.family: IndexTheme.pixel; font.pixelSize: IndexTheme.smallSize; color: IndexTheme.cyanBright
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: IndexTheme.cyanDark }

        IndexSectionButton { label: "RUN INDEX DOCTOR"; detail: "check desktop health"; onClicked: root.run("foot -e index-doctor") }
        IndexSectionButton { label: "INDEX UPDATE"; detail: "open updater in terminal"; onClicked: root.run("foot -e index-update") }
        IndexSectionButton { label: "PROJECT REPOSITORY"; detail: "Beezity/index-OS"; onClicked: root.run("xdg-open https://github.com/Beezity/index-OS") }

        Item { Layout.fillHeight: true }
        Text {
            Layout.fillWidth: true
            text: "local system information only"
            horizontalAlignment: Text.AlignHCenter
            font.family: IndexTheme.pixel; font.pixelSize: IndexTheme.tinySize; color: IndexTheme.cyanDark
        }
    }
}
