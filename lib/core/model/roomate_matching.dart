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
    final dynamic common = json['commonInterests'];
    final dynamic prefs = json['preferences'];

    return RoommateMatchModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      profileImage: json['profileImage']?.toString() ?? '',
      age:
          json['age'] is int
              ? json['age'] as int
              : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      school: json['school']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      budget:
          json['budget'] is num
              ? (json['budget'] as num).toDouble()
              : double.tryParse(json['budget']?.toString() ?? '') ?? 0.0,
      compatibilityScore:
          json['compatibilityScore'] is int
              ? json['compatibilityScore'] as int
              : int.tryParse(json['compatibilityScore']?.toString() ?? '') ?? 0,
      commonInterests:
          (common is List)
              ? common.map((e) => e.toString()).toList()
              : const <String>[],
      preferences:
          (prefs is Map)
              ? Map<String, String>.fromEntries(
                (prefs).entries.map(
                  (e) => MapEntry(e.key.toString(), e.value?.toString() ?? ''),
                ),
              )
              : <String, String>{},
    );
  }
}
