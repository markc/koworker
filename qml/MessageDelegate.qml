import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property int index
    required property string role
    required property string content
    required property bool isStreaming

    width: ListView.view ? ListView.view.width : 400
    implicitHeight: bubble.height + Theme.spacingXs

    readonly property bool isUser: role === "user"

    // User bubbles: alternateBase, Assistant bubbles: base
    Rectangle {
        id: bubble

        anchors {
            left: isUser ? undefined : parent.left
            right: isUser ? parent.right : undefined
            leftMargin: isUser ? parent.width * 0.2 : Theme.spacingMd
            rightMargin: isUser ? Theme.spacingMd : parent.width * 0.2
        }

        width: Math.min(msgText.implicitWidth + Theme.spacingLg,
                        parent.width - (isUser ? parent.width * 0.2 : 0) - Theme.spacingMd)
        height: msgText.implicitHeight + Theme.spacingMd * 2
        radius: Theme.radiusLg
        color: isUser ? root.palette.alternateBase : root.palette.base

        Text {
            id: msgText
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.spacingMd
            }
            text: root.content + (root.isStreaming ? " \u258c" : "")
            textFormat: root.isUser ? Text.PlainText : Text.MarkdownText
            wrapMode: Text.Wrap
            color: root.palette.text
            font.pixelSize: Theme.fontMd
            lineHeight: 1.4
            onLinkActivated: (link) => Qt.openUrlExternally(link)
        }
    }
}
