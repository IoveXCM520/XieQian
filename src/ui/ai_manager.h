#pragma once

#include <functional>
#include <memory>

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

class QJsonObject;
class QNetworkAccessManager;

class AiManager : public QObject
{
    Q_OBJECT

public:
    explicit AiManager(QObject *parent = nullptr);
    ~AiManager() override;

    Q_INVOKABLE void generateMockRoster();
    Q_INVOKABLE void generateAwardSpeech(const QString &winnerName);

    // 图片 OCR：内置专用密钥，多轮提取 + 投票校验
    Q_INVOKABLE void ocrFromImage(const QString &filePath);

    // 成绩单 OCR：返回 [{name, score}]，用于开发者页的 AI 调权
    Q_INVOKABLE void ocrScoresFromImage(const QString &filePath);

    // 自然语言转函数表达式，结果可直接填进函数图像页
    Q_INVOKABLE void generateFunction(const QString &prompt);

    // 用户配置优先；留空的项回退到内置备用配置。
    void setApiConfig(const QString &apiKey, const QString &baseUrl, const QString &model);

signals:
    void mockRosterReady(const QVariantList &roster);
    void mockRosterFailed(const QString &message);
    void awardSpeechReady(const QString &speech);
    void awardSpeechFailed(const QString &message);
    void networkError(const QString &message);
    void ocrRosterReady(const QStringList &names);
    void ocrScoresReady(const QVariantList &entries);
    void ocrFailed(const QString &message);
    void ocrProgress(const QString &message);
    void functionGenerated(const QString &expression);
    void functionFailed(const QString &message);

private:
    enum class RequestKind { MockRoster, AwardSpeech, FunctionExpression };

    using ChatHandler = std::function<void(bool ok, const QString &content, const QString &error)>;

    void requestCompletion(const QString &prompt, RequestKind kind);
    void emitFailure(RequestKind kind, const QString &message);
    [[nodiscard]] QString effectiveApiKey() const;
    [[nodiscard]] QString effectiveModel() const;
    [[nodiscard]] QString endpointUrl() const;
    [[nodiscard]] static QVariantList parseRoster(const QString &content);
    [[nodiscard]] static QStringList parseNameLines(const QString &content);
    [[nodiscard]] static QVariantList parseScores(const QString &content);
    [[nodiscard]] static QString cleanExpression(const QString &content);
    [[nodiscard]] static QString cleanSpeech(const QString &content);

    void postChat(const QJsonObject &payload, const QString &key, const QString &endpoint,
                  int timeoutMs, ChatHandler handler);
    void postOcrChat(const QString &prompt, int timeoutMs, ChatHandler handler);
    void requestOcrCategory();
    void requestOcrExtraction();
    void requestOcrVerification();
    void failOcr(const QString &message);
    [[nodiscard]] bool prepareOcrImage(const QString &filePath);

    std::unique_ptr<QNetworkAccessManager> network_;
    QString apiKey_;
    QString baseUrl_;
    QString model_;

    QString ocrImageUrl_;
    QString ocrCategory_;
    QStringList ocrFirstPass_;
    QStringList ocrSecondPass_;
};
