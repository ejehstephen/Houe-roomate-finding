class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String school;
  final int age;
  final String gender;
  final String? phoneNumber;
  final List<String> preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.school,
    required this.age,
    required this.gender,
    this.phoneNumber,
    required this.preferences,
  });

  // ✅ Add copyWith method
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    String? school,
    int? age,
    String? gender,
    String? phoneNumber,
    List<String>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      school: school ?? this.school,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferences: preferences ?? this.preferences,
    );
  }

  // ✅ JSON factory (for backend and Flutter interop)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage:
          json['profileImage'] ??
          json['profile_image'] ??
          json['profileImageUrl'] ??
          json['avatar'] ??
          json['avatarUrl'] ??
          json['image'] ??
          json['imageUrl'],
      school: json['school'] ?? '',
      age:
          json['age'] is int
              ? json['age']
              : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      preferences:
          (json['preferences'] is List)
              ? List<String>.from(json['preferences'])
              : [],
    );
  }

  // ✅ JSON serializer (Strictly matches DB Schema)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image': profileImage,
      'school': school,
      'age': age,
      'gender': gender,
      'phone_number': phoneNumber,
      'preferences': preferences,
    };
  }

  @override
  String toString() {
    return 'UserModel(name: $name, email: $email, id: $id)';
  }
}
