import 'package:flutter/material.dart';
import 'package:ecdh/models/chat_message.dart';
import 'package:ecdh/message_encryption_service.dart';
import 'package:ecdh/widgets/simple_text.dart';

// 獨立的訊息 Widget
class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final Color color;
  final String? myPublicKey;
  final String? otherPublicKey;
  final String? myPrivateKey;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.color,
    this.myPublicKey,
    this.otherPublicKey,
    this.myPrivateKey,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String? _decryptedContent;
  bool _isDecrypting = false;
  bool _decryptionFailed = false;

  @override
  void initState() {
    super.initState();
    _decryptedContent = widget.message.content;

    // 如果是加密訊息且需要解密，則自動解密
    if (widget.message.isEncrypted &&
        widget.message.encryptedData != null &&
        widget.myPublicKey != null &&
        widget.otherPublicKey != null &&
        widget.myPrivateKey != null) {
      _decryptMessage();
    }
  }

  Future<void> _decryptMessage() async {
    if (_isDecrypting || widget.message.encryptedData == null) return;

    setState(() {
      _isDecrypting = true;
      _decryptionFailed = false;
    });

    try {
      final decryptedMessage =
          await MessageEncryptionService.decryptSimpleMessage(
            encryptedMessage: widget.message.encryptedData!,
            myPublicKey: widget.myPublicKey!,
            otherPublicKey: widget.otherPublicKey!,
            myPrivateKey: widget.myPrivateKey!,
          );

      setState(() {
        _decryptedContent = decryptedMessage;
        _isDecrypting = false;
      });
    } catch (e) {
      setState(() {
        _decryptionFailed = true;
        _isDecrypting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: widget.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.25,
            ),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? widget.color.withOpacity(0.8)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isDecrypting)
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SimpleText(
                        text: "解密中...",
                        fontSize: 12,
                        textColor: widget.isMe ? Colors.white : Colors.black,
                      ),
                    ],
                  )
                else if (_decryptionFailed)
                  SimpleText(
                    text: "❌ 解密失敗",
                    fontSize: 12,
                    textColor: Colors.red,
                  )
                else
                  SimpleText(
                    text: _decryptedContent ?? widget.message.content,
                    fontSize: 12,
                    textColor: widget.isMe ? Colors.white : Colors.black,
                  ),
                const SizedBox(height: 2),
                SimpleText(
                  text:
                      "${widget.message.isEncrypted ? '🔐' : '📝'} ${widget.message.timestamp.hour.toString().padLeft(2, '0')}:${widget.message.timestamp.minute.toString().padLeft(2, '0')}",
                  fontSize: 10,
                  textColor: widget.isMe
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
