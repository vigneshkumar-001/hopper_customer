import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Presentation/Authentication/controller/authController.dart';
import 'package:country_picker/country_picker.dart';
import 'package:hopper/Presentation/Authentication/screens/otp_screens.dart';
import 'package:hopper/Presentation/Authentication/screens/permission_screens.dart';

import 'package:hopper/api/dataSource/apiDataSource.dart';
import 'package:shared_preferences/shared_preferences.dart';
var getMobileNumber = '';
var countryCodes = '';
String selectedCountryFlag = '';

class OtpController extends GetxController {
  ApiDataSource apiDataSource = ApiDataSource();
  String accessToken = '';
  String customerId = '';
  RxString selectedCountryCode = ''.obs;

  RxBool isLoading = false.obs;
  RxBool isGoogleLoading = false.obs;
  final errorText = ''.obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<String?> otpVerify({
    required String mobileNumber,
    required BuildContext context,
    required String countryCode,
    required VoidCallback onSuccess,
    required String otp,
    required Function(String) onError,
  }) async {
    isLoading.value = true;
    try {
      final mbl = countryCode + mobileNumber;
      final results = await apiDataSource.otpVerify(mbl,  otp);
      results.fold(
        (failure) {
          isLoading.value = false;
          onError("Invalid OTP. Please try again.");
        },
        (response) async {
          AppLogger.log.i(response.data.toString());
          onSuccess();
          isLoading.value = false;
          accessToken = response.data.token;
          accessToken = response.data.customer.id;

          AppLogger.log.i('Response = $accessToken');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', response.data.token);
          await prefs.setString('customer_Id', response.data.customer.id);
          String? token = prefs.getString('token');
          String? customerId = prefs.getString('customer_Id');
          AppLogger.log.i('token = $token');
          AppLogger.log.i('token = $customerId');
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => PermissionScreens(),
          //   ),
          // );
        },
      );
    } catch (e) {
      isLoading.value = false;
      return '';
    }
    isLoading.value = false;
    return '';
  }

  Future<String?> resend({
    required String mobileNumber,
    required String code,
  }) async {
    try {
      final results = await apiDataSource.resendOtp(mobileNumber, code);
      results.fold((failure) {}, (response) {
        AppLogger.log.i(response.message);

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => PermissionScreens(),
        //   ),
        // );
      });
    } catch (e) {
      return '';
    }

    return '';
  }

  void clearState() {
    accessToken = '';
    selectedCountryCode.value = '';
  }
}
