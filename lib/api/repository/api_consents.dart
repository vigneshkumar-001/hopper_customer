class ApiConsents {
  static String baseUrl = 'https://hoppr-face-two-dbe557472d7f.herokuapp.com';
  static String baseUrl1 = 'https://4wsg7ghz-3000.inc1.devtunnels.ms';
  static String googleMapApiKey = 'AIzaSyDZ0T-ObERFV38YA0F2AVdZtrt1qUO-1D8';

  static String createBooking = '$baseUrl/api/customer/create-booking';
  static String confirmBooking = '$baseUrl/api/customer/parcel/confirm-booking';
  static String sendDriverRequest = '$baseUrl/api/customer/send-driver-request';
  static String rideHistory = '$baseUrl/api/customer/ride-history';
  static String getCustomerDetails = '$baseUrl/api/customer/getCustomerDetails';
  static String postCustomerDetails =
      '$baseUrl/api/customer/update-customer-settings';
  static String addToWallet = '$baseUrl/api/customer/add-to-wallet';
  static String getwalletBalance = '$baseUrl/api/customer/getwalletBalance';
  static String customerWalletHistory =
      '$baseUrl/api/customer/customer-wallet-history';
  static String signIn = '$baseUrl/api/customer/sign-in';
  static String verifyOtp = '$baseUrl/api/customer/verify-otp';
  static String resendOtp = '$baseUrl/api/customer/resend-otp';
  static String notification = '$baseUrl/api/customer/notifications';






  static String addToWalletResponse =
      '$baseUrl/api/customer/add-to-wallet-reponse';
  static String userImageUpload =
      'https://next.fenizotechnologies.com/Adrox/api/image-save';
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
