import { RNPackage, UITurboModuleFactory } from "@rnoh/react-native-openharmony/ts";
import type { UITurboModule, UITurboModuleContext } from "@rnoh/react-native-openharmony/ts";
import { TM } from "./generated/ts";
import { SmartAssetsAnyModule } from './SmartAssetsModule';
import { AnyThreadTurboModule, AnyThreadTurboModuleContext, RNOHPackage } from "@rnoh/react-native-openharmony";

export default class SmartAssetsPackage extends RNOHPackage {
  // getUITurboModuleFactoryByNameMap(): Map<string, (ctx: UITurboModuleContext) => UITurboModule | null> {
	// 	return new Map<string, ((ctx: UITurboModuleContext) => UITurboModule)>()
  //     .set(TM.Smartassets.NAME, (ctx) => new SmartAssetsModule(ctx));
	// }
  // createEagerUITurboModuleByNameMap(ctx: UITurboModuleContext): Promise<Map<string, UITurboModule>> {
  //   const smartAssetsModule = new SmartAssetsModule(ctx)
  //   return Promise.resolve(
  //     new Map<string, UITurboModule>()
  //       .set(TM.Smartassets.NAME, smartAssetsModule)
  //   )
  // }

  getAnyThreadTurboModuleFactoryByNameMap(): Map<string, (ctx: AnyThreadTurboModuleContext) => AnyThreadTurboModule | null> {
    return new Map<string, ((ctx: AnyThreadTurboModuleContext) => AnyThreadTurboModule)>()
      .set(TM.Smartassets.NAME, (ctx) => new SmartAssetsAnyModule(ctx))
  }

  createEagerAnyThreadTurboModuleByNameMap(ctx: AnyThreadTurboModuleContext): Promise<Map<string, AnyThreadTurboModule>> {
    const smartAssetsModule = new SmartAssetsAnyModule(ctx)
    return Promise.resolve(
      new Map<string, AnyThreadTurboModule>()
        .set(TM.Smartassets.NAME, smartAssetsModule)
    )
  }
}