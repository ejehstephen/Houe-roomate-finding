class RoomListingModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final List<String> amenities;
  final List<String> rules;
  final String gender; // 'male', 'female', 'any'
  final DateTime availableFrom;
  final bool isActive;

  RoomListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.images,
    required this.ownerId,
    required this.ownerName,
    required this.amenities,
    required this.rules,
    required this.gender,
    required this.availableFrom,
    this.isActive = true,
  });

  factory RoomListingModel.fromJson(Map<String, dynamic> json) {
    return RoomListingModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      location: json['location'],
      images: List<String>.from(json['images'] ?? []),
      ownerId: json['owner_id'],
      ownerName: json['ownerName'] ?? json['owner_name'] ?? 'Unknown',
      amenities: List<String>.from(json['amenities'] ?? []),
      rules: List<String>.from(json['rules'] ?? []),
      gender: json['gender_preference'] ?? 'any',
      availableFrom: DateTime.parse(json['available_from']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'images': images,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'amenities': amenities,
      'rules': rules,
      'gender_preference': gender,
      'available_from': availableFrom.toIso8601String(),
      'is_active': isActive,
    };
  }
}
