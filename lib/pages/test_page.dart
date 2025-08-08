import 'package:cryptography/cryptography.dart';
import 'package:ecdh/message_encryption_service.dart';
import 'package:ecdh/widgets/simple_text.dart';
import 'package:ecdh/models/chat_message.dart';
import 'package:ecdh/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final TextEditingController _userAController = TextEditingController();
  final TextEditingController _userBController = TextEditingController();
  final ScrollController _chatAController = ScrollController();
  final ScrollController _chatBController = ScrollController();
  final ScrollController _serverController = ScrollController();

  List<ChatMessage> chatAMessages = [];
  List<ChatMessage> chatBMessages = [];
  List<ChatMessage> serverMessages = [];

  bool _isLoading = false;

  // 模擬用戶A和B的密鑰對
  String? _publicKeyA;
  String? _privateKeyA;
  String? _publicKeyB;
  String? _privateKeyB;

  String? _sessionKeyA;
  String? _sessionKeyB;
  int _messageCounter = 1;

  @override
  void initState() {
    super.initState();
    _generateKeyPairs();
  }

  @override
  void dispose() {
    _userAController.dispose();
    _userBController.dispose();
    _chatAController.dispose();
    _chatBController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  // 生成密鑰對
  Future<void> _generateKeyPairs() async {
    final algorithm = X25519();

    // 生成用戶A的密鑰對
    final keyPairA = await algorithm.newKeyPair();
    final privateKeyA = await keyPairA.extractPrivateKeyBytes();
    final publicKeyA = await keyPairA.extractPublicKey();
    _privateKeyA = base64Encode(privateKeyA);
    _publicKeyA = base64Encode(publicKeyA.bytes);

    // 生成用戶B的密鑰對
    final keyPairB = await algorithm.newKeyPair();
    final privateKeyB = await keyPairB.extractPrivateKeyBytes();
    final publicKeyB = await keyPairB.extractPublicKey();
    _privateKeyB = base64Encode(privateKeyB);
    _publicKeyB = base64Encode(publicKeyB.bytes);

    // 計算共享密鑰
    _sessionKeyA = await MessageEncryptionService.getSimpleSessionKey(
      myPublicKey: _publicKeyA!,
      otherPublicKey: _publicKeyB!,
      myPrivateKey: _privateKeyA!,
    );
    _sessionKeyB = await MessageEncryptionService.getSimpleSessionKey(
      myPublicKey: _publicKeyB!,
      otherPublicKey: _publicKeyA!,
      myPrivateKey: _privateKeyB!,
    );

    setState(() {});
  }

  // 發送訊息 (用戶A -> 用戶B)
  Future<void> _sendMessageFromA() async {
    if (_userAController.text.isEmpty) {
      _showSnackBar('請輸入訊息');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final plaintext = _userAController.text;

      // 加密訊息
      final encryptedMessage =
          await MessageEncryptionService.encryptSimpleMessage(
            plaintext: plaintext,
            myPublicKey: _publicKeyA!,
            receiverPublicKey: _publicKeyB!,
            senderPrivateKey: _privateKeyA!,
            messageCounter: _messageCounter++,
          );

      // 添加到用戶A的聊天記錄（顯示原始明文，因為是自己發送的）
      chatAMessages.add(
        ChatMessage(
          content: plaintext,
          timestamp: DateTime.now(),
          isEncrypted: false,
          sender: 'A',
        ),
      );

      // 添加到Server記錄（顯示加密傳輸）
      serverMessages.add(
        ChatMessage(
          content: 'A → B: ${encryptedMessage.encryptedContent}',
          timestamp: DateTime.now(),
          isEncrypted: true,
          sender: 'A',
        ),
      );

      // 添加到用戶B的聊天記錄（加密狀態，等待解密）
      chatBMessages.add(
        ChatMessage(
          content: encryptedMessage.encryptedContent,
          timestamp: DateTime.now(),
          isEncrypted: true,
          sender: 'A',
          encryptedData: encryptedMessage,
        ),
      );

      _userAController.clear();
      setState(() {
        _isLoading = false;
      });

      _scrollToBottom(_chatAController);
      _scrollToBottom(_chatBController);
      _scrollToBottom(_serverController);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('發送失敗: $e');
    }
  }

  // 發送訊息 (用戶B -> 用戶A)
  Future<void> _sendMessageFromB() async {
    if (_userBController.text.isEmpty) {
      _showSnackBar('請輸入訊息');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final plaintext = _userBController.text;

      // 加密訊息
      final encryptedMessage =
          await MessageEncryptionService.encryptSimpleMessage(
            plaintext: plaintext,
            myPublicKey: _publicKeyB!,
            receiverPublicKey: _publicKeyA!,
            senderPrivateKey: _privateKeyB!,
            messageCounter: _messageCounter++,
          );

      // 添加到用戶B的聊天記錄（顯示原始明文，因為是自己發送的）
      chatBMessages.add(
        ChatMessage(
          content: plaintext,
          timestamp: DateTime.now(),
          isEncrypted: false,
          sender: 'B',
        ),
      );

      // 添加到Server記錄（顯示加密傳輸）
      serverMessages.add(
        ChatMessage(
          content: 'B → A: ${encryptedMessage.encryptedContent}',
          timestamp: DateTime.now(),
          isEncrypted: true,
          sender: 'B',
        ),
      );

      // 添加到用戶A的聊天記錄（加密狀態，等待解密）
      chatAMessages.add(
        ChatMessage(
          content: encryptedMessage.encryptedContent,
          timestamp: DateTime.now(),
          isEncrypted: true,
          sender: 'A',
          encryptedData: encryptedMessage,
        ),
      );

      _userBController.clear();
      setState(() {
        _isLoading = false;
      });

      _scrollToBottom(_chatAController);
      _scrollToBottom(_chatBController);
      _scrollToBottom(_serverController);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('發送失敗: $e');
    }
  }

  void _scrollToBottom(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECDH 加密聊天室'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 標題
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SimpleText(
              text: "端對端加密聊天測試",
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textColor: Colors.deepPurple,
              align: TextAlign.center,
            ),
          ),

          // 聊天區域
          Expanded(
            child: Row(
              children: [
                // 用戶A聊天區域
                Expanded(
                  flex: 2,
                  child: _buildChatPanel(
                    title: "用戶 A",
                    messages: chatAMessages,
                    controller: _userAController,
                    scrollController: _chatAController,
                    onSend: _sendMessageFromA,
                    color: Colors.blue,
                  ),
                ),

                // 分隔線
                Container(width: 2, color: Colors.grey[300]),

                // Server 訊息區域 (中間)
                Expanded(flex: 2, child: _buildServerPanel()),

                // 分隔線
                Container(width: 2, color: Colors.grey[300]),

                // 用戶B聊天區域
                Expanded(
                  flex: 2,
                  child: _buildChatPanel(
                    title: "用戶 B",
                    messages: chatBMessages,
                    controller: _userBController,
                    scrollController: _chatBController,
                    onSend: _sendMessageFromB,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // 密鑰資訊
          if (_publicKeyA != null && _publicKeyB != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.shade50,
              ),
              child: Column(
                children: [
                  SimpleText(
                    text: "密鑰資訊 (Session Key 相同表示加密成功)",
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    textColor: Colors.blue.shade800,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: SimpleText(
                          text: "A的SessionKey: $_sessionKeyA",
                          fontSize: 10,
                          textColor: Colors.blue.shade700,
                        ),
                      ),
                      Expanded(
                        child: SimpleText(
                          text: "B的SessionKey: $_sessionKeyB",
                          fontSize: 10,
                          textColor: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatPanel({
    required String title,
    required List<ChatMessage> messages,
    required TextEditingController controller,
    required ScrollController scrollController,
    required VoidCallback onSend,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 標題
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: SimpleText(
              text: title,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              textColor: color,
              align: TextAlign.center,
            ),
          ),

          // 聊天訊息列表
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                controller: scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.sender == title.split(' ')[1];

                  // 確定解密用的密鑰
                  String? myPublicKey;
                  String? otherPublicKey;
                  String? myPrivateKey;

                  if (title.contains('A')) {
                    myPublicKey = _publicKeyA;
                    otherPublicKey = _publicKeyB;
                    myPrivateKey = _privateKeyA;
                  } else if (title.contains('B')) {
                    myPublicKey = _publicKeyB;
                    otherPublicKey = _publicKeyA;
                    myPrivateKey = _privateKeyB;
                  }

                  return MessageBubble(
                    message: message,
                    isMe: isMe,
                    color: color,
                    myPublicKey: myPublicKey,
                    otherPublicKey: otherPublicKey,
                    myPrivateKey: myPrivateKey,
                  );
                },
              ),
            ),
          ),

          // 輸入框和發送按鈕
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '輸入訊息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isLoading ? null : onSend,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 標題
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: SimpleText(
              text: "🌐 Server 傳輸記錄",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              textColor: Colors.purple,
              align: TextAlign.center,
            ),
          ),

          // Server 訊息列表
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                controller: _serverController,
                itemCount: serverMessages.length,
                itemBuilder: (context, index) {
                  final message = serverMessages[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: message.sender == 'A'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: message.sender == 'A'
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SimpleText(
                          text: message.content,
                          fontSize: 12,
                          textColor: Colors.black87,
                        ),
                        const SizedBox(height: 2),
                        SimpleText(
                          text:
                              "📡 ${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}:${message.timestamp.second.toString().padLeft(2, '0')}",
                          fontSize: 10,
                          textColor: Colors.grey[600],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 說明文字
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: SimpleText(
              text: "📋 顯示所有加密傳輸訊息 (密文)",
              fontSize: 11,
              textColor: Colors.grey[600],
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
