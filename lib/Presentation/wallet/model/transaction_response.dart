class TransactionResponse {
  final bool success;
  final double balance;
  final int totalTransactions;
  final List<Transaction> transactions;

  TransactionResponse({
    required this.success,
    required this.balance,
    required this.totalTransactions,
    required this.transactions,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      success: json['success'] ?? false,
      balance: (json['balance'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      transactions:
          (json['transactions'] as List<dynamic>?)
              ?.map((e) => Transaction.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Transaction {
  final String id;
  final double amount;
  final String type;
  final String paymentMode;
  final String status;
  final String? paymentId;
  final String? bookingId;
  final String? bookingType;
  final String createdAt; // formatted date string like "Sep 25 • 7:39 PM"
  final String displayText;
  final String imageType;
  final String color;
  final Booking? booking;
  final Payment? payment;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.paymentMode,
    required this.status,
    this.paymentId,
    this.bookingId,
    this.bookingType,
    required this.createdAt,
    required this.displayText,
    required this.imageType,
    required this.color,
    this.booking,
    this.payment,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      paymentMode: json['paymentMode'] ?? '',
      status: json['status'] ?? '',
      paymentId: json['paymentId'],
      bookingId: json['bookingId'],
      bookingType: json['bookingType'],
      createdAt: json['createdAt'] ?? '',
      displayText: json['displayText'] ?? '',
      imageType: json['imageType'] ?? '',
      color: json['color'] ?? '',
      booking:
          json['booking'] != null ? Booking.fromJson(json['booking']) : null,
      payment:
          json['payment'] != null ? Payment.fromJson(json['payment']) : null,
    );
  }
}

class Booking {
  final String status;
  final String pickupAddress;
  final String dropAddress;
  final DateTime createdAt;

  Booking({
    required this.status,
    required this.pickupAddress,
    required this.dropAddress,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      status: json['status'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      dropAddress: json['dropAddress'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Payment {
  final String id;
  final String userBookingId;
  final String status;
  final String type;
  final String paymentId;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.userBookingId,
    required this.status,
    required this.type,
    required this.paymentId,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? '',
      userBookingId: json['userBookingId'] ?? '',
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      paymentId: json['paymentId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
