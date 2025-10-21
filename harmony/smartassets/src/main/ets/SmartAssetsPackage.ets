import { RNPackage, UITurboModuleFactory } from "@rnoh/react-native-openharmony/ts";
import type { UITurboModule, UITurboModuleContext } from "@rnoh/react-native-openharmony/ts";
import { TM } from "./generated/ts";
import { SmartAssetsModule } from './SmartAssetsModule';

class SmartAssetsModulesFactory extends UITurboModuleFactory {
  createTurboModule(name: string): UITurboModule | null {
    if (name === TM.Smartassets.NAME) {
      return new SmartAssetsModule(this.ctx);
    }
    return null;
  }

  hasTurboModule(name: string): boolean {
    return name === TM.Smartassets.NAME;
  }
}

export class SmartAssetsPackage extends RNPackage {
  createTurboModulesFactory(ctx: UITurboModuleContext): UITurboModuleFactory {
    return new SmartAssetsModulesFactory(ctx);
  }
}