import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 文件路径助手
/// 用于处理iOS沙盒路径变化问题
/// 存储时使用相对路径，读取时拼接沙盒路径
class FilePathHelper {
  static FilePathHelper? _instance;
  static FilePathHelper get instance => _instance ??= FilePathHelper._();
  
  FilePathHelper._();
  
  String? _tempPath;
  String? _docPath;
  String? _cachePath;
  
  /// 初始化路径（应在app启动时调用）
  Future<void> init() async {
    final tempDir = await getTemporaryDirectory();
    final docDir = await getApplicationDocumentsDirectory();
    final cacheDir = await getApplicationCacheDirectory();
    
    _tempPath = tempDir.path;
    _docPath = docDir.path;
    _cachePath = cacheDir.path;
    
    print('📁 沙盒路径初始化:');
    print('   临时目录: $_tempPath');
    print('   文档目录: $_docPath');
    print('   缓存目录: $_cachePath');
  }
  
  /// 获取临时目录路径
  Future<String> get tempPath async {
    if (_tempPath == null) await init();
    return _tempPath!;
  }
  
  /// 获取文档目录路径
  Future<String> get docPath async {
    if (_docPath == null) await init();
    return _docPath!;
  }
  
  /// 获取缓存目录路径
  Future<String> get cachePath async {
    if (_cachePath == null) await init();
    return _cachePath!;
  }
  
  /// 将完整路径转换为相对路径（用于存储）
  /// 例如: /var/mobile/.../tmp/voice_123.m4a -> tmp/voice_123.m4a
  Future<String> toRelativePath(String fullPath) async {
    await init();
    
    // 尝试移除各种沙盒前缀
    if (_tempPath != null && fullPath.startsWith(_tempPath!)) {
      return 'tmp${fullPath.substring(_tempPath!.length)}';
    }
    if (_docPath != null && fullPath.startsWith(_docPath!)) {
      return 'doc${fullPath.substring(_docPath!.length)}';
    }
    if (_cachePath != null && fullPath.startsWith(_cachePath!)) {
      return 'cache${fullPath.substring(_cachePath!.length)}';
    }
    
    // 如果已经是相对路径，直接返回
    if (fullPath.startsWith('tmp/') || 
        fullPath.startsWith('doc/') || 
        fullPath.startsWith('cache/')) {
      return fullPath;
    }
    
    // 兜底：只保留文件名
    final fileName = fullPath.split('/').last;
    return 'tmp/$fileName';
  }
  
  /// 将相对路径转换为完整路径（用于读取）
  /// 例如: tmp/voice_123.m4a -> /var/mobile/.../tmp/voice_123.m4a
  Future<String> toFullPath(String relativePath) async {
    await init();
    
    // 如果已经是完整路径，直接返回
    if (relativePath.startsWith('/')) {
      return relativePath;
    }
    
    if (relativePath.startsWith('tmp/')) {
      return '$_tempPath${relativePath.substring(3)}';
    }
    if (relativePath.startsWith('doc/')) {
      return '$_docPath${relativePath.substring(3)}';
    }
    if (relativePath.startsWith('cache/')) {
      return '$_cachePath${relativePath.substring(5)}';
    }
    
    // 默认放在临时目录
    return '$_tempPath/$relativePath';
  }
  
  /// 检查文件是否存在（支持相对路径）
  Future<bool> fileExists(String path) async {
    final fullPath = await toFullPath(path);
    return File(fullPath).exists();
  }
  
  /// 获取文件对象（支持相对路径）
  Future<File> getFile(String path) async {
    final fullPath = await toFullPath(path);
    return File(fullPath);
  }
  
  /// 同步版本：将相对路径转换为完整路径
  /// 注意：必须先调用 init() 初始化
  String toFullPathSync(String relativePath) {
    // 如果已经是完整路径，直接返回
    if (relativePath.startsWith('/')) {
      return relativePath;
    }
    
    if (_tempPath == null) {
      // 未初始化，返回原路径
      return relativePath;
    }
    
    if (relativePath.startsWith('tmp/')) {
      return '$_tempPath${relativePath.substring(3)}';
    }
    if (relativePath.startsWith('doc/')) {
      return '$_docPath${relativePath.substring(3)}';
    }
    if (relativePath.startsWith('cache/')) {
      return '$_cachePath${relativePath.substring(5)}';
    }
    
    // 默认放在临时目录
    return '$_tempPath/$relativePath';
  }
  
  /// 同步版本：检查文件是否存在
  bool fileExistsSync(String path) {
    final fullPath = toFullPathSync(path);
    return File(fullPath).existsSync();
  }
  
  /// 将文件复制到永久存储目录（Documents）
  /// 用于将临时缓存文件（如 image_picker）复制到永久位置
  /// @param sourcePath 源文件路径（完整路径）
  /// @param subDir 子目录名称（如 'images', 'voices'）
  /// @return 返回相对路径（用于存储）
  Future<String> copyToPermanentStorage(String sourcePath, String subDir) async {
    await init();
    
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('源文件不存在: $sourcePath');
    }
    
    // 创建子目录
    final targetDir = Directory('$_docPath/$subDir');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    
    // 生成唯一文件名
    final fileName = sourcePath.split('/').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueFileName = '${timestamp}_$fileName';
    final targetPath = '${targetDir.path}/$uniqueFileName';
    
    // 复制文件
    await sourceFile.copy(targetPath);
    
    print('📁 文件已复制到永久存储: $targetPath');
    
    // 返回相对路径
    return 'doc/$subDir/$uniqueFileName';
  }
  
  /// 获取永久存储目录下的完整路径
  Future<String> getPermanentPath(String subDir, String fileName) async {
    await init();
    return '$_docPath/$subDir/$fileName';
  }
}

