class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String school;
  final int age;
  final String gender;
  final List<String> preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.school,
    required this.age,
    required this.gender,
    required this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImage: json['profile_image'],
      school: json['school'],
      age: json['age'],
      gender: json['gender'],
      preferences: List<String>.from(json['preferences'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image': profileImage,
      'school': school,
      'age': age,
      'gender': gender,
      'preferences': preferences,
    };
  }
}
