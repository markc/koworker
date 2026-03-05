import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var messageModel
    required property var client

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
            spacing: 0

            delegate: MessageDelegate {
                role: model.role
                content: model.content
                isStreaming: model.isStreaming
            }

            onCountChanged: {
                Qt.callLater(() => messageList.positionViewAtEnd())
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: messageList.count === 0
                text: "Start a conversation"
                color: Theme.textMuted
                font.pixelSize: Theme.fontLg
            }
        }

        // Error bar
        Rectangle {
            id: errorBar
            Layout.fillWidth: true
            height: errorBar.visible ? errorLabel.implicitHeight + Theme.spacingMd * 2 : 0
            color: "#4d331a"
            visible: errorLabel.text.length > 0

            Label {
                id: errorLabel
                anchors {
                    fill: parent
                    margins: Theme.spacingMd
                }
                color: "#ffaa55"
                font.pixelSize: Theme.fontSm
                wrapMode: Text.Wrap
            }

            MouseArea {
                anchors.fill: parent
                onClicked: errorLabel.text = ""
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        // Input bar
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacingMd
            spacing: Theme.spacingSm

            ScrollView {
                Layout.fillWidth: true
                Layout.maximumHeight: 120

                TextArea {
                    id: inputField

                    placeholderText: "Type a message... (Ctrl+Enter to send)"
                    wrapMode: TextArea.Wrap
                    color: Theme.textPrimary
                    placeholderTextColor: Theme.textMuted
                    font.pixelSize: Theme.fontMd
                    enabled: !root.client.running

                    background: Rectangle {
                        radius: Theme.radiusMd
                        color: Theme.bgInput
                        border.color: inputField.activeFocus ? Theme.accent : Theme.border
                        border.width: 1
                    }

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

            Button {
                id: actionButton

                text: root.client.running ? "Stop" : "Send"
                enabled: root.client.running || inputField.text.trim().length > 0

                contentItem: Text {
                    text: actionButton.text
                    color: actionButton.enabled ? Theme.textPrimary : Theme.textMuted
                    font.pixelSize: Theme.fontMd
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: 72
                    implicitHeight: 36
                    radius: Theme.radiusMd
                    color: {
                        if (!actionButton.enabled) return Theme.bgInput
                        return root.client.running ? Theme.accentMuted : Theme.accent
                    }
                }

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

    // Track streaming assistant message index
    property int streamingIndex: -1

    Connections {
        target: root.client

        function onTokenReceived(token) {
            if (root.streamingIndex < 0) {
                // Start a new assistant message
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
