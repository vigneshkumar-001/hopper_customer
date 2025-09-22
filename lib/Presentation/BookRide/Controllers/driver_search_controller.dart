import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Presentation/BookRide/Models/create_booking_model.dart';
import 'package:hopper/Presentation/BookRide/Models/driver_search_models.dart';
import 'package:hopper/Presentation/BookRide/Models/send_driver_request_models.dart';

import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/custom_bottomnavigation.dart';

import 'package:hopper/uitls/websocket/socket_io_client.dart';

import '../../../Core/Utility/app_toasts.dart';
import '../../../api/dataSource/apiDataSource.dart';

class DriverSearchController extends GetxController {
  ApiDataSource apiDataSource = ApiDataSource();
  Rxn<DriverSearchModels> userProfile = Rxn<DriverSearchModels>();
  RxList<DriverData> serviceType = <DriverData>[].obs;
  Rxn<BookingData> carBooking = Rxn<BookingData>();
  Rxn<BookingDriverData> sendDriverRequestData = Rxn<BookingDriverData>();
  RxString estimatedTime = ''.obs;
  final socketService = SocketService();
  RxBool markerAdded = false.obs;
  RxBool isLoading = false.obs;
  RxBool isGetLoading = false.obs;
  RxString selectedCarType = ''.obs; // default to Luxury

  @override
  void onInit() {
    super.onInit();
  }

  Future<DriverSearchModels?> getDriverSearch({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    isGetLoading.value = true;

    try {
      final results = await apiDataSource.getDriverSearch(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
      );

      return results.fold(
        (failure) {
          isGetLoading.value = false;
          return null;
        },
        (response) {
          isGetLoading.value = false;
          serviceType.value = response.data;
          markerAdded.value = false;
          update();
          AppLogger.log.i(serviceType.length);
          AppLogger.log.i(response.data.toString());
          return response;
        },
      );
    } catch (e) {
      isGetLoading.value = false;
      return null;
    }
  }

  Future<String?> createBookingCar({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
    required String customerId,
    required BuildContext context,
  }) async {
    isLoading.value = true;

    try {
      final results = await apiDataSource.carBookingCar(
        fromLatitude: fromLatitude,
        fromLongitude: fromLongitude,
        toLatitude: toLatitude,
        toLongitude: toLongitude,
        customerId: customerId,
      );

      return results.fold(
        (failure) {
          isLoading.value = false;
          return failure.message;
        },
        (response) {
          isLoading.value = false;
          carBooking.value = response.data;

          final bookingData = {
            'bookingId': response.data. bookingId,
            'userId': response.data.customerId,
          };

          // Log the data
          AppLogger.log.i("📤 Join booking data: $bookingData");

          if (socketService.connected) {
            socketService.emit('join-booking', bookingData);
            AppLogger.log.i("✅ Socket already connected, emitted join-booking");
          } else {
            socketService.onConnect(() {
              AppLogger.log.i("✅ Socket connected, emitting join-booking");
              socketService.emit('join-booking', bookingData);
            });
          }

          if (socketService.connected) {
            socketService.emit('join-booking', bookingData);
            AppLogger.log.i("✅ Socket already connected, emitted join-booking");
          } else {
            socketService.onConnect(() {
              AppLogger.log.i("✅ Socket connected, emitting join-booking");
              socketService.emit('join-booking', bookingData);
            });
          }

          AppLogger.log.i(response.data);
          return null;
        },
      );
    } catch (e) {
      isLoading.value = false;
      return 'An error occurred';
    }
  }

  Future<String?> sendDriverRequest({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropLatitude,
    required double dropLongitude,

    required String bookingId,
    required String carType,
    required BuildContext context,
  }) async {
    isLoading.value = true;

    try {
      final results = await apiDataSource.sendDriverRequest(
        carType: carType,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        dropLatitude: dropLatitude,
        dropLongitude: dropLongitude,
        bookingId: bookingId,
      );

      return results.fold(
        (failure) {
          isLoading.value = false;
          return failure.message;
        },
        (response) {
          isLoading.value = false;
          sendDriverRequestData.value = response.data;
          AppLogger.log.i(response.data);

          return '';
        },
      );
    } catch (e) {
      isLoading.value = false;
      return 'An error occurred';
    }
  }

  Future<String?> cancelRide({
    required String bookingId,
    required String selectedReason,
    required BuildContext context,
  }) async {
    isLoading.value = true;

    try {
      final results = await apiDataSource.cancelRide(
        selectedReason: selectedReason,
        bookingId: bookingId,
      );

      return results.fold(
        (failure) {
          isLoading.value = false;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommonBottomNavigation(initialIndex: 0),
            ),
          );
          return failure.message;
        },
        (response) {
          AppToasts.customToast(context, response.message);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommonBottomNavigation(initialIndex: 0),
            ),
          );
          isLoading.value = false;
          sendDriverRequestData.value = response.data;
          AppLogger.log.i(response.data);

          return '';
        },
      );
    } catch (e) {
      isLoading.value = false;
      return 'An error occurred';
    }
  }

  Future<String?> rateDriver({
    required String bookingId,
    required String rating,
    required BuildContext context,
  }) async {
    isLoading.value = true;

    try {
      final results = await apiDataSource.starRating(
        selectedReason: rating,
        bookingId: bookingId,
      );

      return results.fold(
        (failure) {
          isLoading.value = false;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommonBottomNavigation(initialIndex: 0),
            ),
          );
          return failure.message;
        },
        (response) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommonBottomNavigation(initialIndex: 0),
            ),
          );
          isLoading.value = false;
          sendDriverRequestData.value = response.data;
          AppLogger.log.i(response.data);

          return '';
        },
      );
    } catch (e) {
      isLoading.value = false;
      return 'An error occurred';
    }
  }

  void clearState() {}
}
