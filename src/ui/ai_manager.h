#pragma once

#include <memory>

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

class QNetworkAccessManager;

class AiManager : public QObject
{
    Q_OBJECT

public:
    explicit AiManager(QObject *parent = nullptr);
    ~AiManager() override;

    Q_INVOKABLE void generateMockRoster();
    Q_INVOKABLE void generateAwardSpeech(const QString &winnerName);

    // 图片 OCR：固定使用内置配置，不读取用户在设置页填写的 Key 与地址
    Q_INVOKABLE void ocrFromImage(const QString &filePath);

    // 用户配置优先；留空的项回退到内置备用配置。
    void setApiConfig(const QString &apiKey, const QString &baseUrl, const QString &model);

signals:
    void mockRosterReady(const QVariantList &roster);
    void mockRosterFailed(const QString &message);
    void awardSpeechReady(const QString &speech);
    void awardSpeechFailed(const QString &message);
    void networkError(const QString &message);
    void ocrRosterReady(const QStringList &names);
    void ocrFailed(const QString &message);

private:
    enum class RequestKind { MockRoster, AwardSpeech };

    void requestCompletion(const QString &prompt, RequestKind kind);
    void emitFailure(RequestKind kind, const QString &message);
    [[nodiscard]] QString effectiveApiKey() const;
    [[nodiscard]] QString effectiveModel() const;
    [[nodiscard]] QString endpointUrl() const;
    [[nodiscard]] static QVariantList parseRoster(const QString &content);
    [[nodiscard]] static QStringList parseNameLines(const QString &content);
    [[nodiscard]] static QString cleanSpeech(const QString &content);

    std::unique_ptr<QNetworkAccessManager> network_;
    QString apiKey_;
    QString baseUrl_;
    QString model_;
};
