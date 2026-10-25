#include "ai_manager.h"

#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrl>
#include <QVariantMap>

// 密钥由 CMake 在编译期注入；未注入时视为未配置，不阻断其他功能。
#ifndef DEEPSEEK_API_KEY
#define DEEPSEEK_API_KEY ""
#endif

namespace {

constexpr int kRequestTimeoutMs = 15000;

QString apiKey()
{
    return QString::fromUtf8(DEEPSEEK_API_KEY).trimmed();
}

QString rosterPrompt()
{
    return QStringLiteral("请生成 15 个中国风的学生姓名和学号，严格按 JSON 数组格式返回："
                          "[{\"name\":\"苏婉宁\",\"id\":\"001\"}]，不要包含其他任何废话");
}

}  // namespace

AiManager::AiManager(QObject *parent)
    : QObject(parent), network_(std::make_unique<QNetworkAccessManager>())
{
}

AiManager::~AiManager() = default;

void AiManager::generateMockRoster()
{
    requestCompletion(rosterPrompt(), RequestKind::MockRoster);
}

void AiManager::generateAwardSpeech(const QString &winnerName)
{
    const QString winner = winnerName.trimmed();
    if (winner.isEmpty()) {
        emit awardSpeechFailed(QStringLiteral("中奖者姓名为空"));
        return;
    }

    requestCompletion(
        QStringLiteral("请为抽奖中奖者【%1】写一句 20 字以内的幽默/励志颁奖词").arg(winner),
        RequestKind::AwardSpeech);
}

void AiManager::requestCompletion(const QString &prompt, RequestKind kind)
{
    const QString key = apiKey();
    if (key.isEmpty()) {
        emitFailure(kind, QStringLiteral("未配置 AI 密钥"));
        return;
    }

    QJsonObject message;
    message.insert(QStringLiteral("role"), QStringLiteral("user"));
    message.insert(QStringLiteral("content"), prompt);

    QJsonArray messages;
    messages.append(message);

    QJsonObject payload;
    payload.insert(QStringLiteral("model"), QStringLiteral("deepseek-chat"));
    payload.insert(QStringLiteral("messages"), messages);
    payload.insert(QStringLiteral("stream"), false);

    QNetworkRequest request(QUrl(QStringLiteral("https://api.deepseek.com/chat/completions")));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", "Bearer " + key.toUtf8());

    QNetworkReply *reply = network_->post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact));

    // 硬性超时：超时后中止请求，finished 中统一发出 networkError
    QTimer::singleShot(kRequestTimeoutMs, reply, [reply]() {
        if (reply->isRunning()) {
            qWarning() << "AI request timed out";
            reply->abort();
        }
    });

    connect(reply, &QNetworkReply::finished, this, [this, reply, kind]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "AI request failed:" << reply->errorString();
            const bool timedOut = reply->error() == QNetworkReply::OperationCanceledError;
            emit networkError(timedOut ? QStringLiteral("网络拥堵，请稍后再试")
                                       : QStringLiteral("网络异常，请稍后再试"));
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(reply->readAll());
        const QJsonArray choices = document.object().value(QStringLiteral("choices")).toArray();
        if (choices.isEmpty()) {
            emitFailure(kind, QStringLiteral("AI 返回内容为空"));
            return;
        }

        const QString content = choices.first()
                                    .toObject()
                                    .value(QStringLiteral("message"))
                                    .toObject()
                                    .value(QStringLiteral("content"))
                                    .toString()
                                    .trimmed();
        if (content.isEmpty()) {
            emitFailure(kind, QStringLiteral("AI 返回内容为空"));
            return;
        }

        if (kind == RequestKind::MockRoster) {
            const QVariantList roster = parseRoster(content);
            if (roster.isEmpty()) {
                emitFailure(kind, QStringLiteral("AI 返回的名单格式无法解析"));
                return;
            }
            emit mockRosterReady(roster);
            return;
        }

        const QString speech = cleanSpeech(content);
        if (speech.isEmpty()) {
            emitFailure(kind, QStringLiteral("AI 返回内容为空"));
            return;
        }
        emit awardSpeechReady(speech);
    });
}

void AiManager::emitFailure(RequestKind kind, const QString &message)
{
    if (kind == RequestKind::MockRoster) {
        emit mockRosterFailed(message);
    } else {
        emit awardSpeechFailed(message);
    }
}

QVariantList AiManager::parseRoster(const QString &content)
{
    const int start = content.indexOf(QLatin1Char('['));
    const int end = content.lastIndexOf(QLatin1Char(']'));
    if (start < 0 || end <= start) {
        return {};
    }

    const QJsonDocument document = QJsonDocument::fromJson(content.mid(start, end - start + 1).toUtf8());
    if (!document.isArray()) {
        return {};
    }

    QVariantList roster;
    for (const QJsonValue &value : document.array()) {
        const QJsonObject entry = value.toObject();
        const QString name = entry.value(QStringLiteral("name")).toString().trimmed();
        if (name.isEmpty()) {
            continue;
        }

        QVariantMap participant;
        participant.insert(QStringLiteral("name"), name);
        participant.insert(QStringLiteral("id"),
                           entry.value(QStringLiteral("id")).toVariant().toString().trimmed());
        roster.append(participant);
    }
    return roster;
}

QString AiManager::cleanSpeech(const QString &content)
{
    QString speech = content.trimmed();
    const QString quotes = QStringLiteral("\"'“”‘’");

    while (!speech.isEmpty() && quotes.contains(speech.front())) {
        speech.remove(0, 1);
    }
    while (!speech.isEmpty() && quotes.contains(speech.back())) {
        speech.chop(1);
    }
    return speech.trimmed();
}
