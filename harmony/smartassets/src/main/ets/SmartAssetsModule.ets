import { UITurboModule } from '@rnoh/react-native-openharmony/ts';
import { TM } from "./generated/ts";
import resourceManager from '@ohos.resourceManager';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import fileIo from '@ohos.fileio';
import { fileUri } from '@kit.CoreFileKit';

// 沙箱路径接口
interface SandboxPaths {
  bundleCodeDir: string;
  cacheDir: string;
  filesDir: string;
  preferencesDir: string;
  tempDir: string;
  databaseDir: string;
  distributedFilesDir: string;
  resourceDir: string;
}

// 鸿蒙平台接口 - 只保留核心方法
interface HarmonySpec {
  initSmartAssets(): Promise<boolean>
  findAssetInBundles(assetName: string): string
}

export class SmartAssetsModule extends UITurboModule implements HarmonySpec {
  // 初始化智能资源
  async initSmartAssets(): Promise<boolean> {
    return true;
  }

  findAssetInBundles(assetName: string): string {
    
    // 参数验证
    if (!assetName || typeof assetName !== 'string' || assetName.trim().length === 0) {
      return '';
    }
    
    try {
      const context = getContext(this) as Context;
      if (!context) {
        return '';
      }
      
      const resourceManager = context.resourceManager;
      if (!resourceManager) {
        return '';
      }

      // 第一步：先在本地 rawfile 中查找
      const localResult = this.discoverAndSearch(resourceManager, '', assetName);
      
      if (localResult) {
        return localResult;
      }

      // 第二步：本地没找到，去沙箱路径中查找
      const sandboxResult = this.searchInSandboxPaths(context, assetName);
      
      if (sandboxResult) {
        return sandboxResult;
      }

      return '';
      
    } catch (error) {
      return '';
    }
  }

  // 在沙箱路径中搜索图片
  private searchInSandboxPaths(context: Context, assetName: string): string {
    
    try {
      // 获取所有沙箱路径
      const sandboxPaths: SandboxPaths = {
        bundleCodeDir: context.bundleCodeDir,
        cacheDir: context.cacheDir,
        filesDir: context.filesDir,
        preferencesDir: context.preferencesDir,
        tempDir: context.tempDir,
        databaseDir: context.databaseDir,
        distributedFilesDir: context.distributedFilesDir,
        resourceDir: context.resourceDir
      };
      
      
      // 循环遍历每个沙箱路径
      for (const entry of Object.entries(sandboxPaths) as [string, string][]) {
        const pathName: string = entry[0];
        const pathValue: string = entry[1];
        
        if (pathValue && pathValue.length > 0) {
          
          // 在每个沙箱路径中搜索图片
          const result = this.searchInSandboxDirectory(pathValue, assetName);
          if (result) {
            return result;
          }
        }
      }
      
      return '';
      
    } catch (error) {
      return '';
    }
  }

  // 在指定沙箱目录中搜索图片
  private searchInSandboxDirectory(directoryPath: string, assetName: string): string {
    try {
      
      // 使用文件系统 API 递归搜索目录
      const result = this.recursiveSearchInDirectory(directoryPath, assetName);
      
      if (result) {
        let uri = fileUri.getUriFromPath(result);
        return uri;
      }
      
      return '';
      
    } catch (error) {
      return '';
    }
  }

  // 递归搜索目录中的文件
  private recursiveSearchInDirectory(directoryPath: string, assetName: string): string {
    try {
      
      // 检查目录是否存在
      if (!this.isDirectoryExists(directoryPath)) {
        return '';
      }
      
      // 读取目录内容
      const files: string[] = fs.listFileSync(directoryPath, { recursion: false });
      
      // 遍历目录中的每个文件/目录
      for (const file of files) {
        const fullPath = `${directoryPath}/${file}`;
        
        // 检查是否是目录
        if (this.isDirectory(fullPath)) {
          // 递归搜索子目录
          const result = this.recursiveSearchInDirectory(fullPath, assetName);
          if (result) {
            return result;
          }
        } else {
          // 检查是否是匹配的图片文件
          if (this.isImageFile(file) && this.isFileNameMatch(file, assetName)) {
            // 沙箱中的文件使用 file:// 协议
            const uri = `${fullPath}`;
            return uri;
          }
        }
      }
      
      return '';
      
    } catch (error) {
      return '';
    }
  }

  // 检查目录是否存在
  private isDirectoryExists(path: string): boolean {
    try {
      const stat = fs.statSync(path);
      return stat.isDirectory();
    } catch (error) {
      return false;
    }
  }

  // 检查文件是否存在
  private isFileExists(filePath: string): boolean {
    try {
      const stat = fs.statSync(filePath);
      return stat.isFile();
    } catch (error) {
      return false;
    }
  }

  // 动态发现并搜索
  private discoverAndSearch(resourceManager: resourceManager.ResourceManager, rootPath: string,
    assetName: string): string {

    // 先检查根目录本身是否有匹配的文件
    const rootResult = this.searchInDirectory(resourceManager, rootPath, assetName);
    if (rootResult) {
      return rootResult;
    }

    // 递归发现所有子目录并搜索
    return this.recursiveDiscoverAndSearch(resourceManager, rootPath, assetName);
  }

  // 在指定目录中搜索文件
  private searchInDirectory(resourceManager: resourceManager.ResourceManager, directoryPath: string,
    assetName: string): string {
    try {
      const fileList: Array<string> = resourceManager.getRawFileListSync(directoryPath);
      
      for (const fileName of fileList) {
        if (this.isImageFile(fileName) && this.isFileNameMatch(fileName, assetName)) {
          const fullPath = `${directoryPath}/${fileName}`;
          const uri = `resource://RAWFILE/${fullPath}`;
          return uri;
        }
      }
      
      return '';
    } catch (error) {
      const code = (error as BusinessError).code;
      const message = (error as BusinessError).message;
      return '';
    }
  }

  // 递归发现所有子目录并搜索
  private recursiveDiscoverAndSearch(resourceManager: resourceManager.ResourceManager, currentPath: string,
    assetName: string): string {
    try {
      // 获取当前目录的所有内容
      const fileList: Array<string> = resourceManager.getRawFileListSync(currentPath);
      
      // 检查当前目录中的文件
      for (const fileName of fileList) {
        if (this.isImageFile(fileName) && this.isFileNameMatch(fileName, assetName)) {
          const fullPath = `${currentPath}/${fileName}`;
          const uri = `resource://RAWFILE/${fullPath}`;
          return uri;
        }
      }
      
      // 递归搜索所有子目录
      for (const fileName of fileList) {
        if (this.isDirectory(fileName) && !this.shouldSkipDirectory(fileName)) {
          const subDirPath = currentPath ? `${currentPath}/${fileName}` : fileName;
          const result = this.recursiveDiscoverAndSearch(resourceManager, subDirPath, assetName);
          if (result) {
            return result;
          }
        }
      }
      
      return '';
    } catch (error) {
      const code = (error as BusinessError).code;
      const message = (error as BusinessError).message;
      return '';
    }
  }

  // 判断是否为图片文件
  private isImageFile(fileName: string): boolean {
    const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.bmp', '.tiff'];
    return imageExtensions.some(ext => fileName.toLowerCase().endsWith(ext));
  }

  // 智能文件名匹配
  private isFileNameMatch(fileName: string, targetName: string): boolean {
    // 精确匹配
    if (fileName === targetName) {
      return true;
    }

    // 去除扩展名匹配
    const fileNameWithoutExt = this.removeFileExtension(fileName);
    const targetNameWithoutExt = this.removeFileExtension(targetName);

    if (fileNameWithoutExt === targetNameWithoutExt) {
      return true;
    }

    // 大小写不敏感匹配
    if (fileName.toLowerCase() === targetName.toLowerCase()) {
      return true;
    }

    // 去除扩展名的大小写不敏感匹配
    if (fileNameWithoutExt.toLowerCase() === targetNameWithoutExt.toLowerCase()) {
      return true;
    }

    return false;
  }

  // 移除文件扩展名
  private removeFileExtension(fileName: string): string {
    const lastDotIndex = fileName.lastIndexOf('.');
    return lastDotIndex > 0 ? fileName.substring(0, lastDotIndex) : fileName;
  }

  // 判断是否为目录
  private isDirectory(fileName: string): boolean {
    const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.bmp', '.tiff'];
    const hasImageExtension = imageExtensions.some(ext => fileName.toLowerCase().endsWith(ext));

    // 如果有图片扩展名，肯定是文件
    if (hasImageExtension) {
      return false;
    }

    // 如果包含点号，可能是文件（除非是隐藏文件）
    if (fileName.includes('.')) {
      // 检查是否是常见的文件扩展名
      const commonFileExtensions = ['.js', '.json', '.txt', '.md', '.bundle', '.har'];
      const hasCommonExtension = commonFileExtensions.some(ext => fileName.toLowerCase().endsWith(ext));
      return !hasCommonExtension;
    }

    // 不包含点号的，很可能是目录
    return true;
  }

  // 判断是否应该跳过某个目录
  private shouldSkipDirectory(dirName: string): boolean {
    const skipDirectories = [
      'node_modules',
      '.git',
      '.vscode',
      '.idea',
      'build',
      'dist',
      'coverage',
      '.nyc_output',
      'temp',
      'tmp'
    ];

    return skipDirectories.includes(dirName.toLowerCase());
  }

  
}