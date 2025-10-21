import { NativeModules, Platform } from 'react-native';
import AssetSourceResolver from 'react-native/Libraries/Image/AssetSourceResolver';
import SmartassetsHarmony from './src/NativeSmartAssets';

const Smartassets = Platform.OS === 'harmony' ? SmartassetsHarmony : NativeModules.Smartassets;

let isInitialized = false;

const SmartAssets = {
	initSmartAssets() {
		
		if (isInitialized) {
			return Promise.resolve(true);
		}
		
		this.initSmartAssetsInner();
		isInitialized = true;
		return Promise.resolve(true);
	},

	findAssetInBundles(assetName) {
		
		if (Platform.OS === 'harmony') {
			if (Smartassets?.findAssetInBundles) {
				const result = Smartassets.findAssetInBundles(assetName);
				return result;
			} else {
				return '';
			}
		} else {
			return '';
		}
	},
	
	initSmartAssetsInner() {
		if (Platform.OS === 'harmony') {
			this.setupAssetSourceResolverHook();
		}
	},

	setupAssetSourceResolverHook() {

		const originalDefaultAsset = AssetSourceResolver.prototype.defaultAsset;
		
		AssetSourceResolver.prototype.defaultAsset = function(...args) {
			if (Platform.OS === 'harmony' && this.asset?.name && this.asset?.type) {
				const fileName = `${this.asset.name}.${this.asset.type}`;
				
				try {
					const harmonyPath = SmartAssets.findAssetInBundles(fileName);
					if (harmonyPath && typeof harmonyPath === 'string' && harmonyPath.length > 0) {
						return { uri: harmonyPath };
					}
				} catch (error) {
				}
			}
			
			return originalDefaultAsset.apply(this, args);
		};
	}
};

export {SmartAssets};
