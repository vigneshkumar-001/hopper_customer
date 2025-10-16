import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Presentation/Drawer/models/notification_response.dart';
import 'package:hopper/Presentation/Drawer/models/ride_history_response.dart';

import 'package:hopper/api/dataSource/apiDataSource.dart';

class NotificationController extends GetxController {
  final ApiDataSource apiDataSource = ApiDataSource();

  final RxBool isLoading = false.obs;
  RxList<NotificationData> notificationData = <NotificationData>[].obs;

  @override
  void onInit() {
    super.onInit();
    getNotification();
  }

  Future<void> getNotification() async {
    isLoading.value = true;
    try {
      final results = await apiDataSource.getNotification();
      results.fold(
        (failure) {
          AppLogger.log.e(" $failure");
        },
        (response) {
          notificationData.value = response.data;
          AppLogger.log.i("✅ Raw response: ${response.toJson()}");
        },
      );
    } catch (e) {
      AppLogger.log.e("❌ Exception while fetching rides: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
