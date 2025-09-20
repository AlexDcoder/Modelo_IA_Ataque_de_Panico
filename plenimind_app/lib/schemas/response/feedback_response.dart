class FeedbackInput {
  final String uid;
  final Map<String, double> features;
  final int userFeedback;

  FeedbackInput({
    required this.uid,
    required this.features,
    required this.userFeedback,
  });

  factory FeedbackInput.fromJson(Map<String, dynamic> json) {
    final featuresMap = json['features'] as Map?;
    return FeedbackInput(
      uid: json['uid']?.toString() ?? '',
      features:
          featuresMap != null
              ? featuresMap.map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              )
              : <String, double>{},
      userFeedback: json['user_feedback'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'features': features,
    'user_feedback': userFeedback,
  };
}
