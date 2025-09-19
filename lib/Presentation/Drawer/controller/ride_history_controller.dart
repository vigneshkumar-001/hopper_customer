import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Presentation/Drawer/models/ride_history_response.dart';

import 'package:hopper/api/dataSource/apiDataSource.dart';

class RideHistoryController extends GetxController {
  final ApiDataSource apiDataSource = ApiDataSource();
  final RxList<RideHistoryData> rideHistoryList = <RideHistoryData>[].obs;
  final RxList<RideHistoryData> parcelHistoryList = <RideHistoryData>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getRideHistory();
  }
  Future<void> getRideHistory() async {
    isLoading.value = true;
    try {
      final results = await apiDataSource.getRideHistory();
      results.fold(
            (failure) {
          AppLogger.log.e("❌ Ride history fetch failed: $failure");
        },
            (response) {
          rideHistoryList.assignAll(
            response. remappedBookings .where((e) => e.bookingType == 'Ride').toList(),
          );

          parcelHistoryList.assignAll(
            response. remappedBookings .where((e) => e.bookingType == 'Parcel').toList(),
          );

          AppLogger.log.i(
            "🚗 Rides: ${rideHistoryList.length}, 📦 Parcels: ${parcelHistoryList.length}",
          );
        },
      );
    } catch (e) {
      AppLogger.log.e("❌ Exception while fetching rides: $e");
    } finally {
      isLoading.value = false;
    }
  }
  // Future<void> getRideHistory() async {
  //   isLoading.value = true;
  //   try {
  //     final results = await apiDataSource.getRideHistory();
  //     results.fold(
  //       (failure) {
  //         AppLogger.log.e("❌ Ride history fetch failed: $failure");
  //       },
  //       (response) {
  //         AppLogger.log.i("✅ Raw response: ${response.toJson()}");
  //         AppLogger.log.i("📦 Bookings count: ${response.bookings.length}");
  //         rideHistoryList.assignAll(response.bookings);
  //         AppLogger.log.i(
  //           "🚗 Ride list updated: ${rideHistoryList.length} items",
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     AppLogger.log.e("❌ Exception while fetching rides: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
}
