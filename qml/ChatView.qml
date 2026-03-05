import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    required property var messageModel
    required property var client
    color: palette.window

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Message list
        ListView {
            id: messageList

            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.messageModel
            clip: true
            spacing: Theme.spacingXs
            topMargin: Theme.spacingMd
            bottomMargin: Theme.spacingMd

            delegate: MessageDelegate { }

            onCountChanged: {
                Qt.callLater(() => messageList.positionViewAtEnd())
            }

            Label {
                anchors.centerIn: parent
                visible: messageList.count === 0
                text: "Start a conversation"
                opacity: 0.3
                font.pixelSize: Theme.fontLg
            }
        }

        // Error bar
        Rectangle {
            Layout.fillWidth: true
            visible: errorLabel.text.length > 0
            implicitHeight: errorLabel.implicitHeight + Theme.spacingMd * 2
            color: Qt.rgba(0.6, 0.2, 0.1, 0.3)

            Label {
                id: errorLabel
                anchors {
                    fill: parent
                    margins: Theme.spacingMd
                }
                wrapMode: Text.Wrap
                color: Qt.rgba(1.0, 0.5, 0.3, 1.0)
                font.pixelSize: Theme.fontSm
            }

            MouseArea {
                anchors.fill: parent
                onClicked: errorLabel.text = ""
            }
        }

        // Input area — palette.base (darker, like kcalc display)
        Rectangle {
            Layout.fillWidth: true
            color: palette.base

            implicitHeight: inputRow.implicitHeight + Theme.spacingMd * 2

            RowLayout {
                id: inputRow
                anchors {
                    fill: parent
                    margins: Theme.spacingMd
                }
                spacing: Theme.spacingSm

                ScrollView {
                    Layout.fillWidth: true
                    Layout.maximumHeight: 120

                    TextArea {
                        id: inputField
                        placeholderText: "Type a message... (Ctrl+Enter to send)"
                        wrapMode: TextArea.Wrap
                        font.pixelSize: Theme.fontMd
                        enabled: !root.client.running
                        background: null

                        Keys.onReturnPressed: (event) => {
                            if (event.modifiers & Qt.ControlModifier) {
                                sendMessage()
                            } else {
                                event.accepted = false
                            }
                        }

                        Keys.onEscapePressed: {
                            if (root.client.running) root.client.cancel()
                        }
                    }
                }

                ToolButton {
                    icon.name: root.client.running ? "process-stop" : "document-send"
                    enabled: root.client.running || inputField.text.trim().length > 0
                    ToolTip.text: root.client.running ? "Stop" : "Send (Ctrl+Enter)"
                    ToolTip.visible: hovered

                    onClicked: {
                        if (root.client.running) {
                            root.client.cancel()
                        } else {
                            sendMessage()
                        }
                    }
                }
            }
        }
    }

    // Track streaming assistant message index
    property int streamingIndex: -1

    Connections {
        target: root.client

        function onTokenReceived(token) {
            if (root.streamingIndex < 0) {
                root.messageModel.appendMessage("assistant", "")
                root.streamingIndex = root.messageModel.lastIndex()
            }
            root.messageModel.appendDelta(root.streamingIndex, token)
        }

        function onResponseFinished() {
            if (root.streamingIndex >= 0) {
                root.messageModel.finalise(root.streamingIndex)
                root.streamingIndex = -1
            }
            inputField.forceActiveFocus()
        }

        function onErrorOccurred(error) {
            errorLabel.text = error
            if (root.streamingIndex >= 0) {
                root.messageModel.finalise(root.streamingIndex)
                root.streamingIndex = -1
            }
        }
    }

    function sendMessage() {
        const text = inputField.text.trim()
        if (text.length === 0) return

        errorLabel.text = ""
        root.messageModel.appendMessage("user", text)
        root.client.sendMessage(text)
        inputField.text = ""
    }
}
