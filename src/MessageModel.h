#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QtQml/qqmlregistration.h>

struct Message {
    QString role;       // "user" or "assistant"
    QString content;
    bool isStreaming{false};
    qint64 timestamp{0};
};

class MessageModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        RoleRole = Qt::UserRole + 1,
        ContentRole,
        IsStreamingRole,
        TimestampRole,
    };

    explicit MessageModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void appendMessage(const QString &role, const QString &content);
    Q_INVOKABLE void appendDelta(int index, const QString &token);
    Q_INVOKABLE void finalise(int index);
    Q_INVOKABLE void clear();

    int lastIndex() const;

private:
    QList<Message> m_messages;
};
