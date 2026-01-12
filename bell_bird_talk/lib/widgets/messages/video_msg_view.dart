import 'dart:io';

import 'package:bell_bird_talk/pages/chat/image_preview_page.dart';
import 'package:bell_bird_talk/services/file_path_helper.dart';
import 'package:flutter/material.dart';

class VideoMsgView extends StatelessWidget {
  VideoMsgView({
    Key? key,
    required this.isMine,
    required this.status,
    required this.message,
  }) : super(key: key);

  Map<String, dynamic> message;
  bool isMine;
  String status;

  @override
  Widget build(BuildContext context) {
    return _buildVideoMessage(context, message, isMine, status);
  }

  /// 构建视频消息（显示缩略图并可点击播放/预览）
  Widget _buildVideoMessage(
    BuildContext context,
    Map<String, dynamic> message,
    bool isMine,
    String status,
  ) {
    print("message视频: $message");
    final localThumbPath = message['imageLocalPath'] as String?;
    final thumbUrl = message['imageUrl'] as String?;
    final videoUrl =
        message['videoUrl'] as String? ?? message['fileUrl'] as String?;
    final duration = message['videoDuration'] as int? ?? 0;
    Widget thumbWidget;

    // 将相对路径转换为完整路径
    final pathHelper = FilePathHelper.instance;
    final fullThumbPath = localThumbPath != null
        ? pathHelper.toFullPathSync(localThumbPath)
        : null;

    if (fullThumbPath != null && File(fullThumbPath).existsSync()) {
      thumbWidget = Image.file(
        File(fullThumbPath),
        width: 180,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (thumbUrl != null && thumbUrl.isNotEmpty) {
      thumbWidget = Image.network(
        thumbUrl,
        width: 180,
        height: 120,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 180,
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 180,
            height: 120,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      );
    } else {
      thumbWidget = Container(
        width: 180,
        height: 120,
        color: Colors.grey[300],
        child: const Icon(Icons.videocam, size: 40, color: Colors.grey),
      );
    }

    // 显示时长
    String durationText = '';
    if (duration > 0) {
      final d = Duration(seconds: duration);
      final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      durationText = '$mm:$ss';
    }

    return GestureDetector(
      onTap: () {
        // 预览或播放视频
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImagePreviewPage(
              imageMessages: [
                {
                  'type': 'video',
                  'videoUrl': videoUrl,
                  'coverUrl': thumbUrl,
                  'thumbnailUrl': thumbUrl,
                  'imageLocalPath': localThumbPath,
                  'videoLocalPath': message['fileLocalPath'],
                  'fileLocalPath': message['fileLocalPath'],
                  'id': message['id'],
                },
              ],
              initialIndex: 0,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: thumbWidget),
          // 播放按钮
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
          // 时长角标
          if (durationText.isNotEmpty)
            Positioned(
              right: 8,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  durationText,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          // 发送中遮罩
          if (status == 'sending' || status == 'pending')
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          // 发送失败遮罩
          if (status == 'failed')
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red, size: 36),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
