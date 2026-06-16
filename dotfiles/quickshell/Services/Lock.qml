import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Core

Item {
    id: root

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")
    property bool passwordPamConfigured: false
    property bool authenticating: false
    property bool locked: false
    property string failureMessage: ""
    property string pendingPassword: ""
    property int cursorBlink: 0
    property int spinnerIndex: 0
    readonly property var spinnerFrames: ["\u2813", "\u2819", "\u2819", "\u281C", "\u2834", "\u2826", "\u2827", "\u280B"]

    Timer {
        interval: 530
        running: true
        repeat: true
        onTriggered: root.cursorBlink = root.cursorBlink === 0 ? 1 : 0
    }

    Timer {
        interval: 100
        running: root.authenticating
        repeat: true
        onTriggered: root.spinnerIndex = (root.spinnerIndex + 1) % root.spinnerFrames.length
    }

    function lock() {
        if (locked) return false
        if (!passwordPamConfigured) return false
        failureMessage = ""
        authenticating = false
        locked = true
        lockWindow.visible = true
        forcePasswordFocus()
        return true
    }

    function unlock() {
        locked = false
        authenticating = false
        lockWindow.visible = false
    }

    function forcePasswordFocus() {
        Qt.callLater(function() { pwInput.forceActiveFocus() })
    }

    function submitPassword(pw) {
        if (!locked || authenticating || pw.length === 0) return
        failureMessage = ""
        authenticating = true
        pendingPassword = pw
        if (!passwordPam.start()) {
            authenticating = false
            failureMessage = "PAM error"
            return
        }
        Qt.callLater(function() { respondToPam() })
    }

    function respondToPam() {
        if (authenticating && passwordPam.active && passwordPam.responseRequired)
            passwordPam.respond(pendingPassword)
    }

    PanelWindow {
        id: lockWindow
        visible: false
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        WlrLayershell.namespace: "quickshell-lock"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: "#000"

            Item {
                anchors.centerIn: parent
                width: 360
                height: 50

                Rectangle {
                    anchors.fill: parent
                    color: "#111"
                    radius: Config.buttonBorderRadius
                    border.color: root.authenticating ? "#111" : (root.failureMessage ? "#e94560" : "#333")
                    border.width: Config.borderSize
                    clip: true

                    TextInput {
                        id: pwInput
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        color: "white"
                        font.pixelSize: Config.fontSize
                        font.family: Config.fontFamily
                        font.letterSpacing: 4
                        focus: true
                        echoMode: TextInput.Password
                        passwordCharacter: "\u25CF"
                        horizontalAlignment: TextInput.AlignLeft
                        verticalAlignment: TextInput.AlignVCenter
                        readOnly: root.authenticating
                        cursorDelegate: Item {
                            width: root.authenticating ? 16 : 10
                            height: Config.fontSize + 4

                            Rectangle {
                                anchors.fill: parent
                                color: "white"
                                visible: !root.authenticating && pwInput.activeFocus && root.cursorBlink === 0
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.spinnerFrames[root.spinnerIndex]
                                color: "white"
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize
                                font.letterSpacing: 0
                                visible: root.authenticating
                            }
                        }
                        onAccepted: { var p = text; text = ""; root.submitPassword(p) }
                        onTextChanged: root.failureMessage = ""
                        Keys.onEscapePressed: text = ""
                        Keys.onPressed: function(event) {
                            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U) {
                                text = ""
                                event.accepted = true
                            }
                        }
                    }
                }

                Text {
                    anchors.top: parent.bottom
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    text: "UNAUTHORIZED"
                    visible: root.failureMessage.length > 0
                    color: "#e94560"
                    font.pixelSize: 12
                    font.family: Config.fontFamily
                    font.letterSpacing: 2
                    font.bold: true
                }
            }
        }
    }

    PamContext {
        id: passwordPam
        config: "lock-password"
        user: root.userName
        onResponseRequiredChanged: root.respondToPam()
        onPamMessage: root.respondToPam()
        onCompleted: function(r) {
            authenticating = false
            if (r === PamResult.Success) root.unlock()
            else { failureMessage = "Wrong password"; pwInput.forceActiveFocus() }
        }
        onError: function(e) {
            authenticating = false
            failureMessage = "Error"
        }
    }

    FileView {
        path: "/etc/pam.d/lock-password"
        onLoaded: root.passwordPamConfigured = true
        onLoadFailed: root.passwordPamConfigured = false
    }

    IpcHandler {
        target: "lock"
        function lock(): string { return root.lock() ? "ok" : (root.passwordPamConfigured ? "failed" : "missing-pam") }
        function isLocked(): string { return root.locked ? "true" : "false" }
        function status(): string { return JSON.stringify({ locked: root.locked }) }
    }
}
