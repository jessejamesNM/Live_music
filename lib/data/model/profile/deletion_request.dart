class DeletionRequest {
  final String userId;
  final String reason;
  final String currentDay;
  final String eliminationDay;

  DeletionRequest({
    required this.userId,
    required this.reason,
    required this.currentDay,
    required this.eliminationDay,
  });

  DeletionRequest copyWith({
    String? userId,
    String? reason,
    String? currentDay,
    String? eliminationDay,
  }) {
    return DeletionRequest(
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      currentDay: currentDay ?? this.currentDay,
      eliminationDay: eliminationDay ?? this.eliminationDay,
    );
  }
}