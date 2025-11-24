import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../config/constants.dart';

/// 文件管理工具类
class FileUtil {
  static FileUtil? _instance;
  
  // 单例模式
  factory FileUtil() {
    _instance ??= FileUtil._internal();
    return _instance!;
  }
  
  FileUtil._internal();
  
  // ==================== 目录管理 ====================
  
  /// 获取临时目录
  Future<Directory> getTempDir() async {
    return await getTemporaryDirectory();
  }
  
  /// 获取文档目录
  Future<Directory> getDocDir() async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// 获取支持目录
  Future<Directory> getSupportDir() async {
    return await getApplicationSupportDirectory();
  }
  
  /// 获取缓存目录
  Future<Directory> getCacheDir() async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/${StorageConfig.cacheDir}');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }
  
  /// 获取图片缓存目录
  Future<Directory> getImageCacheDir() async {
    final cacheDir = await getCacheDir();
    final imageDir = Directory('${cacheDir.path}/${StorageConfig.imageDir}');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }
  
  /// 获取视频缓存目录
  Future<Directory> getVideoCacheDir() async {
    final cacheDir = await getCacheDir();
    final videoDir = Directory('${cacheDir.path}/${StorageConfig.videoDir}');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir;
  }
  
  /// 获取音频缓存目录
  Future<Directory> getAudioCacheDir() async {
    final cacheDir = await getCacheDir();
    final audioDir = Directory('${cacheDir.path}/${StorageConfig.audioDir}');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }
  
  /// 获取文件缓存目录
  Future<Directory> getFileCacheDir() async {
    final cacheDir = await getCacheDir();
    final fileDir = Directory('${cacheDir.path}/${StorageConfig.fileDir}');
    if (!await fileDir.exists()) {
      await fileDir.create(recursive: true);
    }
    return fileDir;
  }
  
  // ==================== 文件操作 ====================
  
  /// 检查文件是否存在
  Future<bool> exists(String path) async {
    return await File(path).exists();
  }
  
  /// 删除文件
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ 删除文件失败: $e');
      return false;
    }
  }
  
  /// 复制文件
  Future<String?> copyFile(String sourcePath, String destPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('❌ 源文件不存在: $sourcePath');
        return null;
      }
      
      final destFile = await sourceFile.copy(destPath);
      return destFile.path;
    } catch (e) {
      print('❌ 复制文件失败: $e');
      return null;
    }
  }
  
  /// 移动文件
  Future<String?> moveFile(String sourcePath, String destPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('❌ 源文件不存在: $sourcePath');
        return null;
      }
      
      final destFile = await sourceFile.rename(destPath);
      return destFile.path;
    } catch (e) {
      print('❌ 移动文件失败: $e');
      return null;
    }
  }
  
  /// 读取文件内容（文本）
  Future<String?> readFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        print('❌ 文件不存在: $path');
        return null;
      }
      return await file.readAsString();
    } catch (e) {
      print('❌ 读取文件失败: $e');
      return null;
    }
  }
  
  /// 写入文件内容（文本）
  Future<bool> writeFile(String path, String content) async {
    try {
      final file = File(path);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('❌ 写入文件失败: $e');
      return false;
    }
  }
  
  /// 读取文件内容（字节）
  Future<Uint8List?> readFileAsBytes(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        print('❌ 文件不存在: $path');
        return null;
      }
      return await file.readAsBytes();
    } catch (e) {
      print('❌ 读取文件失败: $e');
      return null;
    }
  }
  
  /// 写入文件内容（字节）
  Future<bool> writeFileAsBytes(String path, Uint8List bytes) async {
    try {
      final file = File(path);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      print('❌ 写入文件失败: $e');
      return false;
    }
  }
  
  // ==================== 文件信息 ====================
  
  /// 获取文件大小（字节）
  Future<int?> getFileSize(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }
      return await file.length();
    } catch (e) {
      print('❌ 获取文件大小失败: $e');
      return null;
    }
  }
  
  /// 格式化文件大小
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  /// 获取文件扩展名
  String getFileExtension(String path) {
    final index = path.lastIndexOf('.');
    if (index == -1) return '';
    return path.substring(index + 1).toLowerCase();
  }
  
  /// 获取文件名（不含扩展名）
  String getFileNameWithoutExtension(String path) {
    final name = path.split('/').last;
    final index = name.lastIndexOf('.');
    if (index == -1) return name;
    return name.substring(0, index);
  }
  
  // ==================== 图片压缩 ====================
  
  /// 压缩图片
  Future<String?> compressImage(
    String imagePath, {
    int quality = AppConstants.imageQuality,
    int? targetWidth,
    int? targetHeight,
  }) async {
    try {
      final dir = await getImageCacheDir();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = '${dir.path}/$fileName';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: quality,
        minWidth: targetWidth ?? 1920,
        minHeight: targetHeight ?? 1920,
      );
      
      return result?.path;
    } catch (e) {
      print('❌ 压缩图片失败: $e');
      return null;
    }
  }
  
  /// 压缩图片到指定大小以下（KB）
  Future<String?> compressImageToSize(
    String imagePath,
    int targetSizeKB,
  ) async {
    try {
      int quality = 90;
      String? compressedPath = imagePath;
      
      while (quality > 10) {
        compressedPath = await compressImage(
          imagePath,
          quality: quality,
        );
        
        if (compressedPath == null) break;
        
        final size = await getFileSize(compressedPath);
        if (size == null) break;
        
        if (size <= targetSizeKB * 1024) {
          return compressedPath;
        }
        
        quality -= 10;
      }
      
      return compressedPath;
    } catch (e) {
      print('❌ 压缩图片到指定大小失败: $e');
      return null;
    }
  }
  
  // ==================== 保存到相册 ====================
  
  /// 保存图片到相册
  Future<bool> saveImageToGallery(String imagePath) async {
    try {
      final result = await ImageGallerySaver.saveFile(imagePath);
      return result['isSuccess'] == true;
    } catch (e) {
      print('❌ 保存图片到相册失败: $e');
      return false;
    }
  }
  
  /// 保存视频到相册
  Future<bool> saveVideoToGallery(String videoPath) async {
    try {
      final result = await ImageGallerySaver.saveFile(videoPath);
      return result['isSuccess'] == true;
    } catch (e) {
      print('❌ 保存视频到相册失败: $e');
      return false;
    }
  }
  
  // ==================== 清理缓存 ====================
  
  /// 清理所有缓存
  Future<bool> clearAllCache() async {
    try {
      final cacheDir = await getCacheDir();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      return true;
    } catch (e) {
      print('❌ 清理缓存失败: $e');
      return false;
    }
  }
  
  /// 清理图片缓存
  Future<bool> clearImageCache() async {
    try {
      final imageDir = await getImageCacheDir();
      if (await imageDir.exists()) {
        await imageDir.delete(recursive: true);
        await imageDir.create();
      }
      return true;
    } catch (e) {
      print('❌ 清理图片缓存失败: $e');
      return false;
    }
  }
  
  /// 获取缓存大小
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getCacheDir();
      if (!await cacheDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final size = await entity.length();
          totalSize += size;
        }
      }
      
      return totalSize;
    } catch (e) {
      print('❌ 获取缓存大小失败: $e');
      return 0;
    }
  }
  
  /// 清理过期缓存
  Future<bool> clearExpiredCache({int days = 7}) async {
    try {
      final cacheDir = await getCacheDir();
      if (!await cacheDir.exists()) {
        return true;
      }
      
      final now = DateTime.now();
      final expireTime = now.subtract(Duration(days: days));
      
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(expireTime)) {
            await entity.delete();
          }
        }
      }
      
      return true;
    } catch (e) {
      print('❌ 清理过期缓存失败: $e');
      return false;
    }
  }
}

