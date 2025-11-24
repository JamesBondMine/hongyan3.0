import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart' as crypto;
import '../config/constants.dart';

/// 加密工具类
class EncryptUtil {
  static EncryptUtil? _instance;
  
  late encrypt.Key _key;
  late encrypt.IV _iv;
  late encrypt.Encrypter _encrypter;
  
  // 单例模式
  factory EncryptUtil() {
    _instance ??= EncryptUtil._internal();
    return _instance!;
  }
  
  EncryptUtil._internal() {
    // 初始化 AES 加密器
    _key = encrypt.Key.fromUtf8(AppConstants.aesKey);
    _iv = encrypt.IV.fromUtf8(AppConstants.aesIV);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }
  
  // ==================== AES 加密/解密 ====================
  
  /// AES 加密
  String aesEncrypt(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('❌ AES 加密失败: $e');
      return plainText;
    }
  }
  
  /// AES 解密
  String aesDecrypt(String encryptedText) {
    try {
      final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      print('❌ AES 解密失败: $e');
      return encryptedText;
    }
  }
  
  // ==================== Base64 编码/解码 ====================
  
  /// Base64 编码
  String base64Encode(String text) {
    try {
      return base64.encode(utf8.encode(text));
    } catch (e) {
      print('❌ Base64 编码失败: $e');
      return text;
    }
  }
  
  /// Base64 解码
  String base64Decode(String encodedText) {
    try {
      return utf8.decode(base64.decode(encodedText));
    } catch (e) {
      print('❌ Base64 解码失败: $e');
      return encodedText;
    }
  }
  
  // ==================== MD5 哈希 ====================
  
  /// MD5 加密（32位小写）
  String md5(String text) {
    return md5Hash(text);
  }
  
  /// MD5 哈希
  static String md5Hash(String text) {
    return crypto.md5.convert(utf8.encode(text)).toString();
  }
  
  /// MD5 哈希（32位大写）
  String md5Upper(String text) {
    return md5(text).toUpperCase();
  }
  
  // ==================== SHA 哈希 ====================
  
  /// SHA-1 哈希
  String sha1Hash(String text) {
    return crypto.sha1.convert(utf8.encode(text)).toString();
  }
  
  /// SHA-256 哈希
  String sha256Hash(String text) {
    return crypto.sha256.convert(utf8.encode(text)).toString();
  }
  
  /// SHA-512 哈希
  String sha512Hash(String text) {
    return crypto.sha512.convert(utf8.encode(text)).toString();
  }
  
  // ==================== HMAC 哈希 ====================
  
  /// HMAC-SHA256
  String hmacSha256(String text, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(text);
    final hmac = crypto.Hmac(crypto.sha256, key);
    return hmac.convert(bytes).toString();
  }
  
  // ==================== 密码加密 ====================
  
  /// 密码加密（MD5 + 盐）
  String encryptPassword(String password, {String? salt}) {
    final saltValue = salt ?? AppConstants.aesKey;
    return md5('$password$saltValue');
  }
  
  /// 验证密码
  bool verifyPassword(String password, String encryptedPassword, {String? salt}) {
    return encryptPassword(password, salt: salt) == encryptedPassword;
  }
  
  // ==================== 自定义密钥加密 ====================
  
  /// 使用自定义密钥加密
  String aesEncryptWithKey(String plainText, String key, String iv) {
    try {
      final encKey = encrypt.Key.fromUtf8(key.padRight(16).substring(0, 16));
      final encIv = encrypt.IV.fromUtf8(iv.padRight(16).substring(0, 16));
      final encrypter = encrypt.Encrypter(encrypt.AES(encKey));
      final encrypted = encrypter.encrypt(plainText, iv: encIv);
      return encrypted.base64;
    } catch (e) {
      print('❌ 自定义密钥加密失败: $e');
      return plainText;
    }
  }
  
  /// 使用自定义密钥解密
  String aesDecryptWithKey(String encryptedText, String key, String iv) {
    try {
      final encKey = encrypt.Key.fromUtf8(key.padRight(16).substring(0, 16));
      final encIv = encrypt.IV.fromUtf8(iv.padRight(16).substring(0, 16));
      final encrypter = encrypt.Encrypter(encrypt.AES(encKey));
      final decrypted = encrypter.decrypt64(encryptedText, iv: encIv);
      return decrypted;
    } catch (e) {
      print('❌ 自定义密钥解密失败: $e');
      return encryptedText;
    }
  }
  
  // ==================== 随机字符串 ====================
  
  /// 生成随机字符串
  static String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (index) {
      final random = DateTime.now().millisecondsSinceEpoch % chars.length;
      return chars[random];
    }).join();
  }
  
  /// 生成随机数字字符串
  static String randomNumber(int length) {
    const chars = '0123456789';
    return List.generate(length, (index) {
      final random = DateTime.now().millisecondsSinceEpoch % chars.length;
      return chars[random];
    }).join();
  }
}

/// 扩展方法
extension EncryptExtension on String {
  /// AES 加密
  String get aesEncrypt => EncryptUtil().aesEncrypt(this);
  
  /// AES 解密
  String get aesDecrypt => EncryptUtil().aesDecrypt(this);
  
  /// Base64 编码
  String get base64Encode => EncryptUtil().base64Encode(this);
  
  /// Base64 解码
  String get base64Decode => EncryptUtil().base64Decode(this);
  
  /// MD5 加密
  String get md5 => EncryptUtil().md5(this);
  
  /// SHA-256 哈希
  String get sha256 => EncryptUtil().sha256Hash(this);
}

