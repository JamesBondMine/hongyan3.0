# 头像裁剪功能实现

## 📝 需求

在用户选择头像图片后，跳转到裁剪页面，将图片裁剪成圆形，然后再上传。

## ✅ 实现内容

### 1. 添加依赖

在 `pubspec.yaml` 中添加：
```yaml
image_cropper: ^8.0.2
```

### 2. 导入包

在 `lib/pages/profile/profile_page.dart` 中添加：
```dart
import 'package:image_cropper/image_cropper.dart';
```

### 3. 修改上传流程

更新 `_pickAndUploadAvatar` 方法，添加裁剪步骤：

```dart
Future<void> _pickAndUploadAvatar(ImageSource source) async {
  // 1. 选择图片
  final XFile? pickedFile = await _imagePicker.pickImage(...);
  
  // 2. 裁剪图片为圆形 ⭐ 新增
  final CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: pickedFile.path,
    cropStyle: CropStyle.circle, // 圆形裁剪
    aspectRatioPresets: [CropAspectRatioPreset.square],
    uiSettings: [...],
  );
  
  // 3. 上传裁剪后的图片
  final File imageFile = File(croppedFile.path);
  await UserController.to.prepareAvatarInfo(imageFile);
}
```

### 4. 添加翻译

**中文** (`zh_cn.dart`):
```dart
'裁剪头像': '裁剪头像',
```

**英文** (`en_us.dart`):
```dart
'裁剪头像': 'Crop Avatar',
```

## 🎨 功能特点

### 圆形裁剪
- ✅ **Android**: 使用 `CropStyle.circle` 实现圆形裁剪框 UI
- ⚠️ **iOS**: 由于平台限制，只能显示方形裁剪框，但最终显示时会用 `CircleAvatar` 显示成圆形
- ✅ 锁定 1:1 比例
- ✅ 自动居中显示

### 平台适配

**Android 设置**:
- 裁剪框样式：圆形 ⭐
- 工具栏标题：裁剪头像
- 工具栏颜色：主题色
- 锁定比例：是
- 隐藏网格：是

**iOS 设置**:
- 裁剪框样式：方形（平台限制）⚠️
- 标题：裁剪头像
- 锁定比例：是
- 隐藏比例选择器：是
- 显示旋转按钮：是

> **注意**: iOS 的 `image_cropper` 库不支持圆形裁剪框 UI，只能显示方形裁剪框。但这不影响最终效果，因为头像在应用中会用 `CircleAvatar` 显示成圆形。

### 图片质量优化

选择图片时的参数调整：
```dart
maxWidth: 1200,      // 从 800 提升到 1200
maxHeight: 1200,     // 从 800 提升到 1200
imageQuality: 90,    // 从 85 提升到 90
```

## 📱 用户体验流程

1. **点击头像** → 触发选择图片
2. **选择图片** → 从相册选择
3. **裁剪页面** → 自动跳转到裁剪界面
   - 圆形裁剪框
   - 可以缩放、移动图片
   - 可以旋转图片
4. **确认裁剪** → 返回裁剪后的图片
5. **上传图片** → 显示上传进度
6. **更新头像** → 刷新显示

## 🔧 技术细节

### 裁剪配置

```dart
cropStyle: CropStyle.circle,  // Android 显示圆形裁剪框，iOS 不支持
aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),  // 强制 1:1 比例
aspectRatioPresets: [
  CropAspectRatioPreset.square,  // 1:1 比例
],
```

### 平台差异说明

**Android**:
- ✅ 支持 `CropStyle.circle`，裁剪框显示为圆形
- ✅ 用户可以直观地看到圆形裁剪效果

**iOS**:
- ⚠️ 不支持 `CropStyle.circle`，裁剪框只能是方形
- ✅ 但通过 `aspectRatio: 1:1` 确保裁剪成正方形
- ✅ 最终在应用中用 `CircleAvatar` 显示成圆形，效果一致

### UI 配置

**Android**:
```dart
AndroidUiSettings(
  toolbarTitle: '裁剪头像'.tr,
  toolbarColor: GbsColors.primaryColor,
  toolbarWidgetColor: Colors.white,
  initAspectRatio: CropAspectRatioPreset.square,
  lockAspectRatio: true,
  hideBottomControls: false,
  showCropGrid: false,
)
```

**iOS**:
```dart
IOSUiSettings(
  title: '裁剪头像'.tr,
  aspectRatioLockEnabled: true,
  resetAspectRatioEnabled: false,
  aspectRatioPresets: [
    CropAspectRatioPreset.square, // 只保留方形
  ],
  aspectRatioPickerButtonHidden: true,
  rotateButtonsHidden: false,
)
```

> **重要**: iOS 平台的 `image_cropper` 不支持圆形裁剪框 UI。这是库本身的限制，不是配置问题。解决方案是使用方形裁剪（1:1 比例），然后在应用中用 `CircleAvatar` 显示成圆形。

### 错误处理

```dart
try {
  // 选择图片
  final XFile? pickedFile = await _imagePicker.pickImage(...);
  if (pickedFile == null) return; // 用户取消选择
  
  // 裁剪图片
  final CroppedFile? croppedFile = await ImageCropper().cropImage(...);
  if (croppedFile == null) return; // 用户取消裁剪
  
  // 上传图片
  await UserController.to.prepareAvatarInfo(imageFile);
  
} catch (e) {
  EasyLoading.showError('上传失败'.tr + ': $e');
}
```

## 📦 依赖版本

- `image_picker: ^1.1.2` - 图片选择
- `image_cropper: ^8.0.2` - 图片裁剪 ⭐ 新增

## 🚀 使用方法

### 安装依赖

```bash
flutter pub get
```

### iOS 配置（如需要）

在 `ios/Podfile` 中确保有：
```ruby
platform :ios, '11.0'
```

### Android 配置（如需要）

在 `android/app/build.gradle` 中确保：
```gradle
minSdkVersion 21
```

## ✅ 测试清单

- [ ] 选择图片功能正常
- [ ] 裁剪页面正常显示
- [ ] 圆形裁剪框显示正确
- [ ] 可以缩放、移动图片
- [ ] 可以旋转图片
- [ ] 确认裁剪后返回正确
- [ ] 取消裁剪功能正常
- [ ] 上传裁剪后的图片成功
- [ ] 头像更新显示正确
- [ ] Android 平台测试通过
- [ ] iOS 平台测试通过

## 🎯 效果展示

### 流程图

```
用户点击头像
    ↓
选择图片（相册/相机）
    ↓
裁剪页面（圆形裁剪）
    ├─ 缩放图片
    ├─ 移动图片
    ├─ 旋转图片
    └─ 确认/取消
    ↓
上传图片
    ↓
更新头像显示
```

### 裁剪界面特点

- ✅ 圆形裁剪框
- ✅ 1:1 比例锁定
- ✅ 支持缩放
- ✅ 支持移动
- ✅ 支持旋转
- ✅ 实时预览
- ✅ 平台原生 UI

## 📝 注意事项

1. **平台差异** ⚠️
   - **Android**: 裁剪框显示为圆形，用户体验更直观
   - **iOS**: 裁剪框只能是方形（库的限制），但最终显示效果一致
   - 两个平台都会得到 1:1 比例的图片
   - 应用中都用 `CircleAvatar` 显示成圆形

2. **图片质量**
   - 选择时已设置较高质量（90%）
   - 裁剪不会再次压缩
   - 最终上传的是裁剪后的原图

3. **用户体验**
   - 用户可以随时取消裁剪
   - 取消后不会上传
   - 上传时显示进度提示

4. **性能优化**
   - 选择时限制最大尺寸（1200x1200）
   - 避免加载过大的图片
   - 裁剪后的图片大小适中

## 🔄 后续优化建议

1. **添加预览**
   - 裁剪前显示预览
   - 裁剪后显示预览

2. **添加滤镜**
   - 可选的图片滤镜
   - 亮度、对比度调整

3. **添加贴纸**
   - 可选的装饰贴纸
   - 边框效果

4. **批量处理**
   - 支持选择多张图片
   - 批量裁剪和上传

---

**实现时间**: 2026-01-14
**功能状态**: ✅ 已完成
**测试状态**: ⏳ 待测试
