
import 'package:flutter/material.dart';

import 'dart:io';

import 'package:bell_bird_talk/pages/chat/image_preview_page.dart';
import 'package:bell_bird_talk/services/file_path_helper.dart';

class ImageMsgView extends StatelessWidget {
  ImageMsgView({
    Key? key,
    required this.isMine,
    required this.status,
    required this.message,
    required this.onTap,
  }) : super(key: key);


  Map<String, dynamic> message;
  bool isMine;
  String status;
  VoidCallback onTap;


  @override
  Widget build(BuildContext context) { 
    return _buildImageMessage(message, isMine, status);
  }

  /// 构建图片消息
  Widget _buildImageMessage(
    Map<String, dynamic> message,
    bool isMine,
    String status,
  ) {
    final localPath = message['imageLocalPath'] as String?;
    final imageUrl = message['imageUrl'] as String?;
    print("localPath: $localPath");
    print("imageUrl: $imageUrl");
    Widget imageWidget;

    // 将相对路径转换为完整路径
    final pathHelper = FilePathHelper.instance;
    final fullPath = localPath != null
        ? pathHelper.toFullPathSync(localPath)
        : null;
    print("fullPath: $fullPath");

    if (fullPath != null && File(fullPath).existsSync()) {
      // 显示本地图片
      imageWidget = Image.file(
        File(fullPath),
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      // 显示网络图片
      imageWidget = Image.network(
        imageUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 150,
            height: 150,
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
            width: 150,
            height: 150,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      );
    } else {
      // 无图片显示占位
      imageWidget = Container(
        width: 150,
        height: 150,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }
    // print("\n\n---------------------------------\n构建图片消息\n message: ${message['id']} content: ${message['content']} localPath: $localPath imageUrl: $imageUrl \n---------------------------------\n\n");
    return GestureDetector(
      onTap: () {
        onTap();
       
      },
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: imageWidget),
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