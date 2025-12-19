import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../../services/file_path_helper.dart';

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
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, Future<void>> _videoInitFutures = {};
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    for (final ctrl in _videoControllers.values) {
      ctrl.removeListener(_videoListener);
      ctrl.dispose();
    }
    super.dispose();
  }
  
  /// 视频播放状态监听
  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }
  
  /// 检查当前消息是否是视频
  bool _isCurrentVideo() {
    if (_currentIndex < 0 || _currentIndex >= widget.imageMessages.length) {
      return false;
    }
    final message = widget.imageMessages[_currentIndex];
    final type = (message['type'] as String?) ?? 'image';
    return type == 'video';
  }
  
  /// 切换控制栏显示/隐藏
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }
  
  /// 视频播放/暂停切换
  void _toggleVideoPlayPause() {
    if (!_isCurrentVideo()) {
      _toggleControls();
      return;
    }
    
    final controller = _videoControllers[_currentIndex];
    if (controller != null) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
      setState(() {});
    }
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

  /// 构建视频 Widget（直接播放）
  Widget _buildVideoWidget(Map<String, dynamic> message, int index) {
    final localPath = message['videoLocalPath'] as String? ??
        message['fileLocalPath'] as String? ??
        message['imageLocalPath'] as String?;
    final videoUrl = message['videoUrl'] as String? ??
        message['fileUrl'] as String? ??
        message['audioUrl'] as String?;

    VideoPlayerController _ensureController() {
      if (_videoControllers.containsKey(index)) {
        return _videoControllers[index]!;
      }
      VideoPlayerController controller;
      if (localPath != null && localPath.isNotEmpty) {
        final pathHelper = FilePathHelper.instance;
        final fullPath = pathHelper.toFullPathSync(localPath);
        controller = VideoPlayerController.file(File(fullPath));
      } else if (videoUrl != null && videoUrl.isNotEmpty) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(''));
      }
      _videoControllers[index] = controller;
      _videoInitFutures[index] = controller.initialize().then((_) {
        if (mounted && index == _currentIndex) {
          controller.play();
        }
      });
      controller.setLooping(true);
      controller.addListener(_videoListener);
      return controller;
    }

    final controller = _ensureController();
    final initFuture = _videoInitFutures[index]!;

    return FutureBuilder<void>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return _buildErrorWidget();
        }
        if (!controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final aspect = controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio;
        return Center(
          child: AspectRatio(
            aspectRatio: aspect,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                // 播放/暂停图标
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: controller.value.isPlaying ? 0.0 : 1.0,
                  child: const Icon(
                    Icons.play_circle_fill,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 构建视频进度条
  Widget _buildVideoProgressBar() {
    if (!_isCurrentVideo()) {
      return const SizedBox.shrink();
    }
    
    final controller = _videoControllers[_currentIndex];
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    
    final duration = controller.value.duration;
    final position = controller.value.position;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      
      if (hours > 0) {
        return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
      }
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 2,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).round(),
                );
                controller.seekTo(newPosition);
              },
            ),
          ),
          // 时间显示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  formatDuration(duration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    final isVideo = _isCurrentVideo();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: isVideo ? _toggleVideoPlayPause : _toggleControls,
        child: Stack(
          children: [
            // 图片预览区域
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageMessages.length,
              physics: isVideo ? const NeverScrollableScrollPhysics() : null,
              onPageChanged: (index) {
                final prev = _currentIndex;
                if (_videoControllers.containsKey(prev)) {
                  _videoControllers[prev]?.pause();
                }
                setState(() {
                  _currentIndex = index;
                });
                // 如果切换到视频页面，自动播放
                final message = widget.imageMessages[index];
                final type = (message['type'] as String?) ?? 'image';
                if (type == 'video' && _videoControllers.containsKey(index)) {
                  final controller = _videoControllers[index];
                  if (controller != null && controller.value.isInitialized) {
                    controller.play();
                  }
                }
              },
              itemBuilder: (context, index) {
                final message = widget.imageMessages[index];
                final type = (message['type'] as String?) ?? 'image';
                if (type == 'video') {
                  return Center(child: _buildVideoWidget(message, index));
                }
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
                      // 图片计数（视频时不显示）
                      if (!isVideo)
                        Text(
                          '${_currentIndex + 1} / ${widget.imageMessages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (!isVideo) const SizedBox(width: 16),
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
            
            // 底部视频进度条
            if (_showControls && isVideo)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: _buildVideoProgressBar(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

