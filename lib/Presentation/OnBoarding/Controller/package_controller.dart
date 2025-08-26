import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/confirmation_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/payment_screen.dart';
import 'package:hopper/Presentation/OnBoarding/models/address_models.dart';
import 'package:hopper/Presentation/OnBoarding/models/confrom_package_response.dart';
import 'package:hopper/Presentation/OnBoarding/models/package_details_response.dart';
import 'package:hopper/api/dataSource/apiDataSource.dart';

class PackageController extends GetxController {
  final ApiDataSource apiDataSource = ApiDataSource();
  final RxBool isLoading = false.obs;
  final RxBool isConfirmLoading = false.obs;
  var packageDetails = Rxn<PackageDetailsResponse>();
  var confirmPackageDetails = Rxn<ConfirmPackageResponse>();

  @override
  void onInit() {
    super.onInit();
  }

  Future<String?> packageAddressDetails({
    required AddressModel senderData,
    required AddressModel receiverData,
  }) async {
    try {
      isLoading.value = true;
      final results = await apiDataSource.packageAddressDetails(
        receiverData: receiverData,
        senderData: senderData,
      );
      return results.fold(
        (failure) {
          isLoading.value = false;
          return '';
        },
        (response) {
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
          Get.to(PaymentScreen(amount: amount.toInt(), bookingId: bookingId));
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
}
