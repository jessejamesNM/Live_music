import '../../sources/local/internal_data_base.dart';

extension ConversationCopyWith on Conversation {
  Conversation copyWith({
    String? nickname,
    String? currentUserId,
    String? otherUserId,
    String? lastMessage,
    int? timestamp,
    String? profileImage,
    String? name,
    int? messagesUnread,
    String? conversationName,
    String? formattedTimestamp,
    bool? artist,
  }) {
    return Conversation(
      nickname: nickname ?? this.nickname,
      currentUserId: currentUserId ?? this.currentUserId,
      otherUserId: otherUserId ?? this.otherUserId,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      profileImage: profileImage ?? this.profileImage,
      name: name ?? this.name,
      messagesUnread: messagesUnread ?? this.messagesUnread,
      conversationName: conversationName ?? this.conversationName,
      formattedTimestamp: formattedTimestamp ?? this.formattedTimestamp,
      artist: artist ?? this.artist,
    );
  }
}
