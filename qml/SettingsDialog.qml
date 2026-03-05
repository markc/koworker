import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings

Dialog {
    id: root

    required property var client

    title: "Settings"
    modal: true
    standardButtons: Dialog.Ok
    width: 480

    Settings {
        id: settings
        property string apiKey
        property string model: "claude-sonnet-4-20250514"
        property string systemPrompt
    }

    Component.onCompleted: {
        apiKeyField.text = settings.apiKey
        modelCombo.currentIndex = modelCombo.indexOfValue(settings.model)
        if (modelCombo.currentIndex < 0) modelCombo.currentIndex = 1
        systemPromptField.text = settings.systemPrompt

        // Apply saved settings to client
        root.client.apiKey = settings.apiKey
        root.client.model = settings.model
        root.client.systemPrompt = settings.systemPrompt
    }

    onAccepted: {
        settings.apiKey = apiKeyField.text
        settings.model = modelCombo.currentValue
        settings.systemPrompt = systemPromptField.text

        root.client.apiKey = apiKeyField.text
        root.client.model = modelCombo.currentValue
        root.client.systemPrompt = systemPromptField.text
    }

    background: Rectangle {
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLg
    }

    header: Label {
        text: root.title
        font.pixelSize: Theme.fontLg
        font.bold: true
        color: Theme.textPrimary
        padding: Theme.spacingMd
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMd

        Label {
            text: "API Key"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSm
        }

        TextField {
            id: apiKeyField
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: "sk-ant-..."
            color: Theme.textPrimary
            placeholderTextColor: Theme.textMuted
            font.pixelSize: Theme.fontMd

            background: Rectangle {
                radius: Theme.radiusMd
                color: Theme.bgInput
                border.color: apiKeyField.activeFocus ? Theme.accent : Theme.border
                border.width: 1
            }
        }

        Label {
            text: "Model"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSm
        }

        ComboBox {
            id: modelCombo
            Layout.fillWidth: true
            textRole: "text"
            valueRole: "value"
            model: [
                { text: "Claude Opus 4", value: "claude-opus-4-20250514" },
                { text: "Claude Sonnet 4", value: "claude-sonnet-4-20250514" },
                { text: "Claude Haiku 3.5", value: "claude-haiku-4-5-20251001" }
            ]

            contentItem: Text {
                text: modelCombo.displayText
                color: Theme.textPrimary
                font.pixelSize: Theme.fontMd
                verticalAlignment: Text.AlignVCenter
                leftPadding: Theme.spacingSm
            }

            background: Rectangle {
                radius: Theme.radiusMd
                color: Theme.bgInput
                border.color: Theme.border
                border.width: 1
            }
        }

        Label {
            text: "System Prompt"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSm
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 100

            TextArea {
                id: systemPromptField
                wrapMode: TextArea.Wrap
                placeholderText: "Optional system prompt..."
                color: Theme.textPrimary
                placeholderTextColor: Theme.textMuted
                font.pixelSize: Theme.fontMd

                background: Rectangle {
                    radius: Theme.radiusMd
                    color: Theme.bgInput
                    border.color: systemPromptField.activeFocus ? Theme.accent : Theme.border
                    border.width: 1
                }
            }
        }
    }
}
