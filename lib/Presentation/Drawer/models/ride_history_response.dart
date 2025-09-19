class RideHistoryResponse {
  final bool success;
  final List<RideHistoryData> remappedBookings;

  RideHistoryResponse({
    required this.success,
    required this.remappedBookings,
  });

  factory RideHistoryResponse.fromJson(Map<String, dynamic> json) {
    return RideHistoryResponse(
      success: json['success'] ?? false,
      remappedBookings: (json['remappedBookings'] as List? ?? [])
          .map((e) => RideHistoryData.fromJson(e))
          .toList(),
    );
  }
}

class RideHistoryData {
  final String? id;
  final String? bookingType;
  final String? bookingId;
  final double? fromLatitude;
  final double? fromLongitude;
  final double? toLatitude;
  final double? toLongitude;
  final Customer? customer;
  final Driver? driver;
  final bool sharedBooking;
  final int sharedCount;
  final num? amount;
  final String? status;
  final bool otpVerified;
  final bool scheduled;
  final bool trackingEnabled;
  final num? baseFare;
  final num? serviceFare;
  final num? distance;
  final num? duration;
  final num? total;
  final String? pickupAddress;
  final String? dropAddress;
  final String? rideType;
  final String? serviceLocationId;
  final String? serviceLocationName;

  // Parcel-specific
  final String? fromContactName;
  final String? fromContactPhone;
  final String? toContactName;
  final String? toContactPhone;
  final String? parcelType;
  final String? description;
  final String? deliveryInstruction;
  final String? addressType;
  final int? maxWeight;

  // Cancellation/refund
  final String? rejectedReason;
  final String? specificReason;
  final num? cancellationFee;
  final num? refundAmount;

  final String? otpCode;
  final String? otpGeneratedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? completedAt;

  final List<RideStatus> rideStatusHistory;
  final Rating? customerRating;
  final Rating? driverRating;

  final int? rideDurationSeconds;
  final String? rideDurationFormatted;

  RideHistoryData({
    this.id,
    this.bookingType,
    this.bookingId,
    this.fromLatitude,
    this.fromLongitude,
    this.toLatitude,
    this.toLongitude,
    this.customer,
    this.driver,
    this.sharedBooking = false,
    this.sharedCount = 0,
    this.amount,
    this.status,
    this.otpVerified = false,
    this.scheduled = false,
    this.trackingEnabled = false,
    this.baseFare,
    this.serviceFare,
    this.distance,
    this.duration,
    this.total,
    this.pickupAddress,
    this.dropAddress,
    this.rideType,
    this.serviceLocationId,
    this.serviceLocationName,
    this.fromContactName,
    this.fromContactPhone,
    this.toContactName,
    this.toContactPhone,
    this.parcelType,
    this.description,
    this.deliveryInstruction,
    this.addressType,
    this.maxWeight,
    this.rejectedReason,
    this.specificReason,
    this.cancellationFee,
    this.refundAmount,
    this.otpCode,
    this.otpGeneratedAt,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.rideStatusHistory = const [],
    this.customerRating,
    this.driverRating,
    this.rideDurationSeconds,
    this.rideDurationFormatted,
  });

  factory RideHistoryData.fromJson(Map<String, dynamic> json) {
    return RideHistoryData(
      id: json['_id'],
      bookingType: json['bookingType'] ?? json[' bookingType'], // handle typo
      bookingId: json['bookingId'],
      fromLatitude: (json['fromLatitude'] != null)
          ? double.tryParse(json['fromLatitude'].toString())
          : null,
      fromLongitude: (json['fromLongitude'] != null)
          ? double.tryParse(json['fromLongitude'].toString())
          : null,
      toLatitude: (json['toLatitude'] != null)
          ? double.tryParse(json['toLatitude'].toString())
          : null,
      toLongitude: (json['toLongitude'] != null)
          ? double.tryParse(json['toLongitude'].toString())
          : null,
      customer:
      json['customerId'] != null ? Customer.fromJson(json['customerId']) : null,
      driver: json['driverId'] != null ? Driver.fromJson(json['driverId']) : null,
      sharedBooking: json['sharedBooking'] ?? false,
      sharedCount: json['sharedCount'] ?? 0,
      amount: json['amount'],
      status: json['status'],
      otpVerified: json['otpVerified'] ?? false,
      scheduled: json['scheduled'] ?? false,
      trackingEnabled: json['trackingEnabled'] ?? false,
      baseFare: json['baseFare'],
      serviceFare: json['serviceFare'],
      distance: json['distance'],
      duration: json['duration'],
      total: json['total'],
      pickupAddress: json['pickupAddress'],
      dropAddress: json['dropAddress'],
      rideType: json['rideType'],
      serviceLocationId: json['serviceLocationId'],
      serviceLocationName: json['serviceLocationName'],
      fromContactName: json['fromContact_name'],
      fromContactPhone: json['fromContact_phone'],
      toContactName: json['toContact_name'],
      toContactPhone: json['toContact_phone'],
      parcelType: json['parcel_type'],
      description: json['description'],
      deliveryInstruction: json['delivery_instruction'],
      addressType: json['address_type'],
      maxWeight: json['maxWeight'],
      rejectedReason: json['rejectedReason'],
      specificReason: json['specificReason'],
      cancellationFee: json['cancellationFee'],
      refundAmount: json['refundAmount'],
      otpCode: json['otpCode'],
      otpGeneratedAt: json['otpGeneratedAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      completedAt: json['completedAt'],
      rideStatusHistory: (json['rideStatusHistory'] as List? ?? [])
          .map((e) => RideStatus.fromJson(e))
          .toList(),
      customerRating: json['customerRating'] != null
          ? Rating.fromJson(json['customerRating'])
          : null,
      driverRating: json['driverRating'] != null
          ? Rating.fromJson(json['driverRating'])
          : null,
      rideDurationSeconds: json['rideDurationSeconds'],
      rideDurationFormatted: json['rideDurationFormatted'],
    );
  }
}

class Customer {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;

  Customer({this.id, this.firstName, this.lastName, this.email, this.phone});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class Driver {
  final String? id;
  final String? serviceType;
  final String? firstName;
  final String? lastName;
  final String? profilePic;
  final String? mobileNumber;

  final String? carPlateNumber;
  final String? carBrand;
  final String? carModel;
  final String? carColor;
  final String? carRegistrationNumber;
  final String? carType;

  final String? bikePlateNumber;
  final String? bikeBrand;
  final String? bikeModel;
  final String? bikeRegistrationNumber;

  Driver({
    this.id,
    this.serviceType,
    this.firstName,
    this.lastName,
    this.profilePic,
    this.mobileNumber,
    this.carPlateNumber,
    this.carBrand,
    this.carModel,
    this.carColor,
    this.carRegistrationNumber,
    this.carType,
    this.bikePlateNumber,
    this.bikeBrand,
    this.bikeModel,
    this.bikeRegistrationNumber,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id'],
      serviceType: json['serviceType'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profilePic: json['profilePic'],
      mobileNumber: json['mobileNumber'],
      carPlateNumber: json['carPlateNumber'],
      carBrand: json['carBrand'],
      carModel: json['carModel'],
      carColor: json['carColor'],
      carRegistrationNumber: json['carRegistrationNumber'],
      carType: json['carType'],
      bikePlateNumber: json['bikePlateNumber'],
      bikeBrand: json['bikeBrand'],
      bikeModel: json['bikeModel'],
      bikeRegistrationNumber: json['bikeRegistrationNumber'],
    );
  }
}

class RideStatus {
  final String? status;
  final String? timestamp;

  RideStatus({this.status, this.timestamp});

  factory RideStatus.fromJson(Map<String, dynamic> json) {
    return RideStatus(
      status: json['status'],
      timestamp: json['timestamp'],
    );
  }
}

class Rating {
  final int? rating;
  final String? review;

  Rating({this.rating, this.review});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rating: json['rating'],
      review: json['review'],
    );
  }
}
