import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:ecdh/encrypt_message_content.dart';

class MessageEncryptionService {
  /// 簡易版 E2EE - 計算共享密鑰
  /// A傳訊息：A的公鑰 + B的公鑰 + A的私鑰 -> 共享密鑰
  /// B收訊息：A的公鑰 + B的公鑰 + B的私鑰 -> 相同的共享密鑰
  static Future<String> getSimpleSessionKey({
    required String myPublicKey, // 我的公鑰
    required String otherPublicKey, // 對方的公鑰
    required String myPrivateKey, // 自己的私鑰
  }) async {
    try {
      debugPrint('[getSimpleSessionKey] myPublicKey: $myPublicKey');
      debugPrint('[getSimpleSessionKey] otherPublicKey: $otherPublicKey');
      debugPrint('[getSimpleSessionKey] myPrivateKey: $myPrivateKey');

      // 先比較一次，確保排序一致（例如字典序）
      String firstKey = myPublicKey.compareTo(otherPublicKey) <= 0
          ? myPublicKey
          : otherPublicKey;
      String secondKey = myPublicKey.compareTo(otherPublicKey) <= 0
          ? otherPublicKey
          : myPublicKey;

      final algorithm = X25519();
      final myPrivateKeyPair = await algorithm.newKeyPairFromSeed(
        base64Decode(myPrivateKey),
      );
      final remotePublicKey = SimplePublicKey(
        base64Decode(otherPublicKey),
        type: KeyPairType.x25519,
      );

      // 計算共享密鑰（ECDH）
      final sharedSecret = await algorithm.sharedSecretKey(
        keyPair: myPrivateKeyPair,
        remotePublicKey: remotePublicKey,
      );
      final sharedSecretBytes = await sharedSecret.extractBytes();

      // 固定順序組合公鑰，確保雙方一致
      final firstKeyBytes = base64Decode(firstKey);
      final secondKeyBytes = base64Decode(secondKey);

      final combinedKeys = [
        ...firstKeyBytes,
        ...secondKeyBytes,
        ...sharedSecretBytes,
      ];

      final sessionKey = sha256.convert(combinedKeys).bytes;
      debugPrint('[getSimpleSessionKey] sessionKey: $sessionKey');
      final sessionKeyBase64 = base64Encode(sessionKey);

      return sessionKeyBase64;
    } catch (e) {
      throw Exception('計算共享密鑰失敗: $e');
    }
  }

  /// 簡易版加密訊息
  /// 用法：A傳訊息給B時調用
  static Future<EncryptedMessage> encryptSimpleMessage({
    required String plaintext,
    required String myPublicKey, // A的公鑰
    required String receiverPublicKey, // B的公鑰
    required String senderPrivateKey, // A的私鑰
    required int messageCounter,
  }) async {
    try {
      // 計算共享密鑰
      final sessionKeyBase64 = await getSimpleSessionKey(
        myPublicKey: myPublicKey,
        otherPublicKey: receiverPublicKey,
        myPrivateKey: senderPrivateKey,
      );
      final sessionKey = base64Decode(sessionKeyBase64);

      // 派生訊息金鑰
      final messageKey = await _deriveMessageKey(sessionKey, messageCounter);

      // 生成隨機 nonce
      final nonce = List<int>.generate(12, (i) => Random.secure().nextInt(256));

      // 使用 ChaCha20-Poly1305 加密
      final algorithm = Chacha20.poly1305Aead();
      final secretKey = await algorithm.newSecretKeyFromBytes(messageKey);

      final plaintextBytes = utf8.encode(plaintext);
      final encryptedData = await algorithm.encrypt(
        plaintextBytes,
        secretKey: secretKey,
        nonce: nonce,
      );

      // 修正：密文需包含 MAC，存 concatenation
      return EncryptedMessage(
        encryptedContent: base64Encode(encryptedData.concatenation()),
        nonce: base64Encode(nonce), // nonce 可選，concatenation 已含 nonce
        messageHash: await _computeMessageHash(plaintext),
        keyFingerprint: null,
        messageCounter: messageCounter,
      );
    } catch (e) {
      throw Exception('簡易訊息加密失敗: $e');
    }
  }

  /// 簡易版解密訊息
  /// 用法：B收到A的訊息時調用
  static Future<String> decryptSimpleMessage({
    required EncryptedMessage encryptedMessage,
    required String myPublicKey, // A的公鑰
    required String otherPublicKey, // B的公鑰
    required String myPrivateKey, // B的私鑰
  }) async {
    try {
      // 計算共享密鑰
      final sessionKeyBase64 = await getSimpleSessionKey(
        myPublicKey: myPublicKey, // 自己的公鑰
        otherPublicKey: otherPublicKey, // 對方的公鑰
        myPrivateKey: myPrivateKey, // 自己的私鑰
      );
      final sessionKey = base64Decode(sessionKeyBase64);

      // 派生訊息金鑰
      final messageCounter = encryptedMessage.messageCounter ?? 0;
      final messageKey = await _deriveMessageKey(sessionKey, messageCounter);

      // 取得加密內容（concatenation 包含 nonce+密文+MAC）
      final encryptedBytes = base64Decode(encryptedMessage.encryptedContent);

      // 使用 ChaCha20-Poly1305 解密
      final algorithm = Chacha20.poly1305Aead();
      final secretKey = await algorithm.newSecretKeyFromBytes(messageKey);
      final encryptedData = SecretBox.fromConcatenation(
        encryptedBytes,
        nonceLength: 12,
        macLength: 16,
      );

      final decryptedBytes = await algorithm.decrypt(
        encryptedData,
        secretKey: secretKey,
      );
      final plaintext = utf8.decode(decryptedBytes);

      // 驗證訊息完整性
      final expectedHash = encryptedMessage.messageHash;
      final actualHash = await _computeMessageHash(plaintext);

      if (expectedHash != actualHash) {
        throw Exception('訊息完整性驗證失敗');
      }

      return plaintext;
    } catch (e) {
      throw Exception('簡易訊息解密失敗: $e');
    }
  }

  /// 派生訊息金鑰
  static Future<List<int>> _deriveMessageKey(
    List<int> sessionKey,
    int messageCounter,
  ) async {
    final hkdf = cryptography.Hkdf(
      hmac: cryptography.Hmac.sha256(),
      outputLength: 32,
    );

    final salt = List<int>.generate(32, (i) => 0); // 使用全零 salt
    final info = utf8.encode('YelloPage Message Key $messageCounter');

    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(sessionKey),
      nonce: salt,
      info: info,
    );

    return await derivedKey.extractBytes();
  }

  /// 計算訊息雜湊
  static Future<String> _computeMessageHash(String message) async {
    final hash = await Sha256().hash(utf8.encode(message));
    return base64Encode(hash.bytes);
  }
}
