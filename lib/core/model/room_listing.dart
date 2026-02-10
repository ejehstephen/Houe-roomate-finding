class RoomListingModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final String? ownerPhone;
  final String? whatsappLink;
  final List<String> amenities;
  final List<String> rules;
  final String gender; // 'male', 'female', 'any'
  final DateTime availableFrom;
  final bool isActive;
  final String school;
  final int reportCount;
  final bool isFeatured;

  RoomListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.images,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhone,
    this.whatsappLink,
    required this.amenities,
    required this.rules,
    required this.gender,
    required this.availableFrom,
    this.isActive = true,
    required this.school,
    this.reportCount = 0,
    this.isFeatured = false,
  });

  factory RoomListingModel.fromJson(Map<String, dynamic> json) {
    return RoomListingModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      location: json['location'],
      images: List<String>.from(json['images'] ?? []),
      ownerId: json['owner_id'] ?? json['ownerId'] ?? '',
      ownerName:
          json['ownerName'] ??
          json['owner_name'] ??
          json['ownerName'] ??
          'Unknown',
      ownerPhone:
          (json['ownerPhone'] ?? json['owner_phone']) is String
              ? (json['ownerPhone'] ?? json['owner_phone']) as String
              : null,
      whatsappLink:
          (json['whatsappLink'] ?? json['whatsapp_link']) is String
              ? (json['whatsappLink'] ?? json['whatsapp_link']) as String
              : null,
      amenities: List<String>.from(json['amenities'] ?? []),
      rules: List<String>.from(json['rules'] ?? []),
      gender: json['gender_preference'] ?? 'any',
      availableFrom:
          json['available_from'] != null
              ? DateTime.parse(json['available_from'])
              : DateTime.now(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      school: json['school'] ?? '',
      reportCount: json['report_count'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
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
      'ownerPhone': ownerPhone,
      'whatsappLink': whatsappLink,
      'amenities': amenities,
      'rules': rules,
      'gender_preference': gender,
      'available_from': availableFrom.toIso8601String(),
      'is_active': isActive,
      'school': school,
      'report_count': reportCount,
      'is_featured': isFeatured,
    };
  }
}
