// WILL OF THE CITY :: THE INDEX — shared shell visual constants
pragma Singleton
import QtQuick

QtObject {
    readonly property string pixel: "Perfect DOS VGA 437 Universal"

    readonly property color background: "#0a0e16"
    readonly property color backgroundDeep: "#05080d"
    readonly property color surface: "#0c1620"
    readonly property color surfaceHover: "#143245"

    readonly property color cyan: "#5DADE2"
    readonly property color cyanBright: "#85C5E8"
    readonly property color cyanDark: "#3A7CA5"
    readonly property color warning: "#FF6B6B"
    readonly property color success: "#5DE285"
    readonly property color ink: "#04141c"

    readonly property int panelMargin: 14
    readonly property int sectionSpacing: 12
    readonly property int rowSpacing: 6
    readonly property int borderWidth: 1
    readonly property int panelBorderWidth: 2

    readonly property int titleSize: 17
    readonly property int bodySize: 13
    readonly property int smallSize: 11
    readonly property int tinySize: 10

    readonly property int fastAnimation: 160
    readonly property int normalAnimation: 200
}
