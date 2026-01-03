import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'all', 'specific', 'offer', 'promotion'
  final String? targetPhone; // null for all users
  final String? targetUserId; // null for all users
  final Map<String, dynamic>? data; // additional data
  final String? imageUrl;
  final String? actionUrl; // deep link or web URL
  final DateTime scheduledAt; // when to send
  final DateTime createdAt;
  final String status; // 'draft', 'scheduled', 'sent', 'failed'
  final int sentCount;
  final int failedCount;
  final String? errorMessage;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetPhone,
    this.targetUserId,
    this.data,
    this.imageUrl,
    this.actionUrl,
    required this.scheduledAt,
    required this.createdAt,
    required this.status,
    this.sentCount = 0,
    this.failedCount = 0,
    this.errorMessage,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'all',
      targetPhone: data['targetPhone'],
      targetUserId: data['targetUserId'],
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'draft',
      sentCount: data['sentCount'] ?? 0,
      failedCount: data['failedCount'] ?? 0,
      errorMessage: data['errorMessage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'targetPhone': targetPhone,
      'targetUserId': targetUserId,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'sentCount': sentCount,
      'failedCount': failedCount,
      'errorMessage': errorMessage,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? targetPhone,
    String? targetUserId,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    DateTime? scheduledAt,
    DateTime? createdAt,
    String? status,
    int? sentCount,
    int? failedCount,
    String? errorMessage,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetPhone: targetPhone ?? this.targetPhone,
      targetUserId: targetUserId ?? this.targetUserId,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      sentCount: sentCount ?? this.sentCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // دوال مساعدة
  bool get isDraft => status == 'draft';
  bool get isScheduled => status == 'scheduled';
  bool get isSent => status == 'sent';
  bool get isFailed => status == 'failed';
  bool get isForAllUsers => targetPhone == null && targetUserId == null;
  bool get isForSpecificUser => targetPhone != null || targetUserId != null;

  String get typeDisplayName {
    switch (type) {
      case 'all':
        return 'جميع المستخدمين';
      case 'specific':
        return 'مستخدم محدد';
      case 'offer':
        return 'عرض خاص';
      case 'promotion':
        return 'ترويج';
      default:
        return 'عام';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return 'مسودة';
      case 'scheduled':
        return 'مجدولة';
      case 'sent':
        return 'مرسلة';
      case 'failed':
        return 'فشلت';
      default:
        return 'غير معروف';
    }
  }

  String get formattedScheduledAt {
    return '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}
