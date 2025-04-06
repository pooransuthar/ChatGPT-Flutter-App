import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'models.dart' as models;

class ConversationProvider extends ChangeNotifier {
  List<models.Conversation> _conversations = [];
  int _currentConversationIndex = 0;
  String _yourChatGptApiKey = "YOUR_API_KEY";
  String _yourGeminiApiKey = "AIzaSyB8fAk-k_mgdtYi12KawX3mBKbqWc8HBoA";
  String proxy = "";
  models.ApiType _selectedApiType = models.ApiType.gemini;

  ConversationProvider() {
    _conversations.add(models.Conversation(
      messages: [],
      title: "New Chat",
    ));
    try {
      Gemini.init(apiKey: _yourGeminiApiKey);
    } catch (e) {
      print('Error initializing Gemini: $e');
    }
  }

  // Getters
  List<models.Conversation> get conversations => _conversations;
  int get currentConversationIndex => _currentConversationIndex;
  models.Conversation get currentConversation =>
      _conversations[_currentConversationIndex];
  String get currentConversationTitle => currentConversation.title;
  int get currentConversationLength => currentConversation.messages.length;
  List<models.Message> get currentConversationMessages =>
      currentConversation.messages;
  String get yourChatGptApiKey => _yourChatGptApiKey;
  String get yourGeminiApiKey => _yourGeminiApiKey;
  String get yourProxy => proxy;
  models.ApiType get selectedApiType => _selectedApiType;

  // API Key Management
  void updateApiKeys(String chatGptKey, String geminiKey) {
    _yourChatGptApiKey = chatGptKey;
    _yourGeminiApiKey = geminiKey;

    if (geminiKey.isNotEmpty &&
        geminiKey != "YOUR_API_KEY" &&
        geminiKey.startsWith("AI")) {
      try {
        Gemini.init(apiKey: geminiKey);
      } catch (e) {
        print('Error initializing Gemini: $e');
      }
    }
    notifyListeners();
  }

  void setSelectedApiType(models.ApiType type) {
    _selectedApiType = type;
    notifyListeners();
  }

  models.ApiType get activeApiType {
    if (_selectedApiType == models.ApiType.gemini &&
        _yourGeminiApiKey.isNotEmpty &&
        _yourGeminiApiKey != "YOUR_API_KEY" &&
        _yourGeminiApiKey.startsWith("AI")) {
      return models.ApiType.gemini;
    }
    return models.ApiType.chatgpt;
  }

  String get activeApiKey {
    return activeApiType == models.ApiType.gemini
        ? _yourGeminiApiKey
        : _yourChatGptApiKey;
  }

  models.Sender get activeAiSender {
    return models.Sender(
      id: 'System',
      name: activeApiType == models.ApiType.gemini ? 'Gemini' : 'ChatGPT',
      avatarAssetPath: activeApiType == models.ApiType.gemini
          ? 'resources/avatars/gemini.png'
          : 'resources/avatars/ChatGPT_logo.png',
    );
  }

  // Message Management
  void addMessage(models.Message message) {
    currentConversation.messages.add(message);
    notifyListeners();
  }

  // Conversation Management
  void setCurrentConversation(int index) {
    _currentConversationIndex = index;
    notifyListeners();
  }

  void addNewConversation() {
    _conversations.add(models.Conversation(
      messages: [],
      title: "New Chat",
    ));
    _currentConversationIndex = _conversations.length - 1;
    notifyListeners();
  }

  void removeCurrentConversation() {
    _conversations.removeAt(_currentConversationIndex);
    _currentConversationIndex = _conversations.length - 1;
    if (_conversations.isEmpty) {
      addNewConversation();
    }
    notifyListeners();
  }

  void renameConversation(int index, String newTitle) {
    _conversations[index] = models.Conversation(
      title: newTitle,
      messages: _conversations[index].messages,
    );
    notifyListeners();
  }

  void clearCurrentConversation() {
    _conversations[_currentConversationIndex] = models.Conversation(
      title: currentConversation.title,
      messages: [],
    );
    notifyListeners();
  }

  void updateProxy(String newProxy) {
    proxy = newProxy;
    notifyListeners();
  }
}

const String model = "gpt-3.5-turbo";

final models.Sender systemSender = models.Sender(
    id: 'System',
    name: 'System',
    avatarAssetPath: 'resources/avatars/gemini.png');
final models.Sender userSender = models.Sender(
    id: 'User', name: 'User', avatarAssetPath: 'resources/avatars/person.png');
