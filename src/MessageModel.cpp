#include "MessageModel.h"

MessageModel::MessageModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int MessageModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_messages.size();
}

QVariant MessageModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_messages.size())
        return {};

    const auto &msg = m_messages[index.row()];
    switch (role) {
    case RoleRole:        return msg.role;
    case ContentRole:     return msg.content;
    case IsStreamingRole: return msg.isStreaming;
    case TimestampRole:   return msg.timestamp;
    }
    return {};
}

QHash<int, QByteArray> MessageModel::roleNames() const
{
    return {
        {RoleRole, "role"},
        {ContentRole, "content"},
        {IsStreamingRole, "isStreaming"},
        {TimestampRole, "timestamp"},
    };
}

void MessageModel::appendMessage(const QString &role, const QString &content)
{
    const int row = m_messages.size();
    beginInsertRows({}, row, row);
    m_messages.append({role, content, false, QDateTime::currentSecsSinceEpoch()});
    endInsertRows();
}

void MessageModel::appendDelta(int index, const QString &token)
{
    if (index < 0 || index >= m_messages.size())
        return;

    m_messages[index].content += token;
    m_messages[index].isStreaming = true;
    const auto idx = createIndex(index, 0);
    emit dataChanged(idx, idx, {ContentRole, IsStreamingRole});
}

void MessageModel::finalise(int index)
{
    if (index < 0 || index >= m_messages.size())
        return;

    m_messages[index].isStreaming = false;
    const auto idx = createIndex(index, 0);
    emit dataChanged(idx, idx, {IsStreamingRole});
}

void MessageModel::clear()
{
    if (m_messages.isEmpty())
        return;

    beginResetModel();
    m_messages.clear();
    endResetModel();
}

int MessageModel::lastIndex() const
{
    return m_messages.size() - 1;
}
