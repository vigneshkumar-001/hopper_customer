// class OtpResponse {
//   final int status;
//   final Data data;
//
//   OtpResponse({required this.status, required this.data});
//
//   factory OtpResponse.fromJson(Map<String, dynamic> json) {
//     return OtpResponse(
//       status: json['status'],
//       data: Data.fromJson(json['data']),
//     );
//   }
// }
//
// class Data {
//   final String token;
//   final Customer customer;
//
//   Data({required this.token, required this.customer});
//
//   factory Data.fromJson(Map<String, dynamic> json) {
//     return Data(
//       token: json['token'],
//       customer: Customer.fromJson(json['customer']),
//     );
//   }
// }
//
// class Customer {
//   final String id;
//   final String firstName;
//   final String lastName;
//   final String? email;
//   final String phone;
//   final bool isActive;
//   final bool isVerified;
//   final bool isBlocked;
//   final bool emailVerified;
//   final bool phoneVerified;
//   final bool isOnline;
//   final int averageRating;
//   final int totalRatings;
//   final int totalBookings;
//   final int totalCancelledBookings;
//   final int completedBookings;
//   final String defaultPaymentMethod;
//   final int walletBalance;
//   final List<dynamic> addresses;
//   final String lastSeen;
//   final Preferences preferences;
//   final String createdAt;
//   final String updatedAt;
//
//   Customer({
//     required this.id,
//     required this.firstName,
//     required this.lastName,
//     required this.email,
//     required this.phone,
//     required this.isActive,
//     required this.isVerified,
//     required this.isBlocked,
//     required this.emailVerified,
//     required this.phoneVerified,
//     required this.isOnline,
//     required this.averageRating,
//     required this.totalRatings,
//     required this.totalBookings,
//     required this.totalCancelledBookings,
//     required this.completedBookings,
//     required this.defaultPaymentMethod,
//     required this.walletBalance,
//     required this.addresses,
//     required this.lastSeen,
//     required this.preferences,
//     required this.createdAt,
//     required this.updatedAt,
//   });
//
//   factory Customer.fromJson(Map<String, dynamic> json) {
//     return Customer(
//       id: json['_id'],
//       firstName: json['firstName'],
//       lastName: json['lastName'],
//       email: json['email'],
//       phone: json['phone'],
//       isActive: json['isActive'],
//       isVerified: json['isVerified'],
//       isBlocked: json['isBlocked'],
//       emailVerified: json['emailVerified'],
//       phoneVerified: json['phoneVerified'],
//       isOnline: json['isOnline'],
//       averageRating: json['averageRating'],
//       totalRatings: json['totalRatings'],
//       totalBookings: json['totalBookings'],
//       totalCancelledBookings: json['totalCancelledBookings'],
//       completedBookings: json['completedBookings'],
//       defaultPaymentMethod: json['defaultPaymentMethod'],
//       walletBalance: json['walletBalance'],
//       addresses: List<dynamic>.from(json['addresses']),
//       lastSeen: json['lastSeen'],
//       preferences: Preferences.fromJson(json['preferences']),
//       createdAt: json['createdAt'],
//       updatedAt: json['updatedAt'],
//     );
//   }
// }
//
// class Preferences {
//   final Notifications notifications;
//   final Privacy privacy;
//   final Ride ride;
//   final String language;
//   final String currency;
//
//   Preferences({
//     required this.notifications,
//     required this.privacy,
//     required this.ride,
//     required this.language,
//     required this.currency,
//   });
//
//   factory Preferences.fromJson(Map<String, dynamic> json) {
//     return Preferences(
//       notifications: Notifications.fromJson(json['notifications']),
//       privacy: Privacy.fromJson(json['privacy']),
//       ride: Ride.fromJson(json['ride']),
//       language: json['language'],
//       currency: json['currency'],
//     );
//   }
// }
//
// class Notifications {
//   final bool email;
//   final bool sms;
//   final bool push;
//   final bool bookingUpdates;
//   final bool promotions;
//   final bool rideReminders;
//
//   Notifications({
//     required this.email,
//     required this.sms,
//     required this.push,
//     required this.bookingUpdates,
//     required this.promotions,
//     required this.rideReminders,
//   });
//
//   factory Notifications.fromJson(Map<String, dynamic> json) {
//     return Notifications(
//       email: json['email'],
//       sms: json['sms'],
//       push: json['push'],
//       bookingUpdates: json['bookingUpdates'],
//       promotions: json['promotions'],
//       rideReminders: json['rideReminders'],
//     );
//   }
// }
//
// class Privacy {
//   final bool shareLocation;
//   final bool showOnlineStatus;
//   final bool allowDataCollection;
//
//   Privacy({
//     required this.shareLocation,
//     required this.showOnlineStatus,
//     required this.allowDataCollection,
//   });
//
//   factory Privacy.fromJson(Map<String, dynamic> json) {
//     return Privacy(
//       shareLocation: json['shareLocation'],
//       showOnlineStatus: json['showOnlineStatus'],
//       allowDataCollection: json['allowDataCollection'],
//     );
//   }
// }
//
// class Ride {
//   final List<dynamic> preferredVehicleType;
//   final int maxWaitTime;
//   final bool autoConfirmBooking;
//   final bool allowSharedRides;
//
//   Ride({
//     required this.preferredVehicleType,
//     required this.maxWaitTime,
//     required this.autoConfirmBooking,
//     required this.allowSharedRides,
//   });
//
//   factory Ride.fromJson(Map<String, dynamic> json) {
//     return Ride(
//       preferredVehicleType: List<dynamic>.from(json['preferredVehicleType']),
//       maxWaitTime: json['maxWaitTime'],
//       autoConfirmBooking: json['autoConfirmBooking'],
//       allowSharedRides: json['allowSharedRides'],
//     );
//   }
// }



class OtpResponse {
  final int status;
  final Data data;

  OtpResponse({
    required this.status,
    required this.data,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      status: json['status'],
      data: Data.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": data.toJson(),
  };
}

class Data {
  final String token;
  final Customer customer;

  Data({
    required this.token,
    required this.customer,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      token: json['token'],
      customer: Customer.fromJson(json['customer']),
    );
  }

  Map<String, dynamic> toJson() => {
    "token": token,
    "customer": customer.toJson(),
  };
}

class Customer {
  final String id;
  final String firstName;
  final String lastName;

  final String phone;

  final String countryCode;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,

    required this.phone,

    required this.countryCode,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'],
      firstName: json['firstName'],
      lastName: json['lastName'],

      phone: json['phone'],

      countryCode: json['countryCode'],
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "firstName": firstName,
    "lastName": lastName,

    "phone": phone,

    "countryCode": countryCode,
  };
}

class Preferences {
  final Notifications notifications;
  final Privacy privacy;
  final Ride ride;
  final String language;
  final String currency;
  final String id;

  Preferences({
    required this.notifications,
    required this.privacy,
    required this.ride,
    required this.language,
    required this.currency,
    required this.id,
  });

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      notifications: Notifications.fromJson(json['notifications']),
      privacy: Privacy.fromJson(json['privacy']),
      ride: Ride.fromJson(json['ride']),
      language: json['language'],
      currency: json['currency'],
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    "notifications": notifications.toJson(),
    "privacy": privacy.toJson(),
    "ride": ride.toJson(),
    "language": language,
    "currency": currency,
    "_id": id,
  };
}

class Notifications {
  final String email;
  final String sms;
  final String push;
  final String bookingUpdates;
  final String promotions;
  final String rideReminders;

  Notifications({
    required this.email,
    required this.sms,
    required this.push,
    required this.bookingUpdates,
    required this.promotions,
    required this.rideReminders,
  });

  factory Notifications.fromJson(Map<String, dynamic> json) {
    return Notifications(
      email: json['email'],
      sms: json['sms'],
      push: json['push'],
      bookingUpdates: json['bookingUpdates'],
      promotions: json['promotions'],
      rideReminders: json['rideReminders'],
    );
  }

  Map<String, dynamic> toJson() => {
    "email": email,
    "sms": sms,
    "push": push,
    "bookingUpdates": bookingUpdates,
    "promotions": promotions,
    "rideReminders": rideReminders,
  };
}

class Privacy {
  final String shareLocation;
  final String showOnlineStatus;
  final String allowDataCollection;

  Privacy({
    required this.shareLocation,
    required this.showOnlineStatus,
    required this.allowDataCollection,
  });

  factory Privacy.fromJson(Map<String, dynamic> json) {
    return Privacy(
      shareLocation: json['shareLocation'],
      showOnlineStatus: json['showOnlineStatus'],
      allowDataCollection: json['allowDataCollection'],
    );
  }

  Map<String, dynamic> toJson() => {
    "shareLocation": shareLocation,
    "showOnlineStatus": showOnlineStatus,
    "allowDataCollection": allowDataCollection,
  };
}

class Ride {
  final List<dynamic> preferredVehicleType;
  final String maxWaitTime;
  final String autoConfirmBooking;
  final String allowSharedRides;

  Ride({
    required this.preferredVehicleType,
    required this.maxWaitTime,
    required this.autoConfirmBooking,
    required this.allowSharedRides,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      preferredVehicleType: List<dynamic>.from(json['preferredVehicleType']),
      maxWaitTime: json['maxWaitTime'],
      autoConfirmBooking: json['autoConfirmBooking'],
      allowSharedRides: json['allowSharedRides'],
    );
  }

  Map<String, dynamic> toJson() => {
    "preferredVehicleType": preferredVehicleType,
    "maxWaitTime": maxWaitTime,
    "autoConfirmBooking": autoConfirmBooking,
    "allowSharedRides": allowSharedRides,
  };
}
