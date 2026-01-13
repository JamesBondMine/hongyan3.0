import 'package:flutter/material.dart';

/// 应用颜色配置类
/// 支持亮色模式和深色模式的颜色定义
class GbsColors {
  // 私有构造函数，防止实例化
  GbsColors._();

  // ===========================================================================
  // 亮色模式颜色定义
  // ===========================================================================

  /// 页面背景主色A - 主要背景色-灰
  static const Color lightBackgroundA = Color.fromARGB(255, 240, 240, 240);

  /// 页面背景主色B - ffffff
  static const Color lightBackgroundB = Color(0xFFFFFFFF);

  /// 主要按钮颜色
  static const Color lightPrimaryButton = Color(0xFF1D61E7);

  /// 主要按钮颜色
  static const Color primaryColor = Color(0xFF1D61E7);


  /// 主要卡片主色
  static const Color lightCardPrimary = Color(0xFFFFFFFF);

  /// APPBar的主色A - 主要背景
  static const Color lightAppBarColorA = Color(0xFFFFFFFF);

  /// APPBar的主色B - 次要背景（渐变用）
  static const Color lightAppBarColorB = Color(0xFFF3F3F3);

  /// APPBar的标题颜色
  static const Color lightAppBarTitle = Color(0xFF212121);

  /// 主要标题文字颜色
  static const Color lightTitlePrimary = Color(0xFF212121);

  /// 主要描述文字颜色
  static const Color lightDesPrimary = Color(0xFF757575);

  /// 主要按钮文字颜色
  static const Color lightButtonTextPrimary = Color(0xFFFFFFFF);

  /// 文字tap颜色
  static const Color textPrimary = Color(0xFF1D61E7);

  /// 文字主要颜色
  static const Color titleColor = Color(0xFF000000);
  /// 文字描述颜色
  static const Color des1Color = Color(0xFF111111);
  /// 文字描述颜色
  static const Color des6Color = Color(0xFF666666);

  /// 文字描述颜色
  static const Color des9Color = Color(0xFF999999);

  /// 次要按钮颜色
  static const Color lightSecondaryButton = Color(0xFFE3F2FD);

  /// 次要按钮文字颜色
  static const Color lightButtonTextSecondary = Color(0xFF2196F3);

  /// 边框颜色
  static const Color lightBorder = Color(0xFFE0E0E0);

  /// 分割线颜色
  static const Color lightDivider = Color(0xFFE9E9E9);

  /// 禁用状态颜色
  static final Color lightDisabled = const Color(0xFF1D61E7).withOpacity(0.5);

  /// 成功状态颜色
  static const Color lightSuccess = Color(0xFF4CAF50);

  /// 警告状态颜色
  static const Color lightWarning = Color(0xFFFF9800);

  /// 错误状态颜色
  static const Color lightError = Color(0xFFF44336);

  /// 信息状态颜色
  static const Color lightInfo = Color(0xFF2196F3);

  /// 输入框背景色
  static const Color lightInputBackground = Color(0xFFF5F5F5);

  /// 标签页选中颜色
  static const Color lightTabSelected = Color(0xFF2196F3);

  /// 标签页未选中颜色
  static const Color lightTabUnselected = Color(0xFF757575);

  // ===========================================================================
  // 深色模式颜色定义
  // ===========================================================================

  /// 页面背景主色A - 主要背景色
  static const Color darkBackgroundPrimary = Color(0xFF121212);

  /// 页面背景主色B - 次要背景色
  static const Color darkBackgroundSecondary = Color(0xFF1E1E1E);

  /// 主要按钮颜色
  static const Color darkPrimaryButton = Color(0xFF2196F3);

  /// 主要卡片主色
  static const Color darkCardPrimary = Color(0xFF1E1E1E);

  /// APPBar的主色A - 主要背景
  static const Color darkAppBarPrimary = Color(0xFF1E1E1E);

  /// APPBar的主色B - 次要背景（渐变用）
  static const Color darkAppBarSecondary = Color(0xFF2D2D2D);

  /// APPBar的标题颜色
  static const Color darkAppBarTitle = Color(0xFFFFFFFF);

  /// 主要标题文字颜色
  static const Color darkTitlePrimary = Color(0xFFFFFFFF);

  /// 主要描述文字颜色
  static const Color darkDescriptionPrimary = Color(0xFFB0B0B0);

  /// 主要按钮文字颜色
  static const Color darkButtonTextPrimary = Color(0xFFFFFFFF);

  /// 次要按钮颜色
  static const Color darkSecondaryButton = Color(0xFF2D2D2D);

  /// 次要按钮文字颜色
  static const Color darkButtonTextSecondary = Color(0xFF2196F3);

  /// 边框颜色
  static const Color darkBorder = Color(0xFF404040);

  /// 分割线颜色
  static const Color darkDivider = Color(0xFF404040);

  /// 禁用状态颜色
  static const Color darkDisabled = Color(0xFF616161);

  /// 成功状态颜色
  static const Color darkSuccess = Color(0xFF4CAF50);

  /// 警告状态颜色
  static const Color darkWarning = Color(0xFFFF9800);

  /// 错误状态颜色
  static const Color darkError = Color(0xFFF44336);

  /// 信息状态颜色
  static const Color darkInfo = Color(0xFF2196F3);

  /// 输入框背景色
  static const Color darkInputBackground = Color(0xFF2D2D2D);

  /// 标签页选中颜色
  static const Color darkTabSelected = Color(0xFF2196F3);

  /// 标签页未选中颜色
  static const Color darkTabUnselected = Color(0xFFB0B0B0);

  // ===========================================================================
  // 通用颜色（亮色和深色模式共用）
  // ===========================================================================

  /// 透明色
  static const Color transparent = Colors.transparent;

  /// 白色
  static const Color white = Colors.white;

  /// 黑色
  static const Color black = Colors.black;

  /// 蓝色主色调
  static const Color blue = Color(0xFF2196F3);

  /// 蓝色变体
  static const Color blueAccent = Color(0xFF448AFF);

  /// 灰色系列
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ===========================================================================
  // 工具方法
  // ===========================================================================

  /// 根据是否为深色模式获取对应的颜色
  static Color getBackgroundPrimary(bool isDark) {
    return isDark ? darkBackgroundPrimary : lightBackgroundA;
  }

  static Color getBackgroundSecondary(bool isDark) {
    return isDark ? darkBackgroundSecondary : lightBackgroundB;
  }

  static Color getPrimaryButton(bool isDark) {
    return isDark ? darkPrimaryButton : lightPrimaryButton;
  }

  static Color getCardPrimary(bool isDark) {
    return isDark ? darkCardPrimary : lightCardPrimary;
  }

  static Color getAppBarPrimary(bool isDark) {
    return isDark ? darkAppBarPrimary : lightAppBarColorA;
  }

  static Color getAppBarSecondary(bool isDark) {
    return isDark ? darkAppBarSecondary : lightAppBarColorB;
  }

  static Color getAppBarTitle(bool isDark) {
    return isDark ? darkAppBarTitle : lightAppBarTitle;
  }

  static Color getTitlePrimary(bool isDark) {
    return isDark ? darkTitlePrimary : lightTitlePrimary;
  }

  static Color getDescriptionPrimary(bool isDark) {
    return isDark ? darkDescriptionPrimary : lightDesPrimary;
  }

  static Color getButtonTextPrimary(bool isDark) {
    return isDark ? darkButtonTextPrimary : lightButtonTextPrimary;
  }

  static Color getSecondaryButton(bool isDark) {
    return isDark ? darkSecondaryButton : lightSecondaryButton;
  }

  static Color getButtonTextSecondary(bool isDark) {
    return isDark ? darkButtonTextSecondary : lightButtonTextSecondary;
  }

  static Color getBorder(bool isDark) {
    return isDark ? darkBorder : lightBorder;
  }

  static Color getDivider(bool isDark) {
    return isDark ? darkDivider : lightDivider;
  }

  static Color getDisabled(bool isDark) {
    return isDark ? darkDisabled : lightDisabled;
  }

  static Color getSuccess(bool isDark) {
    return isDark ? darkSuccess : lightSuccess;
  }

  static Color getWarning(bool isDark) {
    return isDark ? darkWarning : lightWarning;
  }

  static Color getError(bool isDark) {
    return isDark ? darkError : lightError;
  }

  static Color getInfo(bool isDark) {
    return isDark ? darkInfo : lightInfo;
  }

  static Color getInputBackground(bool isDark) {
    return isDark ? darkInputBackground : lightInputBackground;
  }

  static Color getTabSelected(bool isDark) {
    return isDark ? darkTabSelected : lightTabSelected;
  }

  static Color getTabUnselected(bool isDark) {
    return isDark ? darkTabUnselected : lightTabUnselected;
  }
}