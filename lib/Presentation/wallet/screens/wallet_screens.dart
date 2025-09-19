import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/wallet/controller/wallet_controller.dart';
import 'package:hopper/Presentation/wallet/screens/add_money_screen.dart';

class WalletScreens extends StatefulWidget {
  const WalletScreens({super.key});

  @override
  State<WalletScreens> createState() => _WalletScreensState();
}

class _WalletScreensState extends State<WalletScreens> {
  final WalletController controller = Get.put(WalletController());

  @override
  void initState() {
    super.initState();
    controller.getWalletBalance();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await false;
      },
      child: Scaffold(
        backgroundColor: AppColors.containerColor1,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    // GestureDetector(
                    //   onTap: () => Navigator.pop(context),
                    //   child: Image.asset(
                    //     AppImages.backImage,
                    //     height: 19,
                    //     width: 19,
                    //   ),
                    // ),
                    const Spacer(),
                    CustomTextFields.textWithStyles700('Wallet', fontSize: 20),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(color: AppColors.commonWhite),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CustomTextFields.textWithStyles700(
                            fontSize: 18,
                            'Total Wallet balance : ',
                          ),
                          Obx(
                            () => CustomTextFields.textWithImage(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              colors: AppColors.changeButtonColor,
                              imageSize: 20,
                              text:
                                  controller
                                      .walletBalance
                                      .value
                                      ?.customerWalletBalance
                                      ?.toString() ??
                                  '0',
                              imagePath: AppImages.nBlackCurrency,
                              imageColors: AppColors.changeButtonColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Image.asset(AppImages.hopprWallet, height: 32),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextFields.textWithStyles600(
                                  'Hoppr Money',
                                ),
                                CustomTextFields.textWithStylesSmall(
                                  'No expiry',
                                ),
                              ],
                            ),
                          ),
                          Obx(
                            () => CustomTextFields.textWithImage(
                              colors: AppColors.commonBlack,
                              fontWeight: FontWeight.w700,

                              imagePath: AppImages.nBlackCurrency,
                              text:
                                  controller
                                      .walletBalance
                                      .value
                                      ?.customerWalletBalance
                                      ?.toString() ??
                                  '0',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(color: AppColors.commonWhite),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(AppImages.trans, height: 32),
                          SizedBox(width: 15),
                          Expanded(
                            child: CustomTextFields.textWithStyles600(
                              'View All transaction',
                            ),
                          ),
                          Image.asset(
                            AppImages.rightArrow,
                            height: 20,
                            color: AppColors.commonBlack,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: AppButtons.button(
              onTap: () async {
                final minimumBalance =
                    controller.walletBalance.value?.minimumWalletAddBalance ??
                    0;

                final customerWalletBalance =
                    controller.walletBalance.value?.customerWalletBalance ?? 0;
                print("➡️ Passing minimumBalance: $minimumBalance");

                Get.to(
                  AddMoneyScreen(
                    minimumWalletAddBalance: minimumBalance,
                    customerWalletBalance: customerWalletBalance ?? 0,
                  ),
                );
              },
              text: 'Add Money',
            ),
          ),
        ),
      ),
    );
  }
}
