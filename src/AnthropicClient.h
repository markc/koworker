#pragma once

#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QObject>
#include <QtQml/qqmlregistration.h>

class QNetworkReply;

class AnthropicClient : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString apiKey READ apiKey WRITE setApiKey NOTIFY apiKeyChanged)
    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QString systemPrompt READ systemPrompt WRITE setSystemPrompt NOTIFY systemPromptChanged)
    Q_PROPERTY(bool running READ isRunning NOTIFY runningChanged)

public:
    explicit AnthropicClient(QObject *parent = nullptr);

    QString apiKey() const { return m_apiKey; }
    void setApiKey(const QString &key);

    QString model() const { return m_model; }
    void setModel(const QString &model);

    QString systemPrompt() const { return m_systemPrompt; }
    void setSystemPrompt(const QString &prompt);

    bool isRunning() const { return m_running; }

    Q_INVOKABLE void sendMessage(const QString &prompt);
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void newSession();
    Q_INVOKABLE void restoreMessage(const QString &role, const QString &content);

signals:
    void apiKeyChanged();
    void modelChanged();
    void systemPromptChanged();
    void runningChanged();
    void tokenReceived(const QString &token);
    void responseFinished();
    void errorOccurred(const QString &error);

private:
    void handleReadyRead();
    void handleFinished();
    void processSSELine(const QString &line);
    void setRunning(bool running);

    QNetworkAccessManager m_nam;
    QNetworkReply *m_reply{nullptr};
    QByteArray m_buffer;
    QString m_currentEvent;

    QString m_apiKey;
    QString m_model{QStringLiteral("claude-sonnet-4-20250514")};
    QString m_systemPrompt;
    QJsonArray m_messages;
    QString m_pendingResponse;
    bool m_running{false};
};
