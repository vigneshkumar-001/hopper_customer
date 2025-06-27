class DriverSearchModels {
  final int status;
  final List<DriverData> data;
  final int count;

  DriverSearchModels({
    required this.status,
    required this.data,
    required this.count,
  });

  factory DriverSearchModels.fromJson(Map<String, dynamic> json) {
    return DriverSearchModels(
      status: json['status'],
      data: List<DriverData>.from(
        json['data'].map((x) => DriverData.fromJson(x)),
      ),
      count: json['count'],
    );
  }
}

class DriverData {
  final String id;
  final DriverDetails driverId;
  final bool booked;
  final DateTime createdAt;
  final double currentLatitude;
  final double currentLongitude;
  final bool onlineStatus;
  final bool sharedBooking;
  final DateTime updatedAt;
  final DateTime requestDateAndTime;
  final String requestStatus;
  final double distance;
  final double estimatedPrice;
  final int estimatedTime;

  DriverData({
    required this.id,
    required this.driverId,
    required this.booked,
    required this.createdAt,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.onlineStatus,
    required this.sharedBooking,
    required this.updatedAt,
    required this.requestDateAndTime,
    required this.requestStatus,
    required this.distance,
    required this.estimatedPrice,
    required this.estimatedTime,
  });

  factory DriverData.fromJson(Map<String, dynamic> json) {
    return DriverData(
      id: json['_id'],
      driverId: DriverDetails.fromJson(json['driverId']),
      booked: json['booked'],
      createdAt: DateTime.parse(json['createdAt']),
      currentLatitude: (json['currentLatitude'] as num).toDouble(),
      currentLongitude: (json['currentLongitude'] as num).toDouble(),
      onlineStatus: json['onlineStatus'],
      sharedBooking: json['sharedBooking'],
      updatedAt: DateTime.parse(json['updatedAt']),
      requestDateAndTime: DateTime.parse(json['requestDateAndTime']),
      requestStatus: json['requestStatus'],
      distance: (json['distance'] as num).toDouble(),
      estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
      estimatedTime: json['estimatedTime'],
    );
  }
}

class DriverDetails {
  final String id;
  final String firstName;
  final String lastName;
  final String? carBrand;
  final String? carModel;
  final String? carType;

  DriverDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.carBrand,
    this.carModel,
    this.carType,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      id: json['_id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      carBrand: json['carBrand'],
      carModel: json['carModel'],
      carType: json['carType'],
    );
  }
}
