class ReportModel {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? reportedListingId;
  final String reason;
  final String? details;
  final String status;
  final DateTime createdAt;

  // Optional display fields populated from joins
  final String? reporterName;
  final String? reportedUserName;
  final String? reportedListingTitle;

  ReportModel({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.reportedListingId,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
    this.reporterName,
    this.reportedUserName,
    this.reportedListingTitle,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportedUserId: json['reported_user_id'] as String?,
      reportedListingId: json['reported_listing_id'] as String?,
      reason: json['reason'] as String,
      details: json['details'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      reporterName: json['reporter_name'] as String?,
      reportedUserName: json['reported_user_name'] as String?,
      reportedListingTitle: json['reported_listing_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'reported_listing_id': reportedListingId,
      'reason': reason,
      'details': details,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
