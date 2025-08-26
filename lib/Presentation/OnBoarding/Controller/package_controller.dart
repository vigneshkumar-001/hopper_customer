import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/confirmation_screen.dart';
import 'package:hopper/Presentation/OnBoarding/models/address_models.dart';
import 'package:hopper/Presentation/OnBoarding/models/package_details_response.dart';
import 'package:hopper/api/dataSource/apiDataSource.dart';

class PackageController extends GetxController {
  final ApiDataSource apiDataSource = ApiDataSource();
  final RxBool isLoading = false.obs;
  var packageDetails = Rxn<PackageDetailsResponse>();

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
          AppLogger.log.i(packageDetails.value);
          return response.data.toString();
        },
      );
    } catch (e) {
      isLoading.value = false;
      AppLogger.log.e(e);
    }
    return null;
  }
}
