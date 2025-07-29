class ChatMessage {
  final String message;
  final String? audioUrl;
  final bool isMe;
  final String time;
  final String avatar;
  final String? imageUrl;

  ChatMessage({
    required this.message,
    this.audioUrl,
    required this.isMe,
    required this.time,
    required this.avatar,
      this.imageUrl,
  });
}
