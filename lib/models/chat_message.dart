import 'package:ecdh/encrypt_message_content.dart';

class ChatMessage {
  final String content;
  final DateTime timestamp;
  final bool isEncrypted;
  final String sender;
  final EncryptedMessage? encryptedData; // 新增加密資料

  ChatMessage({
    required this.content,
    required this.timestamp,
    required this.isEncrypted,
    required this.sender,
    this.encryptedData,
  });
}
