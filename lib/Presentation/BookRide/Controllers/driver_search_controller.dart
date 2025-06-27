import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Presentation/BookRide/Models/create_booking_model.dart';
import 'package:hopper/Presentation/BookRide/Models/driver_search_models.dart';
import 'package:hopper/Presentation/BookRide/Screens/confirm_booking.dart';

import '../../../api/dataSource/apiDataSource.dart';

class DriverSearchController extends GetxController {
  ApiDataSource apiDataSource = ApiDataSource();
  Rxn<DriverSearchModels> userProfile = Rxn<DriverSearchModels>();
  RxList<DriverData> serviceType = <DriverData>[].obs;
  Rxn<BookingData> carBooking = Rxn<BookingData>();

  RxBool isLoading = false.obs;
  RxBool isGetLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<String?> getDriverSearch({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    isLoading.value = true;

    try {
      final results = await apiDataSource.getDriverSearch(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
      );

      return results.fold(
        (failure) {
          isLoading.value = false;
          return failure.message;
        },
        (response) {
          isLoading.value = false;
          serviceType.value = response.data;
          return '';
        },
      );
    } catch (e) {
      isLoading.value = false;
      return 'An error occurred';
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
