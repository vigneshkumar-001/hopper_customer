import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:country_picker/country_picker.dart';


var getMobileNumber = '';
var countryCodes = '';
String selectedCountryFlag = '';

class AuthController extends GetxController {
  // String mobileNumber = '';
  TextEditingController mobileNumber = TextEditingController();
  TextEditingController countryCodeController = TextEditingController();

  String accessToken = '';
  RxString selectedCountryCode = ''.obs;
  // ApiDataSource apiDataSource = ApiDataSource();
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


  void clearState() {
    accessToken = '';
    selectedCountryCode.value = '';
  }
}
