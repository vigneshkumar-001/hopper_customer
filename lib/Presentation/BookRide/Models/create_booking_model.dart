class CreateBookingModel {
  final int status;
  final BookingData data;
  final String message;

  CreateBookingModel({
    required this.status,
    required this.data,
    required this.message,
  });

  factory CreateBookingModel.fromJson(Map<String, dynamic> json) {
    return CreateBookingModel(
      status: json['status'],
      data: BookingData.fromJson(json['data']),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'data': data.toJson(), 'message': message};
  }
}

class BookingData {
  final String bookingId;
  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;
  final String customerId;
  final bool sharedBooking;
  final int sharedCount;
  final int amount;
  final String status;
  final int duration;
  final bool scheduled;
  final bool trackingEnabled;
  final int baseFare;
  final int serviceFare;
  final String id;
  final DateTime otpGeneratedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingData({
    required this.bookingId,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
    required this.customerId,
    required this.sharedBooking,
    required this.sharedCount,
    required this.amount,
    required this.status,
    required this.duration,
    required this.scheduled,
    required this.trackingEnabled,
    required this.baseFare,
    required this.serviceFare,
    required this.id,
    required this.otpGeneratedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      bookingId: json['bookingId'],
      fromLatitude: (json['fromLatitude'] as num).toDouble(),
      fromLongitude: (json['fromLongitude'] as num).toDouble(),
      toLatitude: (json['toLatitude'] as num).toDouble(),
      toLongitude: (json['toLongitude'] as num).toDouble(),
      customerId: json['customerId'],
      sharedBooking: json['sharedBooking'],
      sharedCount: json['sharedCount'],
      amount: json['amount'],
      status: json['status'],
      duration: json['duration'],
      scheduled: json['scheduled'],
      trackingEnabled: json['trackingEnabled'],
      baseFare: json['baseFare'],
      serviceFare: json['serviceFare'],
      id: json['_id'],
      otpGeneratedAt: DateTime.parse(json['otpGeneratedAt']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'fromLatitude': fromLatitude,
      'fromLongitude': fromLongitude,
      'toLatitude': toLatitude,
      'toLongitude': toLongitude,
      'customerId': customerId,
      'sharedBooking': sharedBooking,
      'sharedCount': sharedCount,
      'amount': amount,
      'status': status,
      'duration': duration,
      'scheduled': scheduled,
      'trackingEnabled': trackingEnabled,
      'baseFare': baseFare,
      'serviceFare': serviceFare,
      '_id': id,
      'otpGeneratedAt': otpGeneratedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
