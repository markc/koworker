#include "AnthropicClient.h"

#include <QJsonDocument>
#include <QNetworkReply>
#include <QNetworkRequest>

static const QUrl API_URL{QStringLiteral("https://api.anthropic.com/v1/messages")};

AnthropicClient::AnthropicClient(QObject *parent)
    : QObject(parent)
{
}

void AnthropicClient::setApiKey(const QString &key)
{
    if (m_apiKey == key) return;
    m_apiKey = key;
    emit apiKeyChanged();
}

void AnthropicClient::setModel(const QString &model)
{
    if (m_model == model) return;
    m_model = model;
    emit modelChanged();
}

void AnthropicClient::setSystemPrompt(const QString &prompt)
{
    if (m_systemPrompt == prompt) return;
    m_systemPrompt = prompt;
    emit systemPromptChanged();
}

void AnthropicClient::setRunning(bool running)
{
    if (m_running == running) return;
    m_running = running;
    emit runningChanged();
}

void AnthropicClient::sendMessage(const QString &prompt)
{
    if (m_apiKey.isEmpty()) {
        emit errorOccurred(QStringLiteral("API key not set. Open Settings to configure."));
        return;
    }
    if (m_running) return;

    // Append user message to conversation history
    QJsonObject userMsg;
    userMsg[QStringLiteral("role")] = QStringLiteral("user");
    userMsg[QStringLiteral("content")] = prompt;
    m_messages.append(userMsg);

    // Build request body
    QJsonObject body;
    body[QStringLiteral("model")] = m_model;
    body[QStringLiteral("max_tokens")] = 8192;
    body[QStringLiteral("stream")] = true;
    body[QStringLiteral("messages")] = m_messages;

    if (!m_systemPrompt.isEmpty()) {
        body[QStringLiteral("system")] = m_systemPrompt;
    }

    QNetworkRequest req(API_URL);
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    req.setRawHeader("x-api-key", m_apiKey.toUtf8());
    req.setRawHeader("anthropic-version", "2023-06-01");

    m_buffer.clear();
    m_currentEvent.clear();
    m_pendingResponse.clear();

    m_reply = m_nam.post(req, QJsonDocument(body).toJson(QJsonDocument::Compact));

    connect(m_reply, &QNetworkReply::readyRead, this, &AnthropicClient::handleReadyRead);
    connect(m_reply, &QNetworkReply::finished, this, &AnthropicClient::handleFinished);

    setRunning(true);
}

void AnthropicClient::cancel()
{
    if (m_reply) {
        m_reply->abort();
    }
}

void AnthropicClient::newSession()
{
    cancel();
    m_messages = QJsonArray();
    m_pendingResponse.clear();
}

void AnthropicClient::handleReadyRead()
{
    if (!m_reply) return;

    m_buffer.append(m_reply->readAll());

    // Process complete lines from the buffer
    while (true) {
        int idx = m_buffer.indexOf('\n');
        if (idx < 0) break;

        QString line = QString::fromUtf8(m_buffer.left(idx)).trimmed();
        m_buffer.remove(0, idx + 1);

        processSSELine(line);
    }
}

void AnthropicClient::handleFinished()
{
    if (!m_reply) return;

    const auto error = m_reply->error();
    if (error != QNetworkReply::NoError && error != QNetworkReply::OperationCanceledError) {
        // Try to parse error response body
        QByteArray body = m_reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(body);
        QString msg;
        if (doc.isObject() && doc.object().contains(QStringLiteral("error"))) {
            auto errObj = doc.object()[QStringLiteral("error")].toObject();
            msg = errObj[QStringLiteral("message")].toString();
        }
        if (msg.isEmpty()) {
            msg = m_reply->errorString();
        }
        emit errorOccurred(msg);
    }

    // Append assistant response to conversation history
    if (!m_pendingResponse.isEmpty()) {
        QJsonObject assistantMsg;
        assistantMsg[QStringLiteral("role")] = QStringLiteral("assistant");
        assistantMsg[QStringLiteral("content")] = m_pendingResponse;
        m_messages.append(assistantMsg);
    }

    m_reply->deleteLater();
    m_reply = nullptr;
    setRunning(false);
    emit responseFinished();
}

void AnthropicClient::processSSELine(const QString &line)
{
    if (line.startsWith(QStringLiteral("event:"))) {
        m_currentEvent = line.mid(6).trimmed();
        return;
    }

    if (!line.startsWith(QStringLiteral("data:"))) return;

    QString data = line.mid(5).trimmed();
    if (data == QStringLiteral("[DONE]")) return;

    QJsonDocument doc = QJsonDocument::fromJson(data.toUtf8());
    if (!doc.isObject()) return;

    QJsonObject obj = doc.object();
    QString type = obj[QStringLiteral("type")].toString();

    if (type == QStringLiteral("content_block_delta")) {
        QJsonObject delta = obj[QStringLiteral("delta")].toObject();
        if (delta[QStringLiteral("type")].toString() == QStringLiteral("text_delta")) {
            QString text = delta[QStringLiteral("text")].toString();
            m_pendingResponse += text;
            emit tokenReceived(text);
        }
    } else if (type == QStringLiteral("error")) {
        QJsonObject errObj = obj[QStringLiteral("error")].toObject();
        emit errorOccurred(errObj[QStringLiteral("message")].toString());
    }
}
