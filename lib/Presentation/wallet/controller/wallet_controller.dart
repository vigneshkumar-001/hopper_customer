import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Presentation/Drawer/models/ride_history_response.dart';
import 'package:hopper/Presentation/wallet/model/get_wallet_balance_response.dart';
import 'package:hopper/Presentation/wallet/model/transaction_response.dart';
import 'package:hopper/Presentation/wallet/model/wallet_response.dart';
import 'package:hopper/Presentation/wallet/screens/wallet_payment_screens.dart';

import 'package:hopper/api/dataSource/apiDataSource.dart';

class WalletController extends GetxController {
  final ApiDataSource apiDataSource = ApiDataSource();
  Rx<WalletResponse?> walletData = Rx<WalletResponse?>(null);
  Rx<WalletBalance?> walletBalance = Rx<WalletBalance?>(null);
  RxList<Transaction> traction = RxList<Transaction>([]);

  final RxBool isLoading = false.obs;
  var balance = 0.0.obs; // <- Balance variable
  @override
  void onInit() {
    super.onInit();
    getWalletBalance();
    customerWalletHistory();
  }

  Future<void> addWallet({
    required double amount,
    required String method,
  }) async {
    isLoading.value = true;
    try {
      final results = await apiDataSource.addWallet(
        amount: amount,
        method: method,
      );
      results.fold(
        (failure) {

          AppLogger.log.e("❌ Ride history fetch failed: $failure");
        },
        (response) {
          walletData.value = response;
          Get.to(
            () => WalletPaymentScreens(
              clientSecret: response.clientSecret,
              publishableKey: response.publishableKey,
              transactionId: response.transactionId,

              amount: amount.toInt(),
            ),
          );
          AppLogger.log.i("✅ Raw response: ${response.toJson()}");
        },
      );
    } catch (e) {
      AppLogger.log.e("❌ Exception while fetching rides: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getWalletBalance() async {
    isLoading.value = true;
    try {
      final results = await apiDataSource.getWalletBalance();
      results.fold(
        (failure) {
          AppLogger.log.e("❌ Ride history fetch failed: $failure");
        },
        (response) {
          walletBalance.value = response.data;
          AppLogger.log.i("✅ Raw response: ${response.toJson()}");
          return response.data.toString();
        },
      );
    } catch (e) {
      AppLogger.log.e("❌ Exception while fetching rides: $e");
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  Future<void> customerWalletHistory() async {
    isLoading.value = true;
    try {
      final results = await apiDataSource.customerWalletHistory();
      results.fold(
        (failure) {
          AppLogger.log.e("❌ Ride history fetch failed: $failure");
        },
        (response) {
          traction.value = response.transactions;
          balance.value = response.balance; // ← store balance
          AppLogger.log.i("✅ Raw response: ${response.transactions}");
          return response.transactions.toString();
        },
      );
    } catch (e) {
      AppLogger.log.e("❌ Exception while fetching rides: $e");
    } finally {
      isLoading.value = false;
    }
    return null;
  }
}
