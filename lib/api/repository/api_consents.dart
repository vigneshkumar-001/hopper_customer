class ApiConsents {
  static String baseUrl = 'https://hoppr-face-two-dbe557472d7f.herokuapp.com';
  static String loginApi = '$baseUrl/customer/driver-search?latitude=9.9144264&longitude=78.0971928&dropLat=11.0250&dropLng=76.9700';
  static String createBooking = '$baseUrl/api/customer/create-booking';

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
  // https://hoppr-backend-3d2b7f783917.herokuapp.com/api/users/districts?state=$state
}
