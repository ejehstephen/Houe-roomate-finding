class RoommateMatchModel {
  final String id;
  final String name;
  final String profileImage;
  final int age;
  final String school;
  final String gender;
  final double budget;
  final int compatibilityScore;
  final List<String> commonInterests;
  final Map<String, String> preferences;

  RoommateMatchModel({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.age,
    required this.school,
    required this.gender,
    required this.budget,
    required this.compatibilityScore,
    required this.commonInterests,
    required this.preferences,
  });

  factory RoommateMatchModel.fromJson(Map<String, dynamic> json) {
    return RoommateMatchModel(
      id: json['id'],
      name: json['name'],
      profileImage: json['profileImage'],
      age: json['age'],
      school: json['school'],
      gender: json['gender'],
      budget: json['budget'].toDouble(),
      compatibilityScore: json['compatibilityScore'],
      commonInterests: List<String>.from(json['commonInterests']),
      preferences: Map<String, String>.from(json['preferences']),
    );
  }
}
