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
  final String? phoneNumber;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'age': age,
      'school': school,
      'gender': gender,
      'budget': budget,
      'compatibilityScore': compatibilityScore,
      'commonInterests': commonInterests,
      'preferences': preferences,
      'phoneNumber': phoneNumber,
    };
  }

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
    this.phoneNumber,
  });

  factory RoommateMatchModel.fromJson(Map<String, dynamic> json) {
    // Handle commonInterests from both camelCase (local) and the RPC JSONB array
    final dynamic common =
        json['commonInterests'] ??
        json['common_interests'] ??
        json['common_interests_json'];
    final dynamic prefs = json['preferences'] ?? json['prefs'];

    // Parse common interests: can be a JSONB array (List) or null
    List<String> parsedInterests = const <String>[];
    if (common is List) {
      parsedInterests = common.map((e) => e.toString()).toList();
    }

    // Parse preferences: can be a JSONB object (Map), a List, or null
    Map<String, String> parsedPrefs = <String, String>{};
    if (prefs is Map) {
      parsedPrefs = Map<String, String>.fromEntries(
        prefs.entries.map(
          (e) => MapEntry(e.key.toString(), e.value?.toString() ?? ''),
        ),
      );
    }

    return RoommateMatchModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      profileImage:
          (json['profileImage'] ??
                  json['profile_image'] ??
                  json['match_profile_image'] ??
                  '')
              .toString(),
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
          (json['compatibilityScore'] ??
                      json['compatibility_score'] ??
                      json['compat_score'])
                  is int
              ? (json['compatibilityScore'] ??
                      json['compatibility_score'] ??
                      json['compat_score'])
                  as int
              : int.tryParse(
                    (json['compatibilityScore'] ??
                                json['compatibility_score'] ??
                                json['compat_score'])
                            ?.toString() ??
                        '',
                  ) ??
                  0,
      commonInterests: parsedInterests,
      preferences: parsedPrefs,
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
    );
  }
}
