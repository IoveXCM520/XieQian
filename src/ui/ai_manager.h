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

signals:
    void mockRosterReady(const QVariantList &roster);
    void mockRosterFailed(const QString &message);
    void awardSpeechReady(const QString &speech);
    void awardSpeechFailed(const QString &message);

private:
    enum class RequestKind { MockRoster, AwardSpeech };

    void requestCompletion(const QString &prompt, RequestKind kind);
    void emitFailure(RequestKind kind, const QString &message);
    [[nodiscard]] static QVariantList parseRoster(const QString &content);
    [[nodiscard]] static QString cleanSpeech(const QString &content);

    std::unique_ptr<QNetworkAccessManager> network_;
};
