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
#include <QRegularExpression>
#include <QTimer>
#include <QUrl>
#include <QVariantMap>

namespace {

constexpr int kRequestTimeoutMs = 15000;
// 图片上传比纯文本慢得多，OCR 每一步单独放宽超时
constexpr int kOcrTimeoutMs = 60000;

// 图片 OCR 使用独立的专用密钥与模型（内置通道），
// 与设置页里用户自己的文本 AI 配置完全隔离。
constexpr const char *kOcrApiKey = "sk-2ff8932b775b4adf946ee873af51939d";
constexpr const char *kOcrBaseUrl = "https://api.deepseek.com";
constexpr const char *kOcrModel = "deepseek-flash";

// 文本任务的接口地址与模型只有默认值，密钥必须由用户在设置页提供
constexpr const char *kTextDefaultBaseUrl = "https://api.deepseek.com";
constexpr const char *kTextDefaultModel = "deepseek-flash";

QString rosterPrompt()
{
    return QStringLiteral("请生成 15 个中国风的学生姓名和学号，严格按 JSON 数组格式返回："
                          "[{\"name\":\"苏婉宁\",\"id\":\"001\"}]，不要包含其他任何废话");
}

QString categoryPrompt()
{
    return QStringLiteral("这是一张表格或照片。请分析图片中包含哪些类别的数据（如：姓名、年龄、"
                          "爱好、学号）。请只回答你认为最适合用于抽奖的一类数据的名称"
                          "（例如回答：姓名）。");
}

QString extractionPrompt(const QString &category, bool reordered)
{
    if (reordered) {
        return QStringLiteral("请再次提取图片中所有的【%1】。要求：每行一个，不要包含其他多余文字，"
                              "也不要添加编号。")
            .arg(category);
    }

    return QStringLiteral("请提取图片中所有的【%1】。要求：每行一个，不要包含其他多余文字。")
        .arg(category);
}

QString verificationPrompt(const QString &category)
{
    return QStringLiteral("请再次仔细识别图片，提取所有的【%1】，核对总共有多少个。"
                          "每行一个，不要包含其他多余文字。")
        .arg(category);
}

QString scoresPrompt()
{
    return QStringLiteral("请识别这张成绩单或成绩表格图片，提取所有学生的姓名与对应分数。"
                          "严格按 JSON 数组返回：[{\"name\":\"张三\",\"score\":95}]，"
                          "分数只写数字，不要带单位，不要包含其他任何文字");
}

QString functionPrompt(const QString &description)
{
    return QStringLiteral("你是数学绘图助手。用户想画：%1。请返回可以直接绘制的函数表达式，"
                          "严格遵守："
                          "1. 只输出表达式本身，不要解释，不要 Markdown 代码块；"
                          "2. 直角坐标写成 y = ...（变量用 x）；"
                          "3. 参数方程写成 x = ... , y = ...（变量用 t）；"
                          "4. 隐式方程写成 F(x, y) = G(x, y)；"
                          "5. 只使用 x y t 这几个变量，支持 sin cos tan log ln sqrt abs exp 与 ^ 乘方。")
        .arg(description);
}

// 模型常把类别写成“类别：姓名”“姓名（Name）”或带引号，取第一个有效词作为类别
QString cleanCategory(const QString &content)
{
    QString text = content.trimmed();
    if (text.isEmpty()) {
        return QString();
    }

    const QStringList lines = text.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    if (!lines.isEmpty()) {
        text = lines.first().trimmed();
    }

    const int colon = text.indexOf(QChar(u'：'));
    const int asciiColon = text.indexOf(QLatin1Char(':'));
    const int split = colon >= 0 ? colon : asciiColon;
    if (split >= 0) {
        text = text.mid(split + 1).trimmed();
    }

    for (int i = 0; i < text.size(); ++i) {
        const QChar ch = text.at(i);
        if (ch == QChar(u'（') || ch == QLatin1Char('(') || ch == QLatin1Char('[')
            || ch == QChar(u'，') || ch == QChar(u'。') || ch == QLatin1Char('.')
            || ch == QChar(u'；') || ch == QLatin1Char(';')) {
            text = text.left(i).trimmed();
            break;
        }
    }

    const QString wrappers = QStringLiteral("\"'“”‘’`「」《》【】*# ");
    while (!text.isEmpty() && wrappers.contains(text.front())) {
        text.remove(0, 1);
    }
    while (!text.isEmpty() && wrappers.contains(text.back())) {
        text.chop(1);
    }

    // 模型偶尔把答案写成一整句话，命中已知类别时直接采用该词
    static const QStringList knownCategories{QStringLiteral("姓名"), QStringLiteral("名字"),
                                             QStringLiteral("学号"), QStringLiteral("年龄"),
                                             QStringLiteral("爱好"), QStringLiteral("班级"),
                                             QStringLiteral("编号"), QStringLiteral("昵称")};
    for (const QString &category : knownCategories) {
        if (text.contains(category)) {
            return category;
        }
    }

    return text.left(12).trimmed();
}

// 投票：两份一致直接采用；三份都不同时取元素最多的那份（并列取第一份）
QStringList pickBestResult(const QStringList &first, const QStringList &second,
                           const QStringList &third)
{
    if (!first.isEmpty() && first == second) {
        return first;
    }
    if (!first.isEmpty() && first == third) {
        return first;
    }
    if (!second.isEmpty() && second == third) {
        return second;
    }

    const QList<QStringList> candidates{first, second, third};
    QStringList best;
    for (const QStringList &candidate : candidates) {
        if (candidate.size() > best.size()) {
            best = candidate;
        }
    }
    return best;
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

QString AiManager::effectiveModel() const
{
    return model_.isEmpty() ? QString::fromLatin1(kTextDefaultModel) : model_;
}

QString AiManager::endpointUrl() const
{
    QString base = baseUrl_.trimmed();
    if (base.isEmpty()) {
        base = QString::fromLatin1(kTextDefaultBaseUrl);
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

void AiManager::postChat(const QJsonObject &payload, const QString &key, const QString &endpoint,
                         int timeoutMs, ChatHandler handler)
{
    QNetworkRequest request{QUrl(endpoint)};
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", "Bearer " + key.toUtf8());

    QNetworkReply *reply =
        network_->post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact));

    // 硬性超时：超时后中止请求，finished 中统一回调失败
    QTimer::singleShot(timeoutMs, reply, [reply]() {
        if (reply->isRunning()) {
            qWarning() << "AI request timed out";
            reply->abort();
        }
    });

    connect(reply, &QNetworkReply::finished, this, [reply, handler = std::move(handler)]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "AI request failed:" << reply->errorString();
            const bool timedOut = reply->error() == QNetworkReply::OperationCanceledError;
            handler(false, QString(),
                    timedOut ? QStringLiteral("网络拥堵，请稍后再试")
                             : QStringLiteral("网络异常，请稍后再试"));
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(reply->readAll());
        const QJsonArray choices = document.object().value(QStringLiteral("choices")).toArray();
        if (choices.isEmpty()) {
            handler(false, QString(), QStringLiteral("AI 返回内容为空"));
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
            handler(false, QString(), QStringLiteral("AI 返回内容为空"));
            return;
        }

        handler(true, content, QString());
    });
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

void AiManager::generateFunction(const QString &prompt)
{
    const QString description = prompt.trimmed();
    if (description.isEmpty()) {
        emit functionFailed(QStringLiteral("先描述一下想画的图形"));
        return;
    }

    requestCompletion(functionPrompt(description), RequestKind::FunctionExpression);
}

void AiManager::requestCompletion(const QString &prompt, RequestKind kind)
{
    const QString key = apiKey_.trimmed();
    if (key.isEmpty()) {
        // 文本任务绝不回退内置密钥，也不静默失败：通知界面引导用户去设置页
        emit textAiKeyMissing();
        emitFailure(kind, QStringLiteral("请前往设置配置 API Key"));
        return;
    }

    const QString endpoint = endpointUrl();
    const QUrl url(endpoint);
    if (!url.isValid() || url.host().isEmpty()) {
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

    postChat(payload, key, endpoint, kRequestTimeoutMs,
             [this, kind](bool ok, const QString &content, const QString &error) {
                 if (!ok) {
                     if (kind == RequestKind::FunctionExpression) {
                         emit functionFailed(error);
                     }
                     emit networkError(error);
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

                 if (kind == RequestKind::FunctionExpression) {
                     const QString expression = cleanExpression(content);
                     if (expression.isEmpty()) {
                         emit functionFailed(QStringLiteral("AI 返回的表达式无法解析"));
                         return;
                     }
                     emit functionGenerated(expression);
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

void AiManager::postOcrChat(const QString &prompt, int timeoutMs, ChatHandler handler)
{
    QJsonObject imageUrl;
    imageUrl.insert(QStringLiteral("url"), ocrImageUrl_);
    // high 等价于原图，保留表格里的小字
    imageUrl.insert(QStringLiteral("detail"), QStringLiteral("high"));

    QJsonObject imagePart;
    imagePart.insert(QStringLiteral("type"), QStringLiteral("image_url"));
    imagePart.insert(QStringLiteral("image_url"), imageUrl);

    QJsonObject textPart;
    textPart.insert(QStringLiteral("type"), QStringLiteral("text"));
    textPart.insert(QStringLiteral("text"), prompt);

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
    // OCR 只需要确定性输出，关闭思考模式可明显降低延迟
    QJsonObject thinking;
    thinking.insert(QStringLiteral("type"), QStringLiteral("disabled"));
    payload.insert(QStringLiteral("thinking"), thinking);
    payload.insert(QStringLiteral("stream"), false);

    postChat(payload, QString::fromLatin1(kOcrApiKey),
             QString::fromLatin1(kOcrBaseUrl) + QStringLiteral("/chat/completions"), timeoutMs,
             std::move(handler));
}

bool AiManager::prepareOcrImage(const QString &filePath)
{
    ocrImageUrl_.clear();

    QFile file(filePath);
    if (filePath.isEmpty() || !file.open(QIODevice::ReadOnly)) {
        qWarning() << "cannot open image for OCR:" << filePath;
        return false;
    }

    const QByteArray raw = file.readAll();
    file.close();
    if (raw.isEmpty()) {
        qWarning() << "empty image for OCR:" << filePath;
        return false;
    }

    const QString suffix = QFileInfo(filePath).suffix().toLower();
    const QString mime = suffix == QStringLiteral("png") ? QStringLiteral("image/png")
                                                        : QStringLiteral("image/jpeg");
    ocrImageUrl_ = QStringLiteral("data:%1;base64,%2")
                       .arg(mime, QString::fromLatin1(raw.toBase64()));
    return true;
}

void AiManager::ocrFromImage(const QString &filePath)
{
    ocrCategory_.clear();
    ocrFirstPass_.clear();
    ocrSecondPass_.clear();

    if (!prepareOcrImage(filePath)) {
        failOcr(QStringLiteral("图片识别失败，请重试或手动导入"));
        return;
    }

    emit ocrProgress(QStringLiteral("AI 正在分析数据结构..."));
    requestOcrCategory();
}

void AiManager::ocrScoresFromImage(const QString &filePath)
{
    if (!prepareOcrImage(filePath)) {
        failOcr(QStringLiteral("图片识别失败，请重试或手动导入"));
        return;
    }

    emit ocrProgress(QStringLiteral("AI 正在读取成绩单..."));
    postOcrChat(scoresPrompt(), kOcrTimeoutMs,
                [this](bool ok, const QString &content, const QString &error) {
                    if (!ok) {
                        failOcr(error);
                        return;
                    }

                    const QVariantList entries = parseScores(content);
                    if (entries.isEmpty()) {
                        failOcr(QStringLiteral("没能从成绩单里识别出姓名与分数"));
                        return;
                    }

                    emit ocrScoresReady(entries);
                });
}

void AiManager::requestOcrCategory()
{
    postOcrChat(categoryPrompt(), kOcrTimeoutMs,
                [this](bool ok, const QString &content, const QString &error) {
                    if (!ok) {
                        failOcr(error);
                        return;
                    }

                    ocrCategory_ = cleanCategory(content);
                    if (ocrCategory_.isEmpty()) {
                        ocrCategory_ = QStringLiteral("姓名");
                    }

                    emit ocrProgress(QStringLiteral("正在提取名单数据..."));
                    requestOcrExtraction();
                });
}

void AiManager::requestOcrExtraction()
{
    postOcrChat(extractionPrompt(ocrCategory_, false), kOcrTimeoutMs,
                [this](bool ok, const QString &content, const QString &error) {
                    if (!ok) {
                        failOcr(error);
                        return;
                    }

                    ocrFirstPass_ = parseNameLines(content);
                    if (ocrFirstPass_.isEmpty()) {
                        failOcr(QStringLiteral("图片识别失败，请重试或手动导入"));
                        return;
                    }

                    emit ocrProgress(QStringLiteral("正在二次校验提取结果..."));
                    postOcrChat(extractionPrompt(ocrCategory_, true), kOcrTimeoutMs,
                                [this](bool verified, const QString &secondContent,
                                       const QString &) {
                                    // 第二遍失败时直接采用第一遍的结果，不再要求用户重来
                                    if (!verified) {
                                        emit ocrRosterReady(ocrFirstPass_);
                                        return;
                                    }

                                    ocrSecondPass_ = parseNameLines(secondContent);
                                    if (ocrSecondPass_ == ocrFirstPass_) {
                                        emit ocrRosterReady(ocrFirstPass_);
                                        return;
                                    }

                                    requestOcrVerification();
                                });
                });
}

void AiManager::requestOcrVerification()
{
    postOcrChat(verificationPrompt(ocrCategory_), kOcrTimeoutMs,
                [this](bool ok, const QString &content, const QString &) {
                    QStringList third;
                    if (ok) {
                        third = parseNameLines(content);
                    }

                    const QStringList best = pickBestResult(ocrFirstPass_, ocrSecondPass_, third);
                    if (best.isEmpty()) {
                        failOcr(QStringLiteral("图片识别失败，请重试或手动导入"));
                        return;
                    }

                    emit ocrRosterReady(best);
                });
}

void AiManager::failOcr(const QString &message)
{
    qWarning() << "OCR failed:" << message;
    emit ocrFailed(message);
}

QStringList AiManager::parseNameLines(const QString &content)
{
    // 校验轮次的返回值里常带“共 42 个”这类汇总行，不能当成人名；
    // 纯数字不算汇总，避免把“学号”类别整列误删
    static const QRegularExpression summaryPattern(
        QStringLiteral("^(?:共|共有|总共|合计|一共|总计)\\s*\\d+\\s*(?:个|人|名|条|行)?"
                       "(?:姓名|名字)?[。.]?$"));
    static const QRegularExpression countPattern(
        QStringLiteral("^\\d+\\s*(?:个|人|名|条|行)(?:姓名|名字)?[。.]?$"));

    QStringList names;
    const QStringList lines = content.split(QLatin1Char('\n'), Qt::SkipEmptyParts);

    for (QString line : lines) {
        line = line.trimmed();

        if (summaryPattern.match(line).hasMatch() || countPattern.match(line).hasMatch()) {
            continue;
        }

        // 模型常把结果写成 “1. 张三” 或 “- 张三”，去掉列表前缀再进名单
        int prefix = 0;
        while (prefix < line.size() && line.at(prefix).isDigit()) {
            ++prefix;
        }
        if (prefix > 0 && prefix < line.size()) {
            const QChar separator = line.at(prefix);
            if (separator == QLatin1Char('.') || separator == QChar(u'、')
                || separator == QLatin1Char(')') || separator == QLatin1Char(' ')) {
                line = line.mid(prefix + 1).trimmed();
            }
        }
        while (!line.isEmpty()
               && (line.front() == QLatin1Char('-') || line.front() == QLatin1Char('*')
                   || line.front() == QChar(u'·'))) {
            line.remove(0, 1);
            line = line.trimmed();
        }

        if (!line.isEmpty() && !names.contains(line)) {
            names.append(line);
        }
    }

    return names;
}

QVariantList AiManager::parseScores(const QString &content)
{
    const int start = content.indexOf(QLatin1Char('['));
    const int end = content.lastIndexOf(QLatin1Char(']'));
    if (start < 0 || end <= start) {
        return {};
    }

    const QJsonDocument document =
        QJsonDocument::fromJson(content.mid(start, end - start + 1).toUtf8());
    if (!document.isArray()) {
        return {};
    }

    QVariantList entries;
    for (const QJsonValue &value : document.array()) {
        const QJsonObject entry = value.toObject();
        const QString name = entry.value(QStringLiteral("name")).toString().trimmed();

        // 模型有时把分数写成 "95 分" 或字符串，统一取第一个数字
        QString rawScore = entry.value(QStringLiteral("score")).toVariant().toString();
        static const QRegularExpression numberPattern(QStringLiteral("-?\\d+(?:\\.\\d+)?"));
        const QRegularExpressionMatch match = numberPattern.match(rawScore);
        if (name.isEmpty() || !match.hasMatch()) {
            continue;
        }

        bool ok = false;
        const double score = match.captured(0).toDouble(&ok);
        if (!ok) {
            continue;
        }

        QVariantMap participant;
        participant.insert(QStringLiteral("name"), name);
        participant.insert(QStringLiteral("score"), score);
        entries.append(participant);
    }
    return entries;
}

QString AiManager::cleanExpression(const QString &content)
{
    QStringList lines;
    for (QString line : content.split(QLatin1Char('\n'))) {
        line = line.trimmed();
        if (line.isEmpty() || line.startsWith(QStringLiteral("```"))) {
            continue;
        }

        // “表达式：y = x^2”这类前缀不属于表达式本身
        const int separator = line.indexOf(QChar(u'：'));
        if (separator > 0 && separator <= 6) {
            line = line.mid(separator + 1).trimmed();
        }
        if (!line.isEmpty()) {
            lines.append(line);
        }
    }

    if (lines.isEmpty()) {
        return QString();
    }

    // 参数方程常被写成两行，合并成一行交给 QML 解析
    return lines.join(QStringLiteral(", "));
}

void AiManager::emitFailure(RequestKind kind, const QString &message)
{
    if (kind == RequestKind::MockRoster) {
        emit mockRosterFailed(message);
    } else if (kind == RequestKind::FunctionExpression) {
        emit functionFailed(message);
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
