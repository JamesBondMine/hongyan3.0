import 'package:flutter/material.dart';

/// 登录页面输入框封装组件
/// 
/// 特点：
/// - 卡片分为上中下三部分（上：标题，中：输入框，下：错误提示）
/// - 支持正常状态和异常状态
/// - 可自定义背景颜色
class LoginTextField extends StatelessWidget {
  /// 控制器
  final TextEditingController? controller;
  
  /// 标题文字（卡片上方）
  final String? title;
  
  /// 提示文字
  final String? hintText;
  
  /// 标签文字（在输入框内显示）
  final String? labelText;
  
  /// 前缀图标
  final Widget? prefixIcon;
  
  /// 后缀图标
  final Widget? suffixIcon;
  
  /// 键盘类型
  final TextInputType? keyboardType;
  
  /// 是否隐藏输入文字（用于密码）
  final bool obscureText;
  
  /// 最大长度
  final int? maxLength;
  
  /// 背景颜色（默认白色）
  final Color? backgroundColor;
  
  /// 是否处于异常状态
  final bool hasError;
  
  /// 异常状态下的错误提示文字
  final String? errorText;
  
  /// 输入框高度（默认48像素）
  final double height;
  
  /// 输入变更回调
  final ValueChanged<String>? onChanged;
  
  /// 输入完成回调
  final VoidCallback? onSubmitted;
  
  /// 是否启用
  final bool enabled;
  
  /// 只读模式
  final bool readOnly;
  
  /// 点击回调（用于只读模式下的点击事件）
  final VoidCallback? onTap;
  
  /// 尾部组件（放在输入框容器内部右侧）
  final Widget? trailingWidget;

  const LoginTextField({
    super.key,
    this.controller,
    this.title,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.backgroundColor,
    this.hasError = false,
    this.errorText,
    this.height = 48,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    // 正常状态边框颜色
    const Color normalBorderColor = Color(0xFFE9E9E9);
    // 异常状态边框颜色
    const Color errorBorderColor = Color(0xFFF44336);
    // 默认背景颜色（白色）
    final Color bgColor = backgroundColor ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上部分：标题
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF212121),
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // 中部分：输入框
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            
            border: Border.all(
              color: hasError ? errorBorderColor : normalBorderColor,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 输入框部分
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  maxLength: maxLength,
                  enabled: enabled,
                  readOnly: readOnly,
                  onTap: onTap,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted?.call(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF212121),
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    labelText: labelText,
                    prefixIcon: prefixIcon,
                    suffixIcon: trailingWidget == null ? suffixIcon : null,
                    counterText: maxLength != null ? '' : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                      // 如果有尾部组件，右侧需要留出空间
                    ),
                    filled: false, // 不使用filled，因为外层容器已经有背景色
                  ),
                ),
              ),
              // 尾部组件（如获取验证码按钮）
              if (trailingWidget != null) trailingWidget!,
            ],
          ),
        ),
        
        // 下部分：错误提示（仅在异常状态显示）
        if (hasError && errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFF44336),
            ),
          ),
        ],
      ],
    );
  }
}
