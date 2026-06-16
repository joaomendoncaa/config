import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Core
import qs.Modules.Bar

Item {
    id: root

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")
    property bool passwordPamConfigured: false
    property bool authenticating: false
    property bool locked: false
    property bool idleEnabled: true
    property string failureMessage: ""
    property string pendingPassword: ""
    property int cursorBlink: 0
    property int spinnerIndex: 0
    readonly property var spinnerFrames: ["|", "/", "-", "\\"]
    property bool windowReady: false

    function lock() {
        if (locked)
            return false;

        if (!passwordPamConfigured)
            return false;

        failureMessage = "";
        authenticating = false;
        locked = true;
        lockWindow.visible = true;
        forcePasswordFocus();
        return true;
    }

    function unlock() {
        locked = false;
        authenticating = false;
        lockWindow.visible = false;
    }

    function forcePasswordFocus() {
        Qt.callLater(function() {
            pwInput.forceActiveFocus();
        });
    }

    function submitPassword(pw) {
        if (!locked || authenticating || pw.length === 0)
            return ;

        failureMessage = "";
        authenticating = true;
        pendingPassword = pw;
        if (!passwordPam.start()) {
            authenticating = false;
            failureMessage = "PAM error";
            return ;
        }
        Qt.callLater(function() {
            respondToPam();
        });
    }

    function respondToPam() {
        if (authenticating && passwordPam.active && passwordPam.responseRequired)
            passwordPam.respond(pendingPassword);

    }

    Timer {
        interval: Config.cursorBlinkInterval
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

    IdleMonitor {
        id: mon

        enabled: root.idleEnabled
        timeout: Config.idleLockTimeout
        respectInhibitors: true
        onIsIdleChanged: {
            if (mon.isIdle && root.idleEnabled)
                root.lock();

        }
    }

    PanelWindow {
        id: lockWindow

        visible: false
        color: "transparent"
        WlrLayershell.namespace: "quickshell-lock"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Component.onCompleted: Qt.callLater(function() { root.windowReady = true })

        Rectangle {
            anchors.fill: parent
            color: "#000"

            Item {
                anchors.fill: parent
                opacity: root.windowReady ? 1 : 0

                CenterBar {
                    showAux: false
                    anchors.top: parent.top
                    anchors.topMargin: Config.shellPadding + Math.round((Config.height - Config.buttonSize) / 2)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Item {
                    anchors.centerIn: parent
                    width: 360

                    Rectangle {
                        id: inputRect
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 360
                        height: 50
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
                            onAccepted: {
                                var p = text;
                                text = "";
                                root.submitPassword(p);
                            }
                            onTextChanged: root.failureMessage = ""
                            Keys.onEscapePressed: text = ""
                            Keys.onPressed: function(event) {
                                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U) {
                                    text = "";
                                    event.accepted = true;
                                }
                            }

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
                        }
                    }

                    Text {
                        anchors.top: inputRect.bottom
                        anchors.topMargin: 10
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        text: "UNAUTHORIZED"
                        visible: root.failureMessage.length > 0
                        color: "#e94560"
                        font.pixelSize: Config.fontSize
                        font.family: Config.fontFamily
                        font.letterSpacing: 1
                        font.bold: true
                    }
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
            authenticating = false;
            if (r === PamResult.Success) {
                root.unlock();
            } else {
                failureMessage = "Wrong password";
                pwInput.forceActiveFocus();
            }
        }
        onError: function(e) {
            authenticating = false;
            failureMessage = "Error";
        }
    }

    FileView {
        path: "/etc/pam.d/lock-password"
        onLoaded: root.passwordPamConfigured = true
        onLoadFailed: root.passwordPamConfigured = false
    }

    IpcHandler {
        function lock() : string {
            return root.lock() ? "ok" : (root.passwordPamConfigured ? "failed" : "missing-pam");
        }

        function isLocked() : string {
            return root.locked ? "true" : "false";
        }

        function status() : string {
            return JSON.stringify({
                "locked": root.locked
            });
        }

        target: "lock"
    }

    IpcHandler {
        function status() : string {
            return JSON.stringify({
                "enabled": root.idleEnabled,
                "idle": mon.isIdle,
                "timeout": Config.idleLockTimeout
            });
        }

        function enable() : string {
            root.idleEnabled = true;
            return "ok";
        }

        function disable() : string {
            root.idleEnabled = false;
            return "ok";
        }

        target: "idle"
    }

}
