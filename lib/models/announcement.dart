class Announcement {
  final String id;
  final String title;
  final String message;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
  });

  // Convert from Supabase JSON
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id']?.toString() ?? 'unknown_id',
      title: json['title']?.toString() ?? 'No Title',
      message: json['body']?.toString() ?? 'No message provided.',
      authorName: 'Coordinator', // Hardcoded since created_by is a UUID
      authorRole: 'Coordinator',
      createdAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'].toString())
          : DateTime.now(),
    );
  }

  // Convert to JSON for offline caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': message,
      'published_at': createdAt.toIso8601String(),
    };
  }
}