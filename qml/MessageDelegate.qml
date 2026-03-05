import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string role
    required property string content
    required property bool isStreaming

    width: ListView.view ? ListView.view.width : 400
    height: bubble.height + Theme.spacingSm

    readonly property bool isUser: role === "user"

    Rectangle {
        id: bubble

        anchors {
            right: isUser ? parent.right : undefined
            left: isUser ? undefined : parent.left
            rightMargin: Theme.spacingMd
            leftMargin: Theme.spacingMd
        }

        width: Math.min(msgText.implicitWidth + Theme.spacingLg * 2,
                        root.width * 0.8)
        height: msgText.implicitHeight + Theme.spacingMd * 2
        radius: Theme.radiusLg
        color: isUser ? Theme.userBubble : Theme.bgCard

        Text {
            id: msgText

            anchors {
                fill: parent
                margins: Theme.spacingMd
            }

            text: content + (isStreaming ? " _" : "")
            textFormat: isUser ? Text.PlainText : Text.MarkdownText
            wrapMode: Text.Wrap
            color: Theme.textPrimary
            font.pixelSize: Theme.fontMd
            lineHeight: 1.5

            onLinkActivated: (link) => Qt.openUrlExternally(link)
        }
    }
}
