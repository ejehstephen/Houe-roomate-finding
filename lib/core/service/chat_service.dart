class ChatService {
  // Get or create chat between two users (placeholder)
  Future<String> getOrCreateChat(String otherUserId) async {
    // TODO: Replace with POST /api/chats (idempotent)
    return 'demo-chat-id';
  }

  // Get messages for a chat (placeholder)
  Future<List<ChatMessage>> getMessages(String chatId) async {
    // TODO: Replace with GET /api/chats/{chatId}/messages
    return [];
  }

  // Send a message (placeholder)
  Future<ChatMessage> sendMessage(String chatId, String content) async {
    // TODO: Replace with POST /api/chats/{chatId}/messages
    return ChatMessage(
      id: 'msg-1',
      content: content,
      senderId: 'demo-user',
      senderName: 'Demo User',
      timestamp: DateTime.now(),
      isMe: true,
    );
  }

  // Listen to new messages (placeholder)
  Stream<ChatMessage> listenToMessages(String chatId) async* {
    // TODO: Replace with WebSocket/SSE client
  }
}

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.isMe,
  });
}
