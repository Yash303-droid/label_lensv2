class UserProfile {
  final String? id;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final String? diet;
  final List<String>? allergies;
  final List<String>? healthIssues;
  final List<String>? likes;
  final List<String>? dislikes;

  UserProfile({
    this.id,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.diet,
    this.allergies,
    this.healthIssues,
    this.likes,
    this.dislikes,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String parsedName;
    if (json['name'] is String && json['name'].isNotEmpty) {
      parsedName = json['name'];
    } else if (json['name'] is List && (json['name'] as List).isNotEmpty) {
      parsedName = (json['name'] as List).join(' ');
    } else {
      parsedName = 'User';
    }

    return UserProfile(
      id: json['_id'] ?? json['id'],
      name: parsedName,
      email: json['email'] ?? '',
      age: json['age'],
      gender: json['gender'],
      diet: json['diet'],
      allergies:
          json['allergies'] != null ? List<String>.from(json['allergies']) : null,
      healthIssues: json['healthIssues'] != null
          ? List<String>.from(json['healthIssues'])
          : null,
      likes: json['likes'] != null ? List<String>.from(json['likes']) : null,
      dislikes: json['avoid'] != null ? List<String>.from(json['avoid']) : null,
    );
  }
}