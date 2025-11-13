import { NativeModules, Platform } from 'react-native';
import resolveAssetSource from 'react-native/Libraries/Image/resolveAssetSource';
import AssetSourceResolver from 'react-native/Libraries/Image/AssetSourceResolver';
import SmartassetsHarmony from './src/NativeSmartAssets';
const Smartassets = Platform.OS === 'harmony' ? SmartassetsHarmony : NativeModules.Smartassets;

let isTransformerInstalled = false;
let bundlePath = null;
let iOSRelateMainBundlePath = '';
let _sourceCodeScriptURL = null;
const defaultMainBundePath = ''; // Smartassets.DefaultMainBundlePath;

var _ = require('lodash');

function getSourceCodeScriptURL() {
	if (_sourceCodeScriptURL) {
		return _sourceCodeScriptURL;
	}
	let sourceCode = global.nativeExtensions && global.nativeExtensions.SourceCode;
	if (!sourceCode) {
		sourceCode = NativeModules && NativeModules.SourceCode;
	}
	_sourceCodeScriptURL = sourceCode ? sourceCode.scriptURL : null;
	return _sourceCodeScriptURL;
}

function findAssetInBundles(assetName) {
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
}

function setupAssetSourceResolverHook() {
	if (isTransformerInstalled || typeof resolveAssetSource?.setCustomSourceTransformer !== 'function') {
		return;
	}
	resolveAssetSource.setCustomSourceTransformer((resolver) => {
		if (typeof resolver?.defaultAsset !== 'function') {
			return resolver;
		}
		const result = resolver.defaultAsset();
		if (Platform.OS !== 'harmony' || !result || !result.__packager_asset || !resolver?.asset?.name || !resolver?.asset?.type) {
			return result;
		}
		try {
			const harmonyPath = findAssetInBundles(`${resolver.asset.name}.${resolver.asset.type}`);
			if (harmonyPath && typeof harmonyPath === 'string' && harmonyPath.length > 0) {
				return { ...result, uri: harmonyPath };
			}
		} catch (error) {
		}

		return result;
	});

	isTransformerInstalled = true;
}

const SmartAssets = {
	initSmartAssets() {
		var initialize = _.once(this.initSmartAssetsInner);
		initialize();
	},

	initSmartAssetsInner() {
		if (Platform.OS === 'harmony') {
				setupAssetSourceResolverHook();
		} else {
				let drawablePathInfos = [];
				Smartassets.travelDrawable(getSourceCodeScriptURL(), (retArray) => {
					drawablePathInfos = drawablePathInfos.concat(retArray);
				});
		
				AssetSourceResolver.prototype.defaultAsset=_.wrap(AssetSourceResolver.prototype.defaultAsset, function (func, ...args) {
					if (this.isLoadedFromServer()) {
						return this.assetServerURL();
					}
					if (Platform.OS === 'android') {
						if(this.isLoadedFromFileSystem()||bundlePath!=null){//begin assets ios begin drawable android
							if(bundlePath!=null){
								this.jsbundleUrl = bundlePath;
								}
							let resolvedAssetSource = this.drawableFolderInBundle();
							let resPath = resolvedAssetSource.uri;
							if(drawablePathInfos.includes(resPath)){//已经在bundle目录中有
								return resolvedAssetSource;
							}
							let isFileExist =  Smartassets.isFileExist(resPath);
							if(isFileExist===true){
								return resolvedAssetSource;
							}else {
								return this.resourceIdentifierWithoutScale();
							}
						}else {
							return this.resourceIdentifierWithoutScale();
						}
					} else {
						if(bundlePath!=null){
							this.jsbundleUrl = bundlePath;
						}
						let iOSAsset = this.scaledAssetURLNearBundle();
						let isFileExist =  Smartassets.isFileExist(iOSAsset.uri);
						if(isFileExist) {
							return iOSAsset;
						}else{
							let oriJsBundleUrl = 'file://'+defaultMainBundePath+'/'+iOSRelateMainBundlePath;
							iOSAsset.uri = iOSAsset.uri.replace(this.jsbundleUrl, oriJsBundleUrl);
							return iOSAsset;
						}
					}
				});
		}
	},

	setBundlePath(bundlePathNew) {
		bundlePath = bundlePathNew;
		if (Platform.OS === 'harmony' && Smartassets?.setBundlePath) {
			if (typeof bundlePathNew === 'string' && bundlePathNew.length > 0) {
				Smartassets.setBundlePath(bundlePathNew);
			} else {
				Smartassets.setBundlePath(null);
			}
		}
	},

	setiOSRelateMainBundlePath(relatePath) {
		iOSRelateMainBundlePath = relatePath;
	}
};

export { SmartAssets };
