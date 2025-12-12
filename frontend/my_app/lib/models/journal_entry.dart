class JournalEntry {
  final int? id;
  final String content;
  final int? moodRating;
  final String? moodTags;
  final int? stressRating;
  final String? emotions;
  final DateTime? timestamp;

  JournalEntry({
    this.id,
    required this.content,
    this.moodRating,
    this.moodTags,
    this.stressRating,
    this.emotions,
    this.timestamp,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      content: json['content'],
      moodRating: json['moodRating'],
      moodTags: json['moodTags'],
      stressRating: json['stressRating'],
      emotions: json['emotions'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'moodRating': moodRating,
      'moodTags': moodTags,
      'stressRating': stressRating,
      'emotions': emotions,
    };
  }
}