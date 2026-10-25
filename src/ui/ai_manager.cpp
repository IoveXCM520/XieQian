#include "ai_manager.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>
#include <QVariantMap>

// 密钥由 CMake 在编译期注入；未注入时视为未配置，不阻断其他功能。
#ifndef DEEPSEEK_API_KEY
#define DEEPSEEK_API_KEY ""
#endif

namespace {

constexpr int kRequestTimeoutMs = 60000;

QString apiKey()
{
    return QStringLiteral(DEEPSEEK_API_KEY).trimmed();
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
    requestCompletion(
        rosterPrompt(),
        [this](const QString &content) {
            const QVariantList roster = parseRoster(content);
            if (roster.isEmpty()) {
                emit mockRosterFailed(QStringLiteral("AI 返回的名单格式无法解析"));
                return;
            }
            emit mockRosterReady(roster);
        },
        [this](const QString &message) { emit mockRosterFailed(message); });
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
        [this](const QString &content) {
            const QString speech = cleanSpeech(content);
            if (speech.isEmpty()) {
                emit awardSpeechFailed(QStringLiteral("AI 返回内容为空"));
                return;
            }
            emit awardSpeechReady(speech);
        },
        [this](const QString &message) { emit awardSpeechFailed(message); });
}

void AiManager::requestCompletion(const QString &prompt, const ContentHandler &onContent,
                                  const ContentHandler &onError)
{
    const QString key = apiKey();
    if (key.isEmpty()) {
        onError(QStringLiteral("未配置 AI 密钥"));
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
    request.setTransferTimeout(kRequestTimeoutMs);

    QNetworkReply *reply = network_->post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [reply, onContent, onError]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            onError(reply->errorString());
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(reply->readAll());
        const QJsonArray choices = document.object().value(QStringLiteral("choices")).toArray();
        if (choices.isEmpty()) {
            onError(QStringLiteral("AI 返回内容为空"));
            return;
        }

        const QString content = choices.front()
                                    .toObject()
                                    .value(QStringLiteral("message"))
                                    .toObject()
                                    .value(QStringLiteral("content"))
                                    .toString()
                                    .trimmed();
        if (content.isEmpty()) {
            onError(QStringLiteral("AI 返回内容为空"));
            return;
        }

        onContent(content);
    });
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
