import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Authentication/controller/authController.dart';

import '../../../api/dataSource/apiDataSource.dart';
import '../../../api/repository/failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

class  ProfileController  extends GetxController {
  TextEditingController name = TextEditingController();
  TextEditingController lastName = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileNumber = TextEditingController();
  String accessToken = '';
  String serviceType = '';
  ApiDataSource apiDataSource = ApiDataSource();
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

  }

  Future<String?> basicInfo(
      BuildContext context,
      String countryCode,
      String mobileNumber, {
        bool fromCompleteScreen = false,
      }) async {
    isLoading.value = true;
    try {

    } catch (e) {
      isLoading.value = false;
      return 'An error occurred';
    }
  }



  void clearState() {
    mobileNumber.clear();
    name.clear();
  }
}
