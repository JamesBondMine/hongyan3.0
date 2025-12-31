import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/native_bridge.dart';

/// 语音录制状态
enum VoiceRecordState {
  idle,       // 空闲
  recording,  // 录制中
  paused,     // 暂停
  recorded,   // 录制完成
  playing,    // 播放中
}

/// 语音录制结果
class VoiceRecordResult {
  final String filePath;
  final int duration; // 秒

  VoiceRecordResult({
    required this.filePath,
    required this.duration,
  });
}

/// 语音录制面板
class VoiceRecordPanel extends StatefulWidget {
  final Function(VoiceRecordResult result)? onSend;
  final VoidCallback? onClose;
  final bool autoStart; // 自动开始录制

  const VoiceRecordPanel({
    super.key,
    this.onSend,
    this.onClose,
    this.autoStart = true,
  });

  @override
  State<VoiceRecordPanel> createState() => _VoiceRecordPanelState();
}

class _VoiceRecordPanelState extends State<VoiceRecordPanel> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final IOSNativeService _nativeService = IOSNativeService();
  
  VoiceRecordState _state = VoiceRecordState.idle;
  String? _currentRecordPath; // 当前正在录制的文件路径
  int _recordDuration = 0;  // 总录制时长（秒）
  int _currentSegmentDuration = 0; // 当前段的录制时长（秒）
  int _playPosition = 0;    // 播放位置（秒）
  Timer? _timer;
  
  // 多段语音文件列表
  final List<String> _voiceSegments = [];
  final List<int> _segmentDurations = []; // 每段的时长（秒）
  
  static const int maxDuration = 60; // 最大录制时长

  @override
  void initState() {
    super.initState();
    // 自动开始录制
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRecording();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  /// 开始录制（新的一段）
  Future<void> _startRecording() async {
    try {
      // 检查权限
      if (!await _recorder.hasPermission()) {
        return;
      }

      // 生成录音文件路径
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // 开始录制
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _state = VoiceRecordState.recording;
        _currentRecordPath = path;
        _currentSegmentDuration = 0;
      });

      // 启动计时器
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordDuration >= maxDuration) {
          _pauseAndSaveSegment();
          return;
        }
        setState(() {
          _currentSegmentDuration++;
          _recordDuration++;
        });
      });
    } catch (e) {
      print('录制失败: $e');
    }
  }

  /// 暂停并保存当前段
  Future<void> _pauseAndSaveSegment() async {
    _timer?.cancel();
    if (_state != VoiceRecordState.recording || _currentRecordPath == null) {
      return;
    }

    try {
      final path = await _recorder.stop();
      if (path != null && _currentSegmentDuration > 0) {
        // 保存当前段
        _voiceSegments.add(path);
        _segmentDurations.add(_currentSegmentDuration);
        print('💾 保存语音段: $path, 时长: ${_currentSegmentDuration}秒');
        
        setState(() {
          _state = VoiceRecordState.paused;
          _currentRecordPath = null;
          _currentSegmentDuration = 0;
        });
      }
    } catch (e) {
      print('暂停录制失败: $e');
      setState(() => _state = VoiceRecordState.paused);
    }
  }

  /// 继续录制（开始新的一段）
  Future<void> _resumeRecording() async {
    if (_state != VoiceRecordState.paused) {
      return;
    }
    
    // 开始新的录制段
    await _startRecording();
  }

  /// 删除录音（删除所有段）
  void _deleteRecording() {
    _timer?.cancel();
    _player.stop();
    
    // 删除所有语音段文件
    for (final path in _voiceSegments) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    
    // 删除当前正在录制的文件
    if (_currentRecordPath != null) {
      try {
        File(_currentRecordPath!).deleteSync();
      } catch (_) {}
    }
    
    setState(() {
      _state = VoiceRecordState.idle;
      _currentRecordPath = null;
      _recordDuration = 0;
      _currentSegmentDuration = 0;
      _playPosition = 0;
      _voiceSegments.clear();
      _segmentDurations.clear();
    });
  }

  /// 播放/暂停（播放合并后的音频，需要先合并）
  Future<void> _togglePlay() async {
    if (_state == VoiceRecordState.playing) {
      await _player.pause();
      _timer?.cancel();
      setState(() => _state = VoiceRecordState.paused);
    } else if (_state == VoiceRecordState.paused && _voiceSegments.isNotEmpty) {
      // 如果有多个段，需要先合并（这里简化处理，只播放第一段作为预览）
      // 实际发送时会合并所有段
      if (_voiceSegments.length == 1) {
        await _player.play(DeviceFileSource(_voiceSegments[0]));
      } else {
        // 多个段时，暂时不播放（或者可以合并后播放）
        print('⚠️ 多段语音暂不支持播放预览，请直接发送');
        return;
      }
      
      setState(() {
        _state = VoiceRecordState.playing;
        _playPosition = 0;
      });
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_playPosition >= _recordDuration) {
          timer.cancel();
          setState(() {
            _state = VoiceRecordState.paused;
            _playPosition = 0;
          });
          return;
        }
        setState(() => _playPosition++);
      });
      
      // 监听播放完成
      _player.onPlayerComplete.listen((event) {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _state = VoiceRecordState.paused;
            _playPosition = 0;
          });
        }
      });
    }
  }

  /// 合并多段语音文件
  Future<String?> _mergeVoiceSegments() async {
    if (_voiceSegments.isEmpty) {
      return null;
    }

    if (_voiceSegments.length == 1) {
      // 只有一段，直接返回
      return _voiceSegments[0];
    }

    try {
      // 生成合并后的文件路径
      final dir = await getTemporaryDirectory();
      final mergedPath = '${dir.path}/voice_merged_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 检查所有文件是否存在
      final List<String> validPaths = [];
      for (final path in _voiceSegments) {
        final file = File(path);
        if (await file.exists()) {
          validPaths.add(path);
        }
      }

      if (validPaths.isEmpty) {
        print('❌ 没有有效的语音文件');
        return null;
      }

      if (validPaths.length == 1) {
        // 只有一个有效文件，直接返回
        return validPaths[0];
      }

      print('📝 开始合并 ${validPaths.length} 段语音...');
      print('📝 文件列表: ${validPaths.join(", ")}');

      // 使用iOS原生方法合并音频文件
      final result = await _nativeService.mergeAudioFiles(
        filePaths: validPaths,
        outputPath: mergedPath,
      );

      if (result['success'] == true) {
        // 检查合并后的文件是否存在
        final mergedFile = File(mergedPath);
        if (await mergedFile.exists()) {
          print('✅ 语音合并成功: $mergedPath');
          return mergedPath;
        } else {
          print('❌ 合并后的文件不存在');
          return null;
        }
      } else {
        final error = result['error'] ?? '合并失败';
        print('❌ 合并语音失败: $error');
        return null;
      }
    } catch (e) {
      print('❌ 合并语音文件异常: $e');
      return null;
    }
  }

  /// 发送语音（合并多段后发送）
  Future<void> _sendVoice() async {
    // 如果当前正在录制，先暂停并保存当前段
    if (_state == VoiceRecordState.recording && _currentRecordPath != null) {
      await _pauseAndSaveSegment();
    }

    if (_voiceSegments.isEmpty && _currentRecordPath == null) {
      return;
    }

    // 如果还有当前段未保存，先保存
    if (_currentRecordPath != null && _currentSegmentDuration > 0) {
      _voiceSegments.add(_currentRecordPath!);
      _segmentDurations.add(_currentSegmentDuration);
    }

    if (_voiceSegments.isEmpty) {
      return;
    }

    // 合并所有语音段
    final mergedPath = await _mergeVoiceSegments();
    
    if (mergedPath != null && _recordDuration > 0) {
      widget.onSend?.call(VoiceRecordResult(
        filePath: mergedPath,
        duration: _recordDuration,
      ));
      
      // 清理临时文件
      _deleteRecording();
    }
  }

  /// 关闭面板
  void _close() {
    _deleteRecording();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动条
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 语音条
          _buildVoiceBar(),
          
          const SizedBox(height: 16),
          
          // 操作区
          _buildControlArea(),
          
          // 底部安全区
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  /// 语音条
  Widget _buildVoiceBar() {
    final isIdle = _state == VoiceRecordState.idle;
    final isRecording = _state == VoiceRecordState.recording;
    final isPaused = _state == VoiceRecordState.paused;
    final isPlaying = _state == VoiceRecordState.playing;
    final hasSegments = _voiceSegments.isNotEmpty || (_currentRecordPath != null && _currentSegmentDuration > 0);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // 左侧：播放按钮（有语音段时显示）
          if (hasSegments && !isRecording)
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 36),
          
          const SizedBox(width: 12),
          
          // 中间：语音波形或提示
          Expanded(
            child: isIdle 
                ? Center(
                    child: Text(
                      '点击麦克风开始录音',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(child: _buildWaveform()),
                      if (_voiceSegments.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${_voiceSegments.length}段',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          
          const SizedBox(width: 12),
          
          // 右侧：时间
          SizedBox(
            width: 50,
            child: Text(
              isIdle
                  ? '${maxDuration}s'  // 最大时长
                  : isRecording 
                      ? '${maxDuration - _recordDuration}s'  // 倒计时
                      : isPaused
                          ? '${_recordDuration}s'  // 总时长（暂停状态）
                          : isPlaying
                              ? '${_playPosition}s'  // 播放进度
                              : '${_recordDuration}s',  // 总时长
              style: TextStyle(
                fontSize: 14,
                color: isRecording ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 语音波形
  Widget _buildWaveform() {
    final isRecording = _state == VoiceRecordState.recording;
    final isPaused = _state == VoiceRecordState.paused;
    final isPlaying = _state == VoiceRecordState.playing;
    
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(20, (index) {
          // 简单的波形效果
          double height;
          if (isRecording || isPlaying) {
            // 动态波形
            height = 8 + (index % 3 + 1) * 6.0;
          } else if (isPaused) {
            // 暂停状态：静态波形
            height = 8 + (index % 4) * 4.0;
          } else {
            // 静态波形
            height = 8 + (index % 4) * 4.0;
          }
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: isRecording 
                  ? Colors.red.withValues(alpha: 0.6 + (index % 3) * 0.15)
                  : isPaused
                      ? Colors.orange.withValues(alpha: 0.4 + (index % 3) * 0.2)
                      : Colors.blue.withValues(alpha: 0.4 + (index % 3) * 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  /// 操作区
  Widget _buildControlArea() {
    final isRecording = _state == VoiceRecordState.recording;
    final isPaused = _state == VoiceRecordState.paused;
    final isIdle = _state == VoiceRecordState.idle;
    final hasSegments = _voiceSegments.isNotEmpty || (_currentRecordPath != null && _currentSegmentDuration > 0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 删除
          GestureDetector(
            onTap: _deleteRecording,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[400],
                size: 28,
              ),
            ),
          ),
          
          // 中间按钮：空闲显示麦克风开始，录制中显示停止，暂停后显示继续录制
          if (isIdle)
            GestureDetector(
              onTap: _startRecording,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            )
          else if (isRecording)
            GestureDetector(
              onTap: _pauseAndSaveSegment,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pause,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            )
          else if (isPaused)
            GestureDetector(
              onTap: _resumeRecording,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          
          // 发送按钮（只有有语音段时才显示）
          if (hasSegments)
            GestureDetector(
              onTap: _sendVoice,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          else
            const SizedBox(width: 72),
        ],
      ),
    );
  }
}

