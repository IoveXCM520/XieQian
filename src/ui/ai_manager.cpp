#include "ai_manager.h"

#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrl>
#include <QVariantMap>

namespace {

constexpr int kRequestTimeoutMs = 15000;
// 图片上传比纯文本慢得多，OCR 单独放宽超时
constexpr int kOcrTimeoutMs = 60000;

// 内置备用配置：用户在设置页留空时使用，图片 OCR 始终使用这一套
constexpr const char *kBuiltinApiKey = "sk-2ff8932b775b4adf946ee873af51939d";
constexpr const char *kBuiltinBaseUrl = "https://api.deepseek.com";
constexpr const char *kBuiltinModel = "deepseek-chat";
constexpr const char *kOcrModel = "deepseek-v4-flash-vision-exp";

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

void AiManager::setApiConfig(const QString &apiKey, const QString &baseUrl, const QString &model)
{
    apiKey_ = apiKey.trimmed();
    baseUrl_ = baseUrl.trimmed();
    model_ = model.trimmed();
}

QString AiManager::effectiveApiKey() const
{
    if (!apiKey_.isEmpty()) {
        return apiKey_;
    }

    // 内置密钥只发给官方地址：用户填写了第三方中转地址却没填 Key 时，
    // 不应该把内置密钥带过去
    const QString base = baseUrl_.trimmed();
    if (!base.isEmpty()) {
        const QUrl url = QUrl::fromUserInput(base);
        if (url.host().compare(QStringLiteral("api.deepseek.com"), Qt::CaseInsensitive) != 0) {
            return QString();
        }
    }

    return QString::fromLatin1(kBuiltinApiKey);
}

QString AiManager::effectiveModel() const
{
    return model_.isEmpty() ? QString::fromLatin1(kBuiltinModel) : model_;
}

QString AiManager::endpointUrl() const
{
    QString base = baseUrl_.trimmed();
    if (base.isEmpty()) {
        base = QString::fromLatin1(kBuiltinBaseUrl);
    }

    if (!base.contains(QStringLiteral("://"))) {
        base.prepend(QStringLiteral("https://"));
    }

    while (base.endsWith(QLatin1Char('/'))) {
        base.chop(1);
    }

    // 允许用户填写 https://api.deepseek.com、.../v1，或直接填完整地址
    if (base.endsWith(QStringLiteral("/chat/completions"), Qt::CaseInsensitive)) {
        return base;
    }
    return base + QStringLiteral("/chat/completions");
}

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
    const QString key = effectiveApiKey();
    if (key.isEmpty()) {
        emitFailure(kind, QStringLiteral("未配置 AI 密钥"));
        return;
    }

    const QUrl endpoint(endpointUrl());
    if (!endpoint.isValid() || endpoint.host().isEmpty()) {
        emitFailure(kind, QStringLiteral("AI 接口地址无效，请在设置页检查"));
        return;
    }

    QJsonObject message;
    message.insert(QStringLiteral("role"), QStringLiteral("user"));
    message.insert(QStringLiteral("content"), prompt);

    QJsonArray messages;
    messages.append(message);

    QJsonObject payload;
    payload.insert(QStringLiteral("model"), effectiveModel());
    payload.insert(QStringLiteral("messages"), messages);
    payload.insert(QStringLiteral("stream"), false);

    QNetworkRequest request(endpoint);
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

void AiManager::ocrFromImage(const QString &filePath)
{
    QFile file(filePath);
    if (filePath.isEmpty() || !file.open(QIODevice::ReadOnly)) {
        qWarning() << "cannot open image for OCR:" << filePath;
        emit ocrFailed(QStringLiteral("图片识别失败，请重试或手动导入"));
        return;
    }

    const QByteArray raw = file.readAll();
    file.close();
    if (raw.isEmpty()) {
        qWarning() << "empty image for OCR:" << filePath;
        emit ocrFailed(QStringLiteral("图片识别失败，请重试或手动导入"));
        return;
    }

    const QString suffix = QFileInfo(filePath).suffix().toLower();
    const QString mime = suffix == QStringLiteral("png") ? QStringLiteral("image/png")
                                                        : QStringLiteral("image/jpeg");

    QJsonObject imageUrl;
    imageUrl.insert(QStringLiteral("url"),
                    QStringLiteral("data:%1;base64,%2")
                        .arg(mime, QString::fromLatin1(raw.toBase64())));

    QJsonObject imagePart;
    imagePart.insert(QStringLiteral("type"), QStringLiteral("image_url"));
    imagePart.insert(QStringLiteral("image_url"), imageUrl);

    QJsonObject textPart;
    textPart.insert(QStringLiteral("type"), QStringLiteral("text"));
    textPart.insert(QStringLiteral("text"),
                    QStringLiteral("请识别图片中的所有姓名，每行一个，只返回姓名列表，"
                                   "不要包含学号或其他文字。"));

    QJsonArray content;
    content.append(imagePart);
    content.append(textPart);

    QJsonObject message;
    message.insert(QStringLiteral("role"), QStringLiteral("user"));
    message.insert(QStringLiteral("content"), content);

    QJsonArray messages;
    messages.append(message);

    QJsonObject payload;
    payload.insert(QStringLiteral("model"), QString::fromLatin1(kOcrModel));
    payload.insert(QStringLiteral("messages"), messages);
    payload.insert(QStringLiteral("stream"), false);

    const QUrl endpoint(QString::fromLatin1(kBuiltinBaseUrl)
                        + QStringLiteral("/chat/completions"));

    QNetworkRequest request(endpoint);
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QByteArray("Bearer ") + QByteArray(kBuiltinApiKey));

    QNetworkReply *reply = network_->post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact));

    QTimer::singleShot(kOcrTimeoutMs, reply, [reply]() {
        if (reply->isRunning()) {
            qWarning() << "OCR request timed out";
            reply->abort();
        }
    });

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "OCR request failed:" << reply->errorString();
            emit ocrFailed(QStringLiteral("图片识别失败，请重试或手动导入"));
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(reply->readAll());
        const QJsonArray choices = document.object().value(QStringLiteral("choices")).toArray();
        const QString text = choices.isEmpty()
                                 ? QString()
                                 : choices.first()
                                       .toObject()
                                       .value(QStringLiteral("message"))
                                       .toObject()
                                       .value(QStringLiteral("content"))
                                       .toString();

        const QStringList names = parseNameLines(text);
        if (names.isEmpty()) {
            qWarning() << "OCR returned no name lines";
            emit ocrFailed(QStringLiteral("图片识别失败，请重试或手动导入"));
            return;
        }

        emit ocrRosterReady(names);
    });
}

QStringList AiManager::parseNameLines(const QString &content)
{
    QStringList names;
    const QStringList lines = content.split(QLatin1Char('\n'), Qt::SkipEmptyParts);

    for (QString line : lines) {
        line = line.trimmed();

        // 模型常把结果写成 “1. 张三” 或 “- 张三”，去掉列表前缀再进名单
        int prefix = 0;
        while (prefix < line.size() && line.at(prefix).isDigit()) {
            ++prefix;
        }
        if (prefix > 0 && prefix < line.size()) {
            const QChar separator = line.at(prefix);
            if (separator == QLatin1Char('.') || separator == QLatin1Char('、')
                || separator == QLatin1Char(')') || separator == QLatin1Char(' ')) {
                line = line.mid(prefix + 1).trimmed();
            }
        }
        while (!line.isEmpty()
               && (line.front() == QLatin1Char('-') || line.front() == QLatin1Char('*')
                   || line.front() == QLatin1Char('·'))) {
            line.remove(0, 1);
            line = line.trimmed();
        }

        if (!line.isEmpty() && !names.contains(line)) {
            names.append(line);
        }
    }

    return names;
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
