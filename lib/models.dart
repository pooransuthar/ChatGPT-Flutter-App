// Model classes for the chat app

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// conversations include multiple messages
class Conversation {
  final String title;
  final List<Message> messages;

  Conversation({
    required this.title,
    required this.messages,
  });
}

// Sender should have name and avatar
class Sender {
  final String id;
  final String name;
  final String avatarAssetPath;

  const Sender({
    required this.id,
    required this.name,
    required this.avatarAssetPath,
  });
}

// message should have role, content, timestamp
class Message {
  final String senderId;
  final String content;
  final List<PlatformFile>? attachments;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.content,
    this.attachments,
  }) : timestamp = DateTime.now();
}

enum ApiType { chatgpt, gemini }

// API Models
const String gptModel = "gpt-3.5-turbo";
const String geminiModel = "gemini-pro";

// API Endpoints
const String chatGptEndpoint = "https://api.openai.com/v1/chat/completions";
const String geminiEndpoint =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-vision-latest:generateContent";

final Sender systemSender = Sender(
    id: 'System',
    name: 'System',
    avatarAssetPath: 'resources/avatars/gemini.png');
final Sender userSender = Sender(
    id: 'User', name: 'User', avatarAssetPath: 'resources/avatars/person.png');
