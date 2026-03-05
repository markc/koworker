import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

Dialog {
    id: root

    required property var client

    title: "Settings"
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    width: 440
    padding: Theme.spacingLg

    Settings {
        id: settings
        property string apiKey
        property string model: "claude-sonnet-4-20250514"
        property string systemPrompt
    }

    onOpened: {
        apiKeyField.text = settings.apiKey
        modelCombo.currentIndex = modelCombo.indexOfValue(settings.model)
        if (modelCombo.currentIndex < 0) modelCombo.currentIndex = 1
        systemPromptField.text = settings.systemPrompt
    }

    onAccepted: {
        settings.apiKey = apiKeyField.text
        settings.model = modelCombo.currentValue
        settings.systemPrompt = systemPromptField.text

        root.client.apiKey = apiKeyField.text
        root.client.model = modelCombo.currentValue
        root.client.systemPrompt = systemPromptField.text
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingSm

        Label { text: "API Key"; font.pixelSize: Theme.fontSm; opacity: 0.6 }

        TextField {
            id: apiKeyField
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: "sk-ant-..."
            font.pixelSize: Theme.fontMd
        }

        Item { height: Theme.spacingXs }

        Label { text: "Model"; font.pixelSize: Theme.fontSm; opacity: 0.6 }

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
        }

        Item { height: Theme.spacingXs }

        Label { text: "System Prompt"; font.pixelSize: Theme.fontSm; opacity: 0.6 }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            TextArea {
                id: systemPromptField
                wrapMode: TextArea.Wrap
                placeholderText: "Optional system prompt..."
                font.pixelSize: Theme.fontMd
            }
        }
    }
}
