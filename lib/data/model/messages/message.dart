class Message {
  final String id;
  final String currentUserId;
  final String type;
  final String messageText;
  final String senderId;
  final String receiverId;
  final String? url;
  final int timestamp;
  bool messageRead;

  Message({
    this.id = "",
    this.currentUserId = "",
    this.type = "",
    this.messageText = "",
    this.senderId = "",
    this.receiverId = "",
    this.url,
    int? timestamp,
    this.messageRead = false,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  // Método para copiar el mensaje con nuevos valores (similar a copy() en Kotlin)
  Message copyWith({
    String? id,
    String? currentUserId,
    String? type,
    String? messageText,
    String? senderId,
    String? receiverId,
    String? url,
    int? timestamp,
    bool? messageRead,
  }) {
    return Message(
      id: id ?? this.id,
      currentUserId: currentUserId ?? this.currentUserId,
      type: type ?? this.type,
      messageText: messageText ?? this.messageText,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      url: url ?? this.url,
      timestamp: timestamp ?? this.timestamp,
      messageRead: messageRead ?? this.messageRead,
    );
  }

  // Para imprimir el objeto como string (similar a toString() en Kotlin data class)
  @override
  String toString() {
    return 'Message(id: $id, currentUserId: $currentUserId, type: $type, '
        'messageText: $messageText, senderId: $senderId, receiverId: $receiverId, '
        'imageUrl: $url, timestamp: $timestamp, messageRead: $messageRead)';
  }

  // Para comparar objetos (similar a equals() en Kotlin data class)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.currentUserId == currentUserId &&
        other.type == type &&
        other.messageText == messageText &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.url == url &&
        other.timestamp == timestamp &&
        other.messageRead == messageRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        currentUserId.hashCode ^
        type.hashCode ^
        messageText.hashCode ^
        senderId.hashCode ^
        receiverId.hashCode ^
        url.hashCode ^
        timestamp.hashCode ^
        messageRead.hashCode;
  }
}
