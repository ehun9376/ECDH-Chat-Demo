# ECDH 加密聊天室專案結構

## 檔案組織

專案已重構為模組化架構，每個 class 和 widget 都分離到獨立的檔案中：

### 📁 lib/
主要程式碼目錄

#### 📁 app/
應用程式核心配置
- `my_app.dart` - 主應用程式類別，包含 MaterialApp 配置

#### 📁 models/  
資料模型
- `chat_message.dart` - 聊天訊息資料模型，包含加密相關欄位

#### 📁 pages/
頁面組件
- `test_page.dart` - 主聊天測試頁面，包含三個聊天面板和密鑰管理邏輯

#### 📁 widgets/
UI 組件
- `message_bubble.dart` - 獨立的訊息氣泡組件，具備自動解密功能

#### 🔧 服務類別
- `message_encryption_service.dart` - 加密/解密服務
- `encrypt_message_content.dart` - 加密訊息內容定義
- `simple_text.dart` - 自訂文字組件

#### 📱 主入口
- `main.dart` - 應用程式入口點，僅包含 main() 函數

## 架構特色

### 🔐 加密功能
- **ECDH X25519** 密鑰交換
- **ChaCha20-Poly1305** 加密演算法
- **端對端加密** 聊天訊息

### 🎯 UI 特色
- **三面板設計**：用戶A | Server | 用戶B
- **獨立訊息組件**：每則訊息都是獨立的 StatefulWidget
- **自動解密**：接收到的加密訊息會自動解密顯示
- **即時加密狀態**：顯示解密進度和加密狀態

### 📦 模組化設計
- **分離關注點**：每個類別都有獨立的檔案
- **清晰目錄結構**：按功能分類組織檔案
- **易於維護**：模組化架構便於後續開發和維護

## 使用方式

1. **執行應用程式**：
   ```bash
   flutter run
   ```

2. **執行測試**：
   ```bash
   flutter test
   ```

3. **程式碼分析**：
   ```bash
   flutter analyze
   ```

## 檔案依賴關係

```
main.dart
├── app/my_app.dart
    └── pages/test_page.dart
        ├── models/chat_message.dart
        ├── widgets/message_bubble.dart
        ├── message_encryption_service.dart
        └── simple_text.dart
```

重構完成後，程式碼更加模組化、易於維護，每個組件都有明確的職責分工。
