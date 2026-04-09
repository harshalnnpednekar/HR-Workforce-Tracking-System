import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../data/eqbot_context_service.dart';
import '../../data/eqbot_models.dart';
import '../../data/eqbot_openai_service.dart';

class EqBotChatSheet extends StatefulWidget {
  const EqBotChatSheet({super.key, required this.contextData});

  final EqBotUserContext contextData;

  static Future<void> open(
    BuildContext context, {
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session unavailable.')),
        );
      }
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    EqBotUserContext contextData;
    try {
      contextData = await EqBotContextService.fetchForUser(userId);
    } on Exception catch (error) {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('EqBot is unavailable: $error')));
      }
      return;
    }

    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return EqBotChatSheet(contextData: contextData);
      },
    );
  }

  @override
  State<EqBotChatSheet> createState() => _EqBotChatSheetState();
}

class _EqBotChatSheetState extends State<EqBotChatSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _openAiService = EqBotOpenAiService();

  final List<EqBotChatMessage> _messages = [];
  bool _isTyping = false;

  static const List<String> _quickReplies = [
    "What's my leave balance?",
    'Why was money deducted?',
    'What are working hours?',
    'When is salary credited?',
  ];

  @override
  void initState() {
    super.initState();
    final name = widget.contextData.employeeName.split(' ').first;
    _messages.add(
      EqBotChatMessage(
        role: EqBotRole.assistant,
        text:
            'Hi $name, I am EqBot. Ask me anything about your payroll, attendance, leaves, or HR policy.',
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _showQuickReplies {
    return !_messages.any((msg) => msg.role == EqBotRole.user);
  }

  Future<void> _sendMessage([String? seededText]) async {
    if (_isTyping) {
      return;
    }

    final messageText = (seededText ?? _inputController.text).trim();
    if (messageText.isEmpty) {
      return;
    }

    _inputController.clear();

    setState(() {
      _messages.add(EqBotChatMessage(role: EqBotRole.user, text: messageText));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await _openAiService.getAssistantReply(
        contextData: widget.contextData,
        conversation: List<EqBotChatMessage>.from(_messages),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(EqBotChatMessage(role: EqBotRole.assistant, text: reply));
        _isTyping = false;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(
          EqBotChatMessage(
            role: EqBotRole.assistant,
            text:
                'I could not process that right now. Please try again.\n\nDetails: $error',
          ),
        );
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height * 0.86;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _EqBotHeader(onClose: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return const _TypingBubble();
                }
                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          if (_showQuickReplies)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickReplies.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _sendMessage(suggestion),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD7DFEA)),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E3B4E),
                    ),
                  );
                }).toList(),
              ),
            ),
          _InputBar(
            controller: _inputController,
            isBusy: _isTyping,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _EqBotHeader extends StatelessWidget {
  const _EqBotHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Color(0xFFE4EAF2))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5D4),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EqBot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF152238),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'HR assistant',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF72839B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final EqBotChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == EqBotRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFFF7A30) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isUser
              ? null
              : Border.all(color: const Color(0xFFDCE4EE), width: 1),
        ),
        child: isUser
            ? Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              )
            : MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Color(0xFF203047),
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  listBullet: const TextStyle(
                    color: Color(0xFF203047),
                    fontSize: 14,
                  ),
                ),
              ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE4EE), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'EqBot is typing...',
              style: TextStyle(
                color: Color(0xFF40556F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isBusy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isBusy;
  final Future<void> Function([String? seededText]) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4EAF2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isBusy,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Ask EqBot...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF7FAFD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCED8E6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCED8E6)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: const Color(0xFFFF7A30),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isBusy ? null : () => onSend(),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
