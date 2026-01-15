//
//  LegacyMethodsHandler.swift
//  Runner
//
//  遗留方法处理器 - 临时桥接
//  用于处理尚未迁移到专门 Handler 的方法
//

import Flutter
import Foundation

/// 遗留方法处理器
/// 这是一个临时解决方案，用于处理尚未迁移的方法
/// 随着迁移进度，这个类中的方法会逐渐减少
class LegacyMethodsHandler {
    
    /// 处理尚未迁移的方法
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 返回未实现错误，提示需要迁移
        print("⚠️ 方法 '\(call.method)' 尚未迁移到新的 Handler")
        print("📝 请从 AppDelegate_old.swift 中复制对应的实现")
        
        result(FlutterError(
            code: "NOT_MIGRATED",
            message: "方法 '\(call.method)' 尚未迁移，请查看 AppDelegate_old.swift",
            details: [
                "method": call.method,
                "suggestion": "从 AppDelegate_old.swift 复制实现到对应的 Handler"
            ]
        ))
    }
}
