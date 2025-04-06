import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'models.dart' as models;
import 'conversation_provider.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<PlatformFile> _selectedFiles = [];
  final Gemini _gemini = Gemini.instance;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<models.Message?> _sendMessage(
      List<Map<String, dynamic>> messages) async {
    final provider = Provider.of<ConversationProvider>(context, listen: false);
    final apiType = provider.activeApiType;
    final apiKey = provider.activeApiKey;

    if (apiKey.isEmpty || apiKey == "YOUR_API_KEY") {
      return models.Message(
          content: "Please set your API key in the settings",
          senderId: models.systemSender.id);
    }

    if (apiType == models.ApiType.gemini) {
      if (!apiKey.startsWith("AI")) {
        return models.Message(
            content: "Invalid Gemini API key format",
            senderId: models.systemSender.id);
      }

      try {
        final lastMessage = messages.last['content'];
        final lastMessageAttachments =
            messages.last['attachments'] as List<PlatformFile>?;

        if (lastMessageAttachments != null &&
            lastMessageAttachments.isNotEmpty) {
          final imageFiles = lastMessageAttachments
              .where((file) =>
                  file.bytes != null &&
                  (file.extension?.toLowerCase() == 'jpg' ||
                      file.extension?.toLowerCase() == 'jpeg' ||
                      file.extension?.toLowerCase() == 'png'))
              .toList();

          if (imageFiles.isNotEmpty) {
            final response = await _gemini.textAndImage(
              text: lastMessage,
              images: imageFiles.map((file) => file.bytes!).toList(),
            );

            if (response?.output != null) {
              return models.Message(
                  content: response!.output!, senderId: models.systemSender.id);
            }
          }
        }

        final response = await _gemini.text(lastMessage);
        if (response?.output != null) {
          return models.Message(
              content: response!.output!, senderId: models.systemSender.id);
        }

        return models.Message(
            content: "No response from Gemini API",
            senderId: models.systemSender.id);
      } catch (e) {
        return models.Message(
            content: "Error: ${e.toString()}",
            senderId: models.systemSender.id);
      }
    } else {
      if (!apiKey.startsWith("sk-")) {
        return models.Message(
            content: "Invalid ChatGPT API key format",
            senderId: models.systemSender.id);
      }

      final url = Uri.parse(models.chatGptEndpoint);
      final formattedMessages = messages
          .map((msg) => {
                'role': msg['senderId'] == models.userSender.id
                    ? 'user'
                    : 'assistant',
                'content': msg['content'],
              })
          .toList();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': models.gptModel,
          'messages': formattedMessages,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return models.Message(
            content: data['choices'][0]['message']['content'],
            senderId: models.systemSender.id);
      } else {
        return models.Message(
            content: "Error: ${response.statusCode} - ${response.body}",
            senderId: models.systemSender.id);
      }
    }
  }

  void _scrollToLastMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendMessageAndAddToChat() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty || _selectedFiles.isNotEmpty) {
      final attachments = List<PlatformFile>.from(_selectedFiles);

      final userMessage = models.Message(
        senderId: models.userSender.id,
        content: text,
        attachments: attachments,
      );

      setState(() {
        Provider.of<ConversationProvider>(context, listen: false)
            .addMessage(userMessage);
        _textController.clear();
        _selectedFiles.clear();
      });

      _scrollToLastMessage();

      try {
        final assistantMessage = await _sendMessage([
          {
            'senderId': userMessage.senderId,
            'content': userMessage.content,
            'attachments': userMessage.attachments,
          }
        ]);

        if (assistantMessage != null) {
          setState(() {
            Provider.of<ConversationProvider>(context, listen: false)
                .addMessage(assistantMessage);
          });
          _scrollToLastMessage();
        }
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _removeAllAttachments() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Consumer<ConversationProvider>(
                builder: (context, conversationProvider, child) {
                  if (conversationProvider.currentConversationLength == 0) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.commentDots,
                            size: 64,
                            color: Color(0xff55bb8e),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start a new conversation',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontFamily: 'din-regular',
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: conversationProvider.currentConversationLength,
                    itemBuilder: (context, index) {
                      final message = conversationProvider
                          .currentConversation.messages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment:
                              message.senderId == models.userSender.id
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.senderId != models.userSender.id)
                                  CircleAvatar(
                                    backgroundImage: AssetImage(
                                        Provider.of<ConversationProvider>(
                                                context,
                                                listen: false)
                                            .activeAiSender
                                            .avatarAssetPath),
                                    radius: 16.0,
                                  )
                                else
                                  const SizedBox(width: 24.0),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        message.senderId == models.userSender.id
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                    children: [
                                      if (message.content.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0, horizontal: 16.0),
                                          decoration: BoxDecoration(
                                            color: message.senderId ==
                                                    models.userSender.id
                                                ? const Color.fromARGB(
                                                    255, 56, 119, 186)
                                                : const Color.fromARGB(
                                                    255, 233, 235, 247),
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            message.content,
                                            style: TextStyle(
                                              color: message.senderId ==
                                                      models.userSender.id
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      if (message.attachments != null &&
                                          message.attachments!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Wrap(
                                            spacing: 8.0,
                                            runSpacing: 8.0,
                                            children: message.attachments!
                                                .map((file) {
                                              if (file.bytes != null) {
                                                return Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    image: DecorationImage(
                                                      image: MemoryImage(
                                                          file.bytes!),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.insert_drive_file,
                                                      color: Colors.grey[700],
                                                    ),
                                                    const SizedBox(width: 4.0),
                                                    Text(
                                                      file.name,
                                                      style: TextStyle(
                                                          color:
                                                              Colors.grey[700]),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                if (message.senderId == models.userSender.id)
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: AssetImage(
                                            models.userSender.avatarAssetPath),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 24.0),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_selectedFiles.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedFiles.length} file${_selectedFiles.length > 1 ? 's' : ''} selected',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _removeAllAttachments,
                          child: const Text('Clear all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              children: [
                                if (file.bytes != null)
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: MemoryImage(file.bytes!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _removeAttachment(index),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(32.0),
              ),
              margin:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              padding:
                  const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.paperclip, size: 20),
                    onPressed: _pickFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration.collapsed(
                          hintText: 'Type your message...'),
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 18),
                    onPressed: _sendMessageAndAddToChat,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
