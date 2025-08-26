class ApiConsents {
  static String baseUrl = 'https://hoppr-face-two-dbe557472d7f.herokuapp.com';

  static String createBooking = '$baseUrl/api/customer/create-booking';
  static String confirmBooking = '$baseUrl/api/customer/parcel/confirm-booking';
  static String sendDriverRequest = '$baseUrl/api/customer/send-driver-request';
  static String signIn = '$baseUrl/api/customer/sign-in';
  static String verifyOtp = '$baseUrl/api/customer/verify-otp';
  static String resendOtp = '$baseUrl/api/customer/resend-otp';

  static String driverSearch({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) {
    return '$baseUrl/api/customer/driver-search'
        '?latitude=$pickupLat&longitude=$pickupLng'
        '&dropLat=$dropLat&dropLng=$dropLng';
  }

  static String cancelRide({required String bookingId}) {
    return '$baseUrl/api/customer/cancel-booking/$bookingId';
  }

  static String rateDriver({required String bookingId}) {
    return '$baseUrl/api/customer/rate-driver/$bookingId';
  }
  // https://hoppr-backend-3d2b7f783917.herokuapp.com/api/users/districts?state=$state
}
