class UserFeedback {
  final String userId; // ID of the user providing feedback
  final String message; // Feedback message
  final DateTime timestamp; // When the feedback was given

  UserFeedback({required this.userId, required this.message, required this.timestamp});

  // Convert a Feedback object to a Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
