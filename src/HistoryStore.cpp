#include "HistoryStore.h"

#include <QDir>
#include <QJsonObject>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QUuid>

HistoryStore::HistoryStore(QObject *parent)
    : QObject(parent)
{
    init();
}

void HistoryStore::init()
{
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"),
                                     QStringLiteral("koworker_history"));
    m_db.setDatabaseName(dataDir + QStringLiteral("/history.db"));

    if (!m_db.open()) {
        qWarning("HistoryStore: failed to open database: %s",
                 qPrintable(m_db.lastError().text()));
        return;
    }

    migrate();
}

void HistoryStore::migrate()
{
    QSqlQuery q(m_db);
    q.exec(QStringLiteral("PRAGMA user_version"));
    q.next();
    const int version = q.value(0).toInt();

    if (version < 1) {
        q.exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS sessions ("
            "  id TEXT PRIMARY KEY,"
            "  title TEXT,"
            "  created_at INTEGER,"
            "  updated_at INTEGER"
            ")"));
        q.exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS messages ("
            "  id TEXT PRIMARY KEY,"
            "  session_id TEXT REFERENCES sessions(id),"
            "  role TEXT,"
            "  content TEXT,"
            "  timestamp INTEGER"
            ")"));
        q.exec(QStringLiteral("PRAGMA user_version = 1"));
    }
}

QString HistoryStore::createSession()
{
    const QString id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const qint64 now = QDateTime::currentSecsSinceEpoch();

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "INSERT INTO sessions (id, title, created_at, updated_at) VALUES (?, ?, ?, ?)"));
    q.addBindValue(id);
    q.addBindValue(QString());
    q.addBindValue(now);
    q.addBindValue(now);
    q.exec();

    return id;
}

void HistoryStore::saveMessage(const QString &sessionId, const QString &role, const QString &content)
{
    const QString id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const qint64 now = QDateTime::currentSecsSinceEpoch();

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "INSERT INTO messages (id, session_id, role, content, timestamp) VALUES (?, ?, ?, ?, ?)"));
    q.addBindValue(id);
    q.addBindValue(sessionId);
    q.addBindValue(role);
    q.addBindValue(content);
    q.addBindValue(now);
    q.exec();

    // Update session timestamp and auto-title from first user message
    QSqlQuery u(m_db);
    u.prepare(QStringLiteral("UPDATE sessions SET updated_at = ? WHERE id = ?"));
    u.addBindValue(now);
    u.addBindValue(sessionId);
    u.exec();

    if (role == QStringLiteral("user")) {
        QSqlQuery t(m_db);
        t.prepare(QStringLiteral(
            "UPDATE sessions SET title = ? WHERE id = ? AND (title IS NULL OR title = '')"));
        t.addBindValue(content.left(80));
        t.addBindValue(sessionId);
        t.exec();
    }
}

QJsonArray HistoryStore::loadSession(const QString &sessionId)
{
    QJsonArray result;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "SELECT role, content FROM messages WHERE session_id = ? ORDER BY timestamp"));
    q.addBindValue(sessionId);
    q.exec();

    while (q.next()) {
        QJsonObject msg;
        msg[QStringLiteral("role")] = q.value(0).toString();
        msg[QStringLiteral("content")] = q.value(1).toString();
        result.append(msg);
    }
    return result;
}

QJsonArray HistoryStore::listSessions()
{
    QJsonArray result;
    QSqlQuery q(m_db);
    q.exec(QStringLiteral(
        "SELECT id, title, updated_at FROM sessions ORDER BY updated_at DESC"));

    while (q.next()) {
        QJsonObject session;
        session[QStringLiteral("id")] = q.value(0).toString();
        session[QStringLiteral("title")] = q.value(1).toString();
        session[QStringLiteral("updated_at")] = q.value(2).toDouble();
        result.append(session);
    }
    return result;
}

void HistoryStore::deleteSession(const QString &sessionId)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM messages WHERE session_id = ?"));
    q.addBindValue(sessionId);
    q.exec();

    q.prepare(QStringLiteral("DELETE FROM sessions WHERE id = ?"));
    q.addBindValue(sessionId);
    q.exec();
}

void HistoryStore::updateTitle(const QString &sessionId, const QString &title)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE sessions SET title = ? WHERE id = ?"));
    q.addBindValue(title);
    q.addBindValue(sessionId);
    q.exec();
}
