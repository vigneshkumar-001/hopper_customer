class ChatMessage {
  final String message;
  final String? audioUrl;
  final bool isMe;
  final String time;
  final String avatar;
  final String? imageUrl;
  final bool isUploading; // 👈 add this
  bool isSending;
  final bool isTyping;


  ChatMessage({
    required this.message,
    this.audioUrl,
    required this.isMe,
    required this.time,
    required this.avatar,
      this.imageUrl,
    this.isUploading = false, // default false
      this. isSending = false,
      this. isTyping = false,
  });
}
