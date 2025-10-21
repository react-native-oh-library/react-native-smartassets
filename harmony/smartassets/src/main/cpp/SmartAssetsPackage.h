#pragma once

#include "RNOH/generated/BaseReactNativeSmartassetsPackage.h"

namespace rnoh {

class SmartAssetsPackage : public BaseReactNativeSmartassetsPackage {
    using Super = BaseReactNativeSmartassetsPackage;

public:
    SmartAssetsPackage(Package::Context ctx) : Super(ctx) {}
};

} // namespace rnoh
