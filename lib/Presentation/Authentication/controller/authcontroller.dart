import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopper/Presentation/Authentication/controller/authController.dart';
import 'package:country_picker/country_picker.dart';
import 'package:hopper/Presentation/Authentication/screens/otp_screens.dart';
import 'package:hopper/api/dataSource/apiDataSource.dart';

import '../../../Core/Utility/app_toasts.dart';

var getMobileNumber = '';
var countryCodes = '';
String selectedCountryFlag = '';

class AuthController extends GetxController {
  // String mobileNumber = '';
  TextEditingController mobileNumber = TextEditingController();
  TextEditingController countryCodeController = TextEditingController();
  ApiDataSource apiDataSource = ApiDataSource();
  String accessToken = '';
  RxString selectedCountryCode = ''.obs;

  RxBool isLoading = false.obs;
  RxBool isGoogleLoading = false.obs;
  final errorText = ''.obs;

  @override
  void onInit() {
    super.onInit();
  }

  void setSelectedCountry(Country country) {
    selectedCountryCode.value = '+${country.phoneCode}';
    countryCodeController.text = '+${country.phoneCode}';
    selectedCountryFlag = country.flagEmoji;
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   mobileNumber.clear();
    // });
  }

  Future<String?> login({
    required String mobileNumber,
    required BuildContext context,
    required String countryCode,
  }) async {
    isLoading.value = true;
    try {
      final results = await apiDataSource.mobileNumberLogin(mobileNumber,countryCode);
      results.fold(
        (failure) {
          // Get.snackbar(
          //   "Error",
          //   failure.message,
          //   snackPosition: SnackPosition.TOP,
          //   backgroundColor: Get.theme.colorScheme.secondary,
          //   colorText: Get.theme.colorScheme.onSecondary,
          // );
          isLoading.value = false;


        },
        (response) {
          isLoading.value = false;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OtpScreens(
                    countyCode: selectedCountryCode.value,
                    mobileNumber: mobileNumber,
                  ),
            ),
          );
        },
      );
    } catch (e) {
      isLoading.value = false;
      return '';
    }
    isLoading.value = false;
    return '';
  }

  void clearState() {
    accessToken = '';
    selectedCountryCode.value = '';
  }
}
