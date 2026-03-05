import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var messageModel

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

            // Auto-scroll to bottom on new content
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

                    placeholderText: "Type a message..."
                    wrapMode: TextArea.Wrap
                    color: Theme.textPrimary
                    placeholderTextColor: Theme.textMuted
                    font.pixelSize: Theme.fontMd

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
                }
            }

            Button {
                id: sendButton

                text: "Send"
                enabled: inputField.text.trim().length > 0

                contentItem: Text {
                    text: sendButton.text
                    color: sendButton.enabled ? Theme.textPrimary : Theme.textMuted
                    font.pixelSize: Theme.fontMd
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: 72
                    implicitHeight: 36
                    radius: Theme.radiusMd
                    color: sendButton.enabled ? Theme.accent : Theme.bgInput
                }

                onClicked: sendMessage()
            }
        }
    }

    function sendMessage() {
        const text = inputField.text.trim()
        if (text.length === 0) return

        root.messageModel.appendMessage("user", text)
        inputField.text = ""
        inputField.forceActiveFocus()
    }
}
