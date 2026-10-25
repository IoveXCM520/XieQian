#include "backend_bridge.h"

#include <random>
#include <utility>

namespace {

std::mt19937_64 seededGenerator()
{
    std::random_device device;
    std::seed_seq seed{device(), device(), device(), device()};
    return std::mt19937_64(seed);
}

}  // namespace

BackendBridge::BackendBridge(QObject *parent)
    : QObject(parent),
      roster_(std::make_unique<xieqian::core::Roster>()),
      drawEngine_(std::make_unique<xieqian::core::DrawEngine>(seededGenerator()))
{
    for (const char *name : {"苏婉宁", "林砚舟", "顾南乔", "白清让", "沈亦初", "温言澈", "陆时衍"}) {
        roster_->add(name);
    }
}

QString BackendBridge::drawWinner()
{
    const auto winner = drawEngine_->drawOne(*roster_);
    if (!winner.has_value()) {
        return QStringLiteral("无可用名单");
    }
    return QString::fromStdString(*winner);
}

QVariantList BackendBridge::drawWinners(int count)
{
    QVariantList winners;
    if (count <= 0) {
        return winners;
    }

    for (const std::string &name : drawEngine_->drawMultiple(*roster_, static_cast<std::size_t>(count))) {
        winners.append(QString::fromStdString(name));
    }
    return winners;
}
