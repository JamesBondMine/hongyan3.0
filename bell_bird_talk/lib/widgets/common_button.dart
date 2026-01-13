import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/gbs_colors.dart';

/// 通用按钮组件
/// 默认灰色不可点击，激活状态可以点击
class CommonButton extends StatelessWidget {
  /// 按钮文本
  final String text;
  
  /// 点击回调
  final VoidCallback? onPressed;
  
  /// 是否启用（默认false，灰色不可点击）
  final bool enabled;
  
  /// 是否加载中
  final bool isLoading;
  
  /// 按钮宽度（默认全宽）
  final double? width;
  
  /// 按钮高度（默认50）
  final double height;
  
  /// 背景颜色（启用状态）
  final Color? backgroundColor;
  
  /// 文字颜色（启用状态）
  final Color? textColor;
  
  /// 禁用背景颜色
  final Color? disabledBackgroundColor;
  
  /// 禁用文字颜色
  final Color? disabledTextColor;
  
  /// 圆角半径（默认12）
  final double borderRadius;
  
  /// 字体大小（默认16）
  final double fontSize;
  
  /// 字体粗细（默认bold）
  final FontWeight fontWeight;
  
  /// 阴影高度（默认2）
  final double elevation;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.enabled = false,
    this.isLoading = false,
    this.width,
    this.height = 50,
    this.backgroundColor,
    this.textColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.borderRadius = 12,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 确定是否可点击：启用且不在加载中
    final canPress = enabled && !isLoading;
    
    // 背景颜色：启用时使用传入的颜色或默认蓝色，禁用时使用灰色
    final bgColor = canPress
        ? (backgroundColor ?? GbsColors.getPrimaryButton(isDark))
        : (disabledBackgroundColor ?? GbsColors.getDisabled(isDark));
    
    // 文字颜色：启用时使用传入的颜色或默认白色，禁用时使用灰色文字
    final txtColor = canPress
        ? (textColor ?? GbsColors.getButtonTextPrimary(isDark))
        : (disabledTextColor ?? GbsColors.getBackgroundPrimary(isDark));

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: canPress ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          disabledBackgroundColor: bgColor,
          disabledForegroundColor: txtColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: elevation,
        ),
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(txtColor),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
      ),
    );
  }
}

