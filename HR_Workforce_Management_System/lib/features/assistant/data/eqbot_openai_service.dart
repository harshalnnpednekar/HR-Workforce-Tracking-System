import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'eqbot_models.dart';

class EqBotOpenAiService {
  EqBotOpenAiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  Future<String> getAssistantReply({
    required EqBotUserContext contextData,
    required List<EqBotChatMessage> conversation,
  }) async {
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');
    const model = String.fromEnvironment(
      'OPENAI_MODEL',
      defaultValue: 'gpt-4o-mini',
    );

    if (apiKey.trim().isEmpty) {
      throw Exception(
        'OPENAI_API_KEY is missing. Run with --dart-define=OPENAI_API_KEY=your_key',
      );
    }

    final trimmedConversation = conversation.length > 14
        ? conversation.sublist(conversation.length - 14)
        : conversation;

    final body = jsonEncode({
      'model': model,
      'temperature': 0.2,
      'messages': [
        {'role': 'system', 'content': contextData.systemPrompt},
        ...trimmedConversation.map((msg) {
          return {
            'role': msg.role == EqBotRole.user ? 'user' : 'assistant',
            'content': msg.text,
          };
        }),
      ],
    });

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw Exception('EqBot request timed out. Please try again.');
    }

    final decoded = _tryDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage =
          ((decoded?['error'] as Map<String, dynamic>?)?['message'] as String?)
              ?.trim();
      throw Exception(
        errorMessage?.isNotEmpty == true
            ? errorMessage
            : 'EqBot request failed with ${response.statusCode}.',
      );
    }

    final choices = decoded?['choices'];
    if (choices is! List || choices.isEmpty) {
      throw Exception('EqBot returned an empty response.');
    }

    final message = choices.first['message'];
    if (message is! Map<String, dynamic>) {
      throw Exception('EqBot response format was not recognized.');
    }

    final content = message['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }
    if (content is List) {
      final text = content
          .map((part) {
            if (part is Map<String, dynamic> && part['text'] is String) {
              return (part['text'] as String).trim();
            }
            return '';
          })
          .where((piece) => piece.isNotEmpty)
          .join('\n');
      if (text.isNotEmpty) {
        return text;
      }
    }

    throw Exception('EqBot returned no readable text.');
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
