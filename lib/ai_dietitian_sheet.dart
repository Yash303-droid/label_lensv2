import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/user_profile.dart';

// A simple data class for chat messages
class ChatMessage {
  final bool isUser;
  final String message;

  ChatMessage({required this.isUser, required this.message});
}

class AiDietitianSheet extends StatefulWidget {
  final String productName;
  final List<String> ingredients;
  final UserProfile userProfile;
  // IMPORTANT: You must get your own API key from Google AI Studio.
  final String apiKey;

  const AiDietitianSheet({
    Key? key,
    required this.productName,
    required this.ingredients,
    required this.userProfile,
    required this.apiKey,
  }) : super(key: key);

  @override
  _AiDietitianSheetState createState() => _AiDietitianSheetState();
}

class _AiDietitianSheetState extends State<AiDietitianSheet> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Design System Colors
  static const Color cardBg = Color(0xFF1E293B);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: widget.apiKey,
      systemInstruction: _buildSystemInstruction(),
    );
    _chat = _model.startChat();
  }

  Content _buildSystemInstruction() {
    // Using a structured prompt for clarity and better instruction following.
    final systemPrompt = '''
# Persona
You are an expert AI dietitian. Your tone is knowledgeable, safe, and concise. Do not mention that you are an AI.

# Context
- **Product Name:** ${widget.productName}
- **Product Ingredients:** ${widget.ingredients.isEmpty ? 'Not available' : widget.ingredients.join(', ')}
- **User Health Profile:**
  - Diet: ${widget.userProfile.diet ?? 'Not specified'}
  - Allergies: ${widget.userProfile.allergies?.isEmpty ?? true ? 'None specified' : widget.userProfile.allergies!.join(', ')}
  - Health Issues: ${widget.userProfile.healthIssues?.isEmpty ?? true ? 'None specified' : widget.userProfile.healthIssues!.join(', ')}

# Task
Analyze the user's question based on the provided product context and user health profile. Provide safe, clear, and brief advice.
''';

    return Content.text(systemPrompt);
  }

  void _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(isUser: true, message: question));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await _chat.sendMessage(Content.text(question));
      final text = response.text;

      if (text == null) {
        _showError('No response from API.');
        return;
      }

      setState(() {
        _messages.add(ChatMessage(isUser: false, message: text));
        _isLoading = false;
      });
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
       _messages.add(ChatMessage(isUser: false, message: 'Error: $message'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Scrollable Message Area
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  final message = _messages[index];
                  return _ChatMessageBubble(
                    message: message.message,
                    isUser: message.isUser,
                  );
                },
              ),
            ),
            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.slate900,
        border: Border(top: BorderSide(color: textSecondary, width: 0.2)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Ask about this product...',
                    hintStyle: TextStyle(color: textSecondary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.emerald400,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: AppColors.slate900),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _ChatMessageBubble({required this.message, required this.isUser});

  static const Color userBubble = Color(0xFF064E3B);
  static const Color aiBubble = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isUser ? userBubble : aiBubble,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald400),
            ),
            const SizedBox(width: 8),
            Text(
              'AI Dietitian is typing...',
              style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
