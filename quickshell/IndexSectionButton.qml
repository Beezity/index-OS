// WILL OF THE CITY :: THE INDEX — reusable settings navigation row
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string label: "SECTION"
    property string detail: ""
    property bool enabled: true
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: detail.length > 0 ? 42 : 34
    color: mouse.containsMouse && enabled ? IndexTheme.surfaceHover : IndexTheme.surface
    border.color: enabled ? IndexTheme.cyanDark : Qt.darker(IndexTheme.cyanDark, 1.5)
    border.width: IndexTheme.borderWidth
    opacity: enabled ? 1 : 0.55

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                text: root.label
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.bodySize
                color: IndexTheme.cyanBright
            }
            Text {
                visible: root.detail.length > 0
                text: root.detail
                font.family: IndexTheme.pixel
                font.pixelSize: IndexTheme.tinySize
                color: IndexTheme.cyanDark
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
        Text {
            text: ">"
            font.family: IndexTheme.pixel
            font.pixelSize: IndexTheme.bodySize
            color: IndexTheme.cyan
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
