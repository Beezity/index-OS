// ============================================================
//  WILL OF THE CITY :: THE INDEX — Quickshell session lock
//  Quickshell 0.3+ / ext-session-lock-v1 / PAM authentication.
//
//  WlSessionLock creates one surface per output. Authentication state lives
//  at the ShellRoot so every monitor shares one PAM transaction and a
//  successful login unlocks the whole session.
// ============================================================

import QtQuick
import QtQuick.Layouts
import QtMultimedia
import QtCore
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    readonly property string username: Quickshell.env("USER") || "user"
    property string pendingPassword: ""
    property bool authBusy: false
    property string authMessage: ""
    property bool authFailed: false
    property int failCount: 0
    property bool unlocking: false

    signal clearPasswords()

    Settings {
        id: lockSettings
        property real volume: 0.5
    }

    function authenticate(password) {
        if (root.authBusy || root.unlocking || password.length === 0)
            return

        root.pendingPassword = password
        root.authBusy = true
        root.authFailed = false
        root.authMessage = ">_ VERIFYING._"

        if (!pam.start()) {
            root.authBusy = false
            root.authFailed = true
            root.authMessage = ">_ AUTHENTICATION ERROR._"
            root.pendingPassword = ""
            root.clearPasswords()
        }
    }

    PamContext {
        id: pam
        config: "login"
        user: root.username

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.pendingPassword)
        }

        onCompleted: function(result) {
            root.pendingPassword = ""
            root.authBusy = false

            if (result === PamResult.Success) {
                root.authFailed = false
                root.authMessage = ">_ ACCESS GRANTED._"
                root.unlocking = true
                unlockTimer.start()
            } else {
                root.failCount += 1
                root.authFailed = true
                root.authMessage = root.failCount >= 3
                    ? ">_ WILL OF THE CITY: AUTHORIZATION DENIED._"
                    : ">_ ACCESS DENIED._"
                root.clearPasswords()
                clearStatusTimer.restart()
            }
        }

        onError: function(error) {
            root.pendingPassword = ""
            root.authBusy = false
            root.authFailed = true
            root.authMessage = ">_ PAM ERROR._"
            root.clearPasswords()
            clearStatusTimer.restart()
        }
    }

    Timer {
        id: clearStatusTimer
        interval: 1800
        repeat: false
        onTriggered: {
            if (!root.authBusy && !root.unlocking) {
                root.authMessage = ""
                root.authFailed = false
            }
        }
    }

    Timer {
        id: unlockTimer
        interval: 500
        repeat: false
        onTriggered: {
            sessionLock.locked = false
            Qt.quit()
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            id: surf
            color: "#000000"

            readonly property color cyan: "#5DADE2"
            readonly property color cyanBright: "#85C5E8"
            readonly property color cyanDim: "#3A7CA5"
            readonly property color warnColor: "#FF6B6B"
            readonly property color successColor: "#5DE285"
            readonly property bool audioSurface: Quickshell.screens.length === 0 || surf.screen === Quickshell.screens[0]

            property bool introActive: false

            FontLoader {
                id: pixelFont
                source: Qt.resolvedUrl("assets/PerfectDOSVGA437-Universal.ttf")
            }

            function soundPath(name) {
                return Qt.resolvedUrl("assets/sounds/" + name).toString().replace("file://", "")
            }

            function playSound(name) {
                if (!surf.audioSurface)
                    return
                Quickshell.execDetached([
                    "pw-play",
                    "--volume=" + lockSettings.volume.toFixed(2),
                    soundPath(name)
                ])
            }

            MediaPlayer {
                id: backgroundMusic
                source: Qt.resolvedUrl("assets/sounds/bg.mp3")
                loops: MediaPlayer.Infinite
                audioOutput: AudioOutput {
                    volume: surf.audioSurface ? lockSettings.volume : 0
                }
            }

            // Optional intro video. Missing/invalid video falls through to the
            // lock immediately. Only the primary output emits its audio.
            Item {
                id: introLayer
                anchors.fill: parent
                z: 1000
                visible: surf.introActive

                Rectangle { anchors.fill: parent; color: "#000000" }

                MediaPlayer {
                    id: introVideo
                    source: Qt.resolvedUrl("assets/intro.mp4")
                    videoOutput: introOutput
                    audioOutput: AudioOutput {
                        volume: surf.audioSurface ? 0.9 : 0
                    }
                    onMediaStatusChanged: {
                        if (mediaStatus === MediaPlayer.EndOfMedia || mediaStatus === MediaPlayer.InvalidMedia)
                            surf.endIntro()
                    }
                    onErrorOccurred: surf.endIntro()
                }

                VideoOutput {
                    id: introOutput
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectFit
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24
                    width: 100
                    height: 34
                    color: skipArea.containsMouse ? "#143245" : "#0a0e16"
                    border.color: surf.cyan
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "[SKIP]"
                        font.family: pixelFont.name
                        font.pixelSize: 15
                        color: surf.cyanBright
                    }

                    MouseArea {
                        id: skipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: surf.endIntro()
                    }
                }
            }

            function endIntro() {
                if (!surf.introActive)
                    return
                introVideo.stop()
                surf.introActive = false
                if (surf.audioSurface)
                    backgroundMusic.play()
                focusTimer.restart()
            }

            // CRT scanlines.
            Item {
                anchors.fill: parent
                z: 100
                opacity: 0.14
                Repeater {
                    model: Math.floor(surf.height / 4)
                    Rectangle {
                        width: surf.width
                        height: 2
                        y: index * 4 + 2
                        color: "#000000"
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: root.unlocking ? 1 : 0
                z: 900
                Behavior on opacity { NumberAnimation { duration: 450 } }
            }

            RowLayout {
                anchors.centerIn: parent
                width: Math.min(surf.width * 0.82, 1100)
                spacing: Math.max(30, Math.min(60, surf.width * 0.04))
                opacity: surf.introActive ? 0 : 1

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 28

                    Text {
                        id: clockText
                        font.family: pixelFont.name
                        font.pixelSize: Math.max(34, Math.min(56, surf.width / 28))
                        color: surf.cyanBright
                        style: Text.Outline
                        styleColor: surf.cyan
                        text: "_00:00 AM._"
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: {
                            var now = new Date()
                            var h = now.getHours()
                            var m = now.getMinutes()
                            var ap = h >= 12 ? "PM" : "AM"
                            h = h % 12 || 12
                            clockText.text = "_" + (h < 10 ? "0" : "") + h + ":" +
                                             (m < 10 ? "0" : "") + m + " " + ap + "._"
                        }
                    }

                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        source: Qt.resolvedUrl("assets/Logo.png")
                        sourceSize.width: 220
                        sourceSize.height: 220
                        fillMode: Image.PreserveAspectFit
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 16

                    Text {
                        text: "// THE INDEX"
                        font.family: pixelFont.name
                        font.pixelSize: 18
                        color: surf.cyanDim
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        color: "#05080d"
                        border.color: surf.cyan
                        border.width: 2

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10

                            Item {
                                width: 38
                                height: 38
                                Image {
                                    id: profileImage
                                    anchors.fill: parent
                                    source: Qt.resolvedUrl("assets/DefaultProfile.jpg")
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: !profileImage.visible
                                    text: "//"
                                    font.family: pixelFont.name
                                    font.pixelSize: 16
                                    color: surf.cyanDim
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "_" + root.username.toUpperCase() + "._"
                                font.family: pixelFont.name
                                font.pixelSize: 22
                                color: surf.cyanBright
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        color: "#05080d"
                        border.color: root.authFailed ? surf.warnColor : surf.cyan
                        border.width: 2

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.margins: 12
                            font.family: pixelFont.name
                            font.pixelSize: 21
                            color: surf.cyanBright
                            echoMode: TextInput.Password
                            passwordCharacter: "."
                            enabled: !root.authBusy && !root.unlocking && !surf.introActive
                            focus: enabled
                            verticalAlignment: TextInput.AlignVCenter
                            Keys.onReturnPressed: root.authenticate(text)
                            Keys.onEnterPressed: root.authenticate(text)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.authMessage
                        visible: text !== ""
                        font.family: pixelFont.name
                        font.pixelSize: 16
                        color: root.authFailed ? surf.warnColor : (root.unlocking ? surf.successColor : surf.cyan)
                    }

                    Rectangle {
                        Layout.preferredWidth: 180
                        height: 38
                        color: loginArea.containsMouse && !root.authBusy ? surf.cyan : "transparent"
                        border.color: surf.cyan
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.authBusy ? "<_VERIFYING._>" : "<_LOGIN._>"
                            font.family: pixelFont.name
                            font.pixelSize: 18
                            color: loginArea.containsMouse && !root.authBusy ? "#04141c" : surf.cyanBright
                        }

                        MouseArea {
                            id: loginArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: passwordInput.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                surf.playSound("click.wav")
                                root.authenticate(passwordInput.text)
                            }
                        }
                    }
                }
            }

            // Lock-screen volume control.
            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 28
                anchors.bottomMargin: 28
                spacing: 8
                z: 200

                Text {
                    text: "VOL"
                    font.family: pixelFont.name
                    font.pixelSize: 13
                    color: surf.cyanDim
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    id: volumeTrack
                    width: 120
                    height: 16
                    color: "#05080d"
                    border.color: surf.cyanDim
                    border.width: 1

                    Rectangle {
                        x: 2
                        y: 2
                        height: parent.height - 4
                        width: Math.max(0, (parent.width - 4) * lockSettings.volume)
                        color: surf.cyan
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: function(mouse) {
                            lockSettings.volume = Math.max(0, Math.min(1, mouse.x / width))
                        }
                        onPositionChanged: function(mouse) {
                            if (pressed)
                                lockSettings.volume = Math.max(0, Math.min(1, mouse.x / width))
                        }
                    }
                }

                Text {
                    text: Math.round(lockSettings.volume * 100) + "%"
                    font.family: pixelFont.name
                    font.pixelSize: 13
                    color: surf.cyanDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 28
                anchors.bottomMargin: 24
                spacing: 14
                z: 200

                Image {
                    source: Qt.resolvedUrl("assets/Restart.png")
                    sourceSize.width: 34
                    sourceSize.height: 34
                    scale: restartArea.containsMouse ? 1.1 : 1
                    MouseArea {
                        id: restartArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                    }
                }

                Image {
                    source: Qt.resolvedUrl("assets/Power.png")
                    sourceSize.width: 34
                    sourceSize.height: 34
                    scale: powerArea.containsMouse ? 1.1 : 1
                    MouseArea {
                        id: powerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                }
            }

            Connections {
                target: root
                function onClearPasswords() {
                    passwordInput.text = ""
                    if (!surf.introActive)
                        passwordInput.forceActiveFocus()
                    surf.playSound("fail.wav")
                }
            }

            Timer {
                id: focusTimer
                interval: 250
                repeat: false
                onTriggered: passwordInput.forceActiveFocus()
            }

            Component.onCompleted: {
                var showIntro = false
                try {
                    showIntro = String(Quickshell.env("INDEX_INTRO") || "") === "1"
                } catch (e) {
                    showIntro = false
                }

                if (showIntro) {
                    surf.introActive = true
                    introVideo.play()
                } else {
                    surf.introActive = false
                    if (surf.audioSurface)
                        backgroundMusic.play()
                    focusTimer.start()
                }
            }
        }
    }
}
