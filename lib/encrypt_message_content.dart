//  {
//       'encryptedData': encryptedData,
//       'nonce': nonce,
//       'messageHash': messageHash,
//       'keyFingerprint': 'mock-key-fingerprint',
//     };

class EncryptedMessage {
  final String encryptedContent;
  final String nonce;
  final String messageHash;
  final String? keyFingerprint;
  final int? messageCounter;

  EncryptedMessage({
    required this.encryptedContent,
    required this.nonce,
    required this.messageHash,
    this.keyFingerprint,
    this.messageCounter,
  });

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      encryptedContent: json['encryptedData'] as String,
      nonce: json['nonce'] as String,
      messageHash: json['messageHash'] as String,
      keyFingerprint: json['keyFingerprint'] as String?,
      messageCounter: json['messageCounter'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encryptedData': encryptedContent,
      'nonce': nonce,
      'messageHash': messageHash,
      'keyFingerprint': keyFingerprint,
      if (messageCounter != null) 'messageCounter': messageCounter,
    };
  }
}
