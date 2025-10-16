import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/confirmation_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/payment_screen.dart';
import 'package:hopper/Presentation/OnBoarding/models/address_models.dart';
import 'package:hopper/Presentation/OnBoarding/models/confrom_package_response.dart';
import 'package:hopper/Presentation/OnBoarding/models/package_details_response.dart';
import 'package:hopper/api/dataSource/apiDataSource.dart';
import 'package:hopper/dummy_screen.dart';

import '../../../uitls/websocket/socket_io_client.dart';
import '../../Drawer/controller/ride_history_controller.dart';
import '../Screens/package_map_confrim_screen.dart';

class PackageController extends GetxController {
  final ApiDataSource apiDataSource = ApiDataSource();
  final RxBool isLoading = false.obs;
  final socketService = SocketService();
  final RxBool isConfirmLoading = false.obs;
  final RxBool isButtonLoading = false.obs;
  var packageDetails = Rxn<PackageDetailsResponse>();
  var confirmPackageDetails = Rxn<ConfirmPackageResponse>();
  final RideHistoryController controller = Get.put(RideHistoryController());
  @override
  void onInit() {
    super.onInit();
    controller.getRideHistory();
  }

  Future<String?> paymentDetails({
    required String bookingId,
    required String paymentType,
    required BuildContext context,
  }) async {
    isButtonLoading.value = true;

    try {
      final results = await apiDataSource.paymentDetails(
        paymentType: paymentType,
        bookingId: bookingId,
      );

      return results.fold(
        (failure) {
          isButtonLoading.value = false;
          return failure.message;
        },
        (response) {
          isButtonLoading.value = false;

          return '';
        },
      );
    } catch (e) {
      isButtonLoading.value = false;
      return 'An error occurred';
    }
  }

  Future<String?> packageAddressDetails({
    required AddressModel senderData,
    required AddressModel receiverData,
    required String weight,
    required String selectedParcel,
  }) async {
    try {
      isLoading.value = true;
      final results = await apiDataSource.packageAddressDetails(
        receiverData: receiverData,
        senderData: senderData,
        weight: weight,
        selectedParcel: selectedParcel,
      );
      return results.fold(
        (failure) {
          isLoading.value = false;
          return '';
        },
        (response) {
          isLoading.value = false;
          final bookingData = {
            'bookingId': response.data.bookingId,
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
          isLoading.value = false;
          packageDetails.value = response;
          AppLogger.log.i("Package Details  == ${packageDetails.value}");
          return response.data.toString();
        },
      );
    } catch (e) {
      isLoading.value = false;
      AppLogger.log.e(e);
    }
    return null;
  }

  Future<String?> confirmPackageAddressDetails({
    required String bookingId,
    required String weight,
    required AddressModel senderData,
    required AddressModel receiverData,
  }) async {
    try {
      isConfirmLoading.value = true;
      final results = await apiDataSource.confirmPackageScreen(
        bookingId: bookingId,
      );
      return results.fold(
        (failure) {
          isConfirmLoading.value = false;
          AppLogger.log.e("Failure: $failure");
          return '';
        },
        (response) {
          isConfirmLoading.value = false;
          confirmPackageDetails.value = response;
          final double amount = response.data.amount;
          final String bookingId = response.data.bookingId;
          AppLogger.log.i(' ${amount},${bookingId}');

          Get.to(
            PaymentScreen(
              amount: amount,
              bookingId: bookingId,
              sender: senderData,
              receiver: receiverData,
            ),
          );
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => PaymentScreen()),
          // );
          AppLogger.log.i('confirm = ${confirmPackageDetails.value?.toJson()}');

          return response.data.toString();
        },
      );
    } catch (e) {
      isConfirmLoading.value = false;
      AppLogger.log.e(e);
    }
    return null;
  }

  Future<String?> sendPackageDriverRequest({
    required String bookingId,
    required AddressModel senderData,
    required AddressModel receiverData,
  }) async {
    try {
      isConfirmLoading.value = true;
      final results = await apiDataSource.sendPackageDriverRequest(
        bookingId: bookingId,
        receiverData: receiverData,
        senderData: senderData,
      );
      return results.fold(
        (failure) {
          isConfirmLoading.value = false; // ✅ handled
          AppLogger.log.e("Failure: $failure");
          return '';
        },
        (response) {
          isConfirmLoading.value = false;
          Get.to(
            PackageMapConfirmScreen(
              bookingId: bookingId,
              senderData: senderData,
              receiverData: receiverData,
            ),
          );
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => PaymentScreen()),
          // );
          AppLogger.log.i('${response.data}');

          return response.data.toString();
        },
      );
    } catch (e) {
      isConfirmLoading.value = false;
      AppLogger.log.e(e);
    }
    return null;
  }
}
