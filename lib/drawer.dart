import 'package:flutter/material.dart';
import 'package:flutter_chat/models.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'conversation_provider.dart';
import 'models.dart' as models;
import 'secrets.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  Provider.of<ConversationProvider>(context, listen: false)
                      .addNewConversation();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // border: Border.all(color: Color(Colors.grey[300]?.value ?? 0)),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    // left align
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      FaIcon(FontAwesomeIcons.plus,
                          color: Colors.grey[800], size: 16.0),
                      const SizedBox(width: 15.0),
                      const Text(
                        'New Chat',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontFamily: 'din-regular',
                          // fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<ConversationProvider>(
                builder: (context, conversationProvider, child) {
                  return ListView.builder(
                    itemCount: conversationProvider.conversations.length,
                    itemBuilder: (BuildContext context, int index) {
                      Conversation conversation =
                          conversationProvider.conversations[index];
                      return Dismissible(
                        key: UniqueKey(),
                        child: GestureDetector(
                          onTap: () {
                            conversationProvider.setCurrentConversation(index);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: conversationProvider
                                          .currentConversationIndex ==
                                      index
                                  ? const Color(0xff55bb8e)
                                  : Colors.white,
                              // border: Border.all(color: Color(Colors.grey[200]?.value ?? 0)),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // conversation icon
                                FaIcon(
                                  FontAwesomeIcons.message,
                                  color: conversationProvider
                                              .currentConversationIndex ==
                                          index
                                      ? Colors.white
                                      : Colors.grey[700],
                                  size: 16.0,
                                ),
                                const SizedBox(width: 15.0),
                                Text(
                                  conversation.title,
                                  style: TextStyle(
                                    // fontWeight: FontWeight.bold,
                                    color: conversationProvider
                                                .currentConversationIndex ==
                                            index
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontFamily: 'din-regular',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select AI Model',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'din-regular',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<ConversationProvider>(
                    builder: (context, provider, child) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<models.ApiType>(
                              title: Row(
                                children: [
                                  Image.asset(
                                    'resources/avatars/gemini.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Gemini',
                                    style: TextStyle(
                                      fontFamily: 'din-regular',
                                    ),
                                  ),
                                ],
                              ),
                              value: models.ApiType.gemini,
                              groupValue: provider.selectedApiType,
                              onChanged: (models.ApiType? value) {
                                if (value != null) {
                                  provider.setSelectedApiType(value);
                                }
                              },
                            ),
                            const Divider(height: 1),
                            RadioListTile<models.ApiType>(
                              title: Row(
                                children: [
                                  Image.asset(
                                    'resources/avatars/ChatGPT_logo.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'ChatGPT',
                                    style: TextStyle(
                                      fontFamily: 'din-regular',
                                    ),
                                  ),
                                ],
                              ),
                              value: models.ApiType.chatgpt,
                              groupValue: provider.selectedApiType,
                              onChanged: (models.ApiType? value) {
                                if (value != null) {
                                  provider.setSelectedApiType(value);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    showApiSettingsDialog(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 8.0),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.pen,
                            color: Colors.grey[700], size: 16.0),
                        const SizedBox(width: 15.0),
                        Text(
                          'API Setting',
                          style: TextStyle(
                            fontFamily: 'din-regular',
                            color: Colors.grey[700],
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    showProxyDialog(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 8.0),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.gear,
                            color: Colors.grey[700], size: 16.0),
                        const SizedBox(width: 15.0),
                        Text(
                          'Proxy Setting',
                          style: TextStyle(
                            fontFamily: 'din-regular',
                            color: Colors.grey[700],
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }
}

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<ConversationProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xff55bb8e),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure your API keys and preferences',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // AI Model Selection
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select AI Model',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<models.ApiType>(
                            title: Row(
                              children: [
                                Image.asset(
                                  'resources/avatars/gemini.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text('Gemini'),
                              ],
                            ),
                            value: models.ApiType.gemini,
                            groupValue: provider.selectedApiType,
                            onChanged: (models.ApiType? value) {
                              if (value != null) {
                                provider.setSelectedApiType(value);
                              }
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<models.ApiType>(
                            title: Row(
                              children: [
                                Image.asset(
                                  'resources/avatars/ChatGPT_logo.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text('ChatGPT'),
                              ],
                            ),
                            value: models.ApiType.chatgpt,
                            groupValue: provider.selectedApiType,
                            onChanged: (models.ApiType? value) {
                              if (value != null) {
                                provider.setSelectedApiType(value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // API Keys Section
              // ... existing code ...
            ],
          );
        },
      ),
    );
  }
}
