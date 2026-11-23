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
      id: json['id'],
      title: json['title'],
      message: json['body'],
      authorName: json['created_by'],
      authorRole: json['author_role'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Convert to JSON for offline caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'author_name': authorName,
      'author_role': authorRole,
      'created_at': createdAt.toIso8601String(),
    };
  }
}