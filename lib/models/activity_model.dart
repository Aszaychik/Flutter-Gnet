class Activity {
  final int id;
  final int userId;
  final String imageUrl;
  final String title;
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic> user;

  Activity({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.user,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      userId: json['user_id'],
      imageUrl: json['image_url'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'],
    );
  }
}