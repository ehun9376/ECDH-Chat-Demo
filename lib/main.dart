import 'package:cryptography/cryptography.dart';
import 'package:ecdh/encrypt_message_content.dart';
import 'package:ecdh/message_encryption_service.dart';
import 'package:ecdh/simple_text.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECDH Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final TextEditingController _inputController = TextEditingController();
  String _resultText = '';
  EncryptedMessage? _encryptedMessage;
  bool _isLoading = false;

  // 模擬用戶A和B的密鑰對
  String? _publicKeyA;
  String? _privateKeyA;
  String? _publicKeyB;
  String? _privateKeyB;

  String? _sessionKeyA;
  String? _sessionKeyB;

  @override
  void initState() {
    super.initState();
    _generateKeyPairs();
  }

  @override
  void dispose() {
    _inputController.dispose();
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

  // 加密訊息
  Future<void> _encryptMessage() async {
    if (_inputController.text.isEmpty) {
      _showSnackBar('請輸入要加密的文字');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final encryptedMessage =
          await MessageEncryptionService.encryptSimpleMessage(
            plaintext: _inputController.text,
            myPublicKey: _publicKeyA!,
            receiverPublicKey: _publicKeyB!,
            senderPrivateKey: _privateKeyA!,
            messageCounter: 1,
          );

      setState(() {
        _encryptedMessage = encryptedMessage;
        _resultText = '加密結果:\n${encryptedMessage.encryptedContent}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultText = '加密失敗: $e';
        _isLoading = false;
      });
    }
    //收鍵盤

    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  // 解密訊息
  Future<void> _decryptMessage() async {
    if (_encryptedMessage == null) {
      _showSnackBar('請先進行加密操作');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final decryptedMessage =
          await MessageEncryptionService.decryptSimpleMessage(
            encryptedMessage: _encryptedMessage!,
            myPublicKey: _publicKeyB!,
            otherPublicKey: _publicKeyA!,
            myPrivateKey: _privateKeyB!,
          );

      setState(() {
        _resultText = '解密結果:\n$decryptedMessage';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultText = '解密失敗: $e';
        _isLoading = false;
      });
    }
    //收鍵盤
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
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
        title: const Text('加解密測試'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SimpleText(
            text: "加解密 Demo",
            fontSize: 24,
            fontWeight: FontWeight.bold,
            textColor: Colors.deepPurple,
            align: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // 輸入框
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: '請輸入要加密的文字',
              border: OutlineInputBorder(),
              hintText: '在此輸入您的訊息...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // 按鈕區域
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _encryptMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('加密', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _decryptMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('解密', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 結果顯示區域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SimpleText(
                  text: "結果:",
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  textColor: Colors.black87,
                ),
                const SizedBox(height: 8),
                SimpleText(
                  text: _resultText.isEmpty ? '尚無結果' : _resultText,
                  fontSize: 14,
                  textColor: _resultText.isEmpty ? Colors.grey : Colors.black,
                  lines: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 密鑰資訊顯示
          if (_publicKeyA != null && _publicKeyB != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SimpleText(
                    text: "密鑰資訊:",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    textColor: Colors.blue.shade800,
                  ),
                  const SizedBox(height: 4),
                  SimpleText(
                    text: "用戶A公鑰: ${_publicKeyA!.substring(0, 20)}...",
                    fontSize: 12,
                    textColor: Colors.blue.shade700,
                  ),
                  SimpleText(
                    text: "用戶A私鑰: ${_privateKeyA!.substring(0, 20)}...",
                    fontSize: 12,
                    textColor: Colors.blue.shade700,
                  ),
                  SimpleText(
                    text: "用戶B公鑰: ${_publicKeyB!.substring(0, 20)}...",
                    fontSize: 12,
                    textColor: Colors.blue.shade700,
                  ),
                  SimpleText(
                    text: "用戶B私鑰: ${_privateKeyB!.substring(0, 20)}...",
                    fontSize: 12,
                    textColor: Colors.blue.shade700,
                  ),
                  SizedBox(height: 10),
                  SimpleText(
                    text: "用戶A算出來的sessionKey:$_sessionKeyA",
                    fontSize: 12,
                    textColor: Colors.blue.shade700,
                  ),
                  SizedBox(height: 10),
                  SimpleText(
                    text: "用戶B算出來的sessionKey:$_sessionKeyB",
                    fontSize: 12,
                    textColor: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
