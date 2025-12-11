import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

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
  
  VoiceRecordState _state = VoiceRecordState.idle;
  String? _recordPath;
  int _recordDuration = 0;  // 录制时长（秒）
  int _playPosition = 0;    // 播放位置（秒）
  Timer? _timer;
  
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

  /// 开始录制
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
        _recordPath = path;
        _recordDuration = 0;
      });

      // 启动计时器
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordDuration >= maxDuration) {
          _stopRecording();
          return;
        }
        setState(() {
          _recordDuration++;
        });
      });
    } catch (e) {
      print('录制失败: $e');
    }
  }

  /// 暂停/继续录制
  Future<void> _togglePauseRecording() async {
    if (_state == VoiceRecordState.recording) {
      await _recorder.pause();
      _timer?.cancel();
      setState(() => _state = VoiceRecordState.paused);
    } else if (_state == VoiceRecordState.paused) {
      await _recorder.resume();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordDuration >= maxDuration) {
          _stopRecording();
          return;
        }
        setState(() => _recordDuration++);
      });
      setState(() => _state = VoiceRecordState.recording);
    }
  }

  /// 停止录制
  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    
    if (path != null && _recordDuration > 0) {
      setState(() {
        _state = VoiceRecordState.recorded;
        _recordPath = path;
      });
    } else {
      setState(() => _state = VoiceRecordState.idle);
    }
  }

  /// 删除录音
  void _deleteRecording() {
    _timer?.cancel();
    _player.stop();
    
    if (_recordPath != null) {
      try {
        File(_recordPath!).deleteSync();
      } catch (_) {}
    }
    
    setState(() {
      _state = VoiceRecordState.idle;
      _recordPath = null;
      _recordDuration = 0;
      _playPosition = 0;
    });
  }

  /// 播放/暂停
  Future<void> _togglePlay() async {
    if (_state == VoiceRecordState.playing) {
      await _player.pause();
      _timer?.cancel();
      setState(() => _state = VoiceRecordState.recorded);
    } else if (_state == VoiceRecordState.recorded && _recordPath != null) {
      await _player.play(DeviceFileSource(_recordPath!));
      
      setState(() {
        _state = VoiceRecordState.playing;
        _playPosition = 0;
      });
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_playPosition >= _recordDuration) {
          timer.cancel();
          setState(() {
            _state = VoiceRecordState.recorded;
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
            _state = VoiceRecordState.recorded;
            _playPosition = 0;
          });
        }
      });
    }
  }

  /// 发送语音
  void _sendVoice() {
    if (_recordPath != null && _recordDuration > 0) {
      widget.onSend?.call(VoiceRecordResult(
        filePath: _recordPath!,
        duration: _recordDuration,
      ));
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
    final isRecording = _state == VoiceRecordState.recording || _state == VoiceRecordState.paused;
    final isPlaying = _state == VoiceRecordState.playing;
    final hasRecorded = _state == VoiceRecordState.recorded || isPlaying;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // 左侧：播放按钮（录制完成后显示）
          if (hasRecorded)
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
                : _buildWaveform(),
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
    final isRecording = _state == VoiceRecordState.recording || _state == VoiceRecordState.paused;
    final hasRecorded = _state == VoiceRecordState.recorded || _state == VoiceRecordState.playing;
    final isIdle = _state == VoiceRecordState.idle;
    
    // 录制中/录制完成：删除、麦克风/发送、关闭
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
          
          // 中间按钮：空闲显示麦克风开始，录制中显示停止，录制完成显示发送
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
              onTap: _stopRecording,
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
                  Icons.stop,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            )
          else if (hasRecorded)
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
            ),
          
          // 关闭
          GestureDetector(
            onTap: _close,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.grey[600],
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

