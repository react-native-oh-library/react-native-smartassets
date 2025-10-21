export namespace Smartassets {
  export const NAME = 'Smartassets' as const

  export interface Spec {
    initSmartAssets(): Promise<boolean>
    findAssetInBundles(assetName: string): Promise<string>
  }
}