#pragma once

#include <memory>

#include <QObject>
#include <QString>
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

    // 本地配置优先；为空时回退到编译期注入的密钥与官方地址。
    void setApiConfig(const QString &apiKey, const QString &baseUrl);

signals:
    void mockRosterReady(const QVariantList &roster);
    void mockRosterFailed(const QString &message);
    void awardSpeechReady(const QString &speech);
    void awardSpeechFailed(const QString &message);
    void networkError(const QString &message);

private:
    enum class RequestKind { MockRoster, AwardSpeech };

    void requestCompletion(const QString &prompt, RequestKind kind);
    void emitFailure(RequestKind kind, const QString &message);
    [[nodiscard]] QString effectiveApiKey() const;
    [[nodiscard]] QString endpointUrl() const;
    [[nodiscard]] static QVariantList parseRoster(const QString &content);
    [[nodiscard]] static QString cleanSpeech(const QString &content);

    std::unique_ptr<QNetworkAccessManager> network_;
    QString apiKey_;
    QString baseUrl_;
};
