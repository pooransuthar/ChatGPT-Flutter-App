import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'conversation_provider.dart';
import 'models.dart';

void showProxyDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String newProxy = 'your proxy';
      return AlertDialog(
        title: const Text('Proxy Setting'),
        content: TextField(
          decoration: InputDecoration(
            hintText: Provider.of<ConversationProvider>(context).yourProxy,
          ),
          onChanged: (value) {
            newProxy = value;
          },
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xff55bb8e),
              ),
            ),
            onPressed: () {
              if (newProxy == '') {
                Navigator.pop(context);
                return;
              }
              Provider.of<ConversationProvider>(context, listen: false)
                  .updateProxy(newProxy);
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

void showApiSettingsDialog(BuildContext context) {
  final provider = Provider.of<ConversationProvider>(context, listen: false);
  final chatGptController =
      TextEditingController(text: provider.yourChatGptApiKey);
  final geminiController =
      TextEditingController(text: provider.yourGeminiApiKey);
  final selectedApiType = provider.selectedApiType;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('API Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gemini API Key (Primary)'),
            TextField(
              controller: geminiController,
              decoration: const InputDecoration(
                hintText: 'Enter your Gemini API key',
              ),
            ),
            const SizedBox(height: 16),
            const Text('ChatGPT API Key'),
            TextField(
              controller: chatGptController,
              decoration: const InputDecoration(
                hintText: 'Enter your ChatGPT API key',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              geminiController.clear();
              chatGptController.clear();
              provider.updateApiKeys('', '');
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.updateApiKeys(
                chatGptController.text,
                geminiController.text,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
