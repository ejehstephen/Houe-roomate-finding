import 'package:camp_nest/core/utility/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get or create chat between two users
  Future<String> getOrCreateChat(String otherUserId) async {
    try {
      final currentUserId = _client.auth.currentUser!.id;

      // Try to find existing chat
      final existingChat =
          await _client
              .from('chats')
              .select()
              .or(
                'and(user1_id.eq.$currentUserId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$currentUserId)',
              )
              .maybeSingle();

      if (existingChat != null) {
        return existingChat['id'];
      }

      // Create new chat
      final newChat =
          await _client
              .from('chats')
              .insert({'user1_id': currentUserId, 'user2_id': otherUserId})
              .select()
              .single();

      return newChat['id'];
    } catch (e) {
      throw Exception('Failed to get or create chat: ${e.toString()}');
    }
  }

  // Get messages for a chat
  Future<List<ChatMessage>> getMessages(String chatId) async {
    try {
      final response = await _client
          .from('messages')
          .select('''
            *,
            user_profiles!messages_sender_id_fkey(name)
          ''')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      return response.map<ChatMessage>((json) {
        return ChatMessage(
          id: json['id'],
          content: json['content'],
          senderId: json['sender_id'],
          senderName: json['user_profiles']['name'],
          timestamp: DateTime.parse(json['created_at']),
          isMe: json['sender_id'] == _client.auth.currentUser!.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get messages: ${e.toString()}');
    }
  }

  // Send a message
  Future<ChatMessage> sendMessage(String chatId, String content) async {
    try {
      final currentUserId = _client.auth.currentUser!.id;

      final response =
          await _client
              .from('messages')
              .insert({
                'chat_id': chatId,
                'sender_id': currentUserId,
                'content': content,
              })
              .select('''
            *,
            user_profiles!messages_sender_id_fkey(name)
          ''')
              .single();

      return ChatMessage(
        id: response['id'],
        content: response['content'],
        senderId: response['sender_id'],
        senderName: response['user_profiles']['name'],
        timestamp: DateTime.parse(response['created_at']),
        isMe: true,
      );
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // Listen to new messages in a chat
  Stream<ChatMessage> listenToMessages(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((data) {
          final json = data.last;
          return ChatMessage(
            id: json['id'],
            content: json['content'],
            senderId: json['sender_id'],
            senderName: '', // Would need to fetch separately
            timestamp: DateTime.parse(json['created_at']),
            isMe: json['sender_id'] == _client.auth.currentUser!.id,
          );
        });
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
