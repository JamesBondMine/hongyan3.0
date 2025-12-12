import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import '../../services/file_path_helper.dart';
import '../../utils/permission_util.dart';

/// 图片预览页面
class ImagePreviewPage extends StatefulWidget {
  /// 图片消息列表
  final List<Map<String, dynamic>> imageMessages;
  
  /// 初始显示的图片索引
  final int initialIndex;
  
  const ImagePreviewPage({
    super.key,
    required this.imageMessages,
    this.initialIndex = 0,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  /// 切换控制栏显示/隐藏
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }
  
  /// 下载当前图片
  Future<void> _downloadCurrentImage() async {
    if (_currentIndex < 0 || _currentIndex >= widget.imageMessages.length) {
      return;
    }
    
    final message = widget.imageMessages[_currentIndex];
    final localPath = message['imageLocalPath'] as String?;
    final imageUrl = message['imageUrl'] as String?;
    
    // 检查权限
    // final permissionUtil = PermissionUtil();
    // final hasPermission = await permissionUtil.requestPhotos();
    // if (!hasPermission) {
    //   EasyLoading.showError('需要相册权限才能保存图片');
    //   return;
    // }
    
    try {
      EasyLoading.show(status: '正在保存...');
      
      Uint8List? imageBytes;
      
      // 优先使用本地路径
      if (localPath != null && localPath.isNotEmpty) {
        final pathHelper = FilePathHelper.instance;
        final fullPath = await pathHelper.toFullPath(localPath);
        final file = File(fullPath);
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
        }
      }
      
      // 如果本地文件不存在，从网络下载
      if (imageBytes == null && imageUrl != null && imageUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        }
      }
      
      if (imageBytes == null) {
        EasyLoading.showError('图片数据不存在');
        return;
      }
      
      // 保存到相册
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: 'image_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (result['isSuccess'] == true) {
        EasyLoading.showSuccess('图片已保存到相册');
      } else {
        EasyLoading.showError('保存失败');
      }
    } catch (e) {
      print('❌ 保存图片失败: $e');
      EasyLoading.showError('保存失败: $e');
    }
  }
  
  /// 构建图片 Widget
  Widget _buildImageWidget(Map<String, dynamic> message) {
    final localPath = message['imageLocalPath'] as String?;
    final imageUrl = message['imageUrl'] as String?;
    
    // 优先使用本地路径
    if (localPath != null && localPath.isNotEmpty) {
      final pathHelper = FilePathHelper.instance;
      final fullPath = pathHelper.toFullPathSync(localPath);
      final file = File(fullPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      }
    }
    
    // 使用网络图片
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }
    
    return _buildErrorWidget();
  }
  
  /// 构建错误 Widget
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              '图片加载失败',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // 图片预览区域
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageMessages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final message = widget.imageMessages[index];
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: _buildImageWidget(message),
                  ),
                );
              },
            ),
            
            // 顶部控制栏
            if (_showControls)
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // 返回按钮
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      // 图片计数
                      Text(
                        '${_currentIndex + 1} / ${widget.imageMessages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 下载按钮
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: _downloadCurrentImage,
                        tooltip: '保存到相册',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

