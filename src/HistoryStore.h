#pragma once

#include <QJsonArray>
#include <QObject>
#include <QSqlDatabase>
#include <QtQml/qqmlregistration.h>

class HistoryStore : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit HistoryStore(QObject *parent = nullptr);

    Q_INVOKABLE QString createSession();
    Q_INVOKABLE void saveMessage(const QString &sessionId, const QString &role, const QString &content);
    Q_INVOKABLE QJsonArray loadSession(const QString &sessionId);
    Q_INVOKABLE QJsonArray listSessions();
    Q_INVOKABLE void deleteSession(const QString &sessionId);
    Q_INVOKABLE void updateTitle(const QString &sessionId, const QString &title);

private:
    void init();
    void migrate();

    QSqlDatabase m_db;
};
