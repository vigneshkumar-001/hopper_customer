class  NotificationResponse  {
  bool success;
  int count;
  List<NotificationData> data;

  NotificationResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => NotificationData.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class NotificationData {
  String id;
  String userType;
  String customerId;
  String bookingId;
  String type;
  String title;
  String message;
  NotificationDetails data;
  String status;
  String createdAt;
  DateTime updatedAt;
  int v;
  String imageType;
  String bookingType;
  bool sharedBooking;

  NotificationData({
    required this.id,
    required this.userType,
    required this.customerId,
    required this.bookingId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.imageType,
    required this.bookingType,
    required this.sharedBooking,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['_id'] ?? '',
      userType: json['userType'] ?? '',
      customerId: json['customerId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: NotificationDetails.fromJson(json['data'] ?? {}),
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '' ,
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      v: json['__v'] ?? 0,
      imageType: json['imageType'] ?? '',
      bookingType: json['bookingType'] ?? '',
      sharedBooking: json['sharedBooking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userType': userType,
      'customerId': customerId,
      'bookingId': bookingId,
      'type': type,
      'title': title,
      'message': message,
      'data': data.toJson(),
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
      'imageType': imageType,
      'bookingType': bookingType,
      'sharedBooking': sharedBooking,
    };
  }
}

class NotificationDetails {
  String bookingId;
  DateTime time;

  NotificationDetails({
    required this.bookingId,
    required this.time,
  });

  factory NotificationDetails.fromJson(Map<String, dynamic> json) {
    return NotificationDetails(
      bookingId: json['bookingId'] ?? '',
      time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'time': time.toIso8601String(),
    };
  }
}
