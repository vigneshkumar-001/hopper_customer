class SendDriverRequestModels {
  final int status;
  final String message;
  final BookingDriverData data;

  SendDriverRequestModels({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SendDriverRequestModels.fromJson(Map<String, dynamic> json) {
    return SendDriverRequestModels(
      status: json['status'],
      message: json['message'],
      data: BookingDriverData.fromJson(json['data']),
    );
  }
}

class BookingDriverData {
  final int driversNotified;

  BookingDriverData({required this.driversNotified});

  factory BookingDriverData.fromJson(Map<String, dynamic> json) {
    return BookingDriverData(driversNotified: json['driversNotified']);
  }
}
