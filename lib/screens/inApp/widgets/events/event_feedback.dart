class EventFeedback {
  final String email;
  final bool completed;

  // Feedback-specific fields
  final int stars; // 1 to 5
  final String comment;
  final bool wasOrganizedWell;
  final bool wouldRecommend;
  final bool wantsToBeContacted;

  EventFeedback({
    required this.email,
    required this.completed,
    this.stars = 0,
    this.comment = '',
    this.wasOrganizedWell = false,
    this.wouldRecommend = false,
    this.wantsToBeContacted = false,
  });

  factory EventFeedback.fromFirestore(Map<String, dynamic> data) {
    return EventFeedback(
      email: data['email'] ?? '',
      completed: data['completed'] ?? false,
      stars: data['stars'] ?? 0,
      comment: data['comment'] ?? '',
      wasOrganizedWell: data['wasOrganizedWell'] ?? false,
      wouldRecommend: data['wouldRecommend'] ?? false,
      wantsToBeContacted: data['wantsToBeContacted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'completed': completed,
      'stars': stars,
      'comment': comment,
      'wasOrganizedWell': wasOrganizedWell,
      'wouldRecommend': wouldRecommend,
      'wantsToBeContacted': wantsToBeContacted,
    };
  }
}
