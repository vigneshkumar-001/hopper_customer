import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';

import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFD), Color(0xFFF6F7FF)],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 25,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: (){
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          AppImages.backImage,
                          height: 20,
                          width: 20,
                        ),
                      ),
                      CustomTextFields.textWithStyles700(
                        'Payment Method',
                        fontSize: 20,
                      ),
                      Image.asset(AppImages.history, height: 20, width: 20),
                    ],
                  ),

                  const SizedBox(height: 30),

                  CustomTextFields.textWithStyles700(
                    'Online Payment',
                    fontSize: 17,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 50,
                        width: 170,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.commonWhite,
                          border: Border.all(color: AppColors.containerColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              AppImages.payPall,
                              height: 24,
                              width: 24,
                            ),
                            SizedBox(width: 10),

                            CustomTextFields.textWithStylesSmall(
                              'PayPal',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              colors: AppColors.commonBlack,
                            ),
                          ],
                        ),
                      ),

                      Container(
                        height: 50,
                        width: 170,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.commonWhite,
                          border: Border.all(color: AppColors.containerColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              AppImages.applePay,
                              height: 24,
                              width: 40,
                            ),
                            SizedBox(width: 10),
                            CustomTextFields.textWithStylesSmall(
                              'Apple Pay',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              colors: AppColors.commonBlack,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Container(
                    height: 50,
                    width: 170,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.commonWhite,
                      border: Border.all(color: AppColors.containerColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.more_horiz),
                        SizedBox(width: 10),
                        CustomTextFields.textWithStylesSmall(
                          'Apple Pay',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          colors: AppColors.commonBlack,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),

                  CustomTextFields.textWithStyles700('Card', fontSize: 16),
                  SizedBox(height: 15),
                  PackageContainer.customWalletContainer(
                    onTap: () {},
                    title: 'Add a new card',
                    textColor: AppColors.resendBlue,
                    fontWeight: FontWeight.w400,
                    leadingImagePath: AppImages.borderAdd,
                    trailing: Image.asset(
                      AppImages.rightArrow,
                      color: AppColors.commonBlack,
                      width: 16,
                      height: 16,
                    ),
                  ),
                  SizedBox(height: 15),

                  CustomTextFields.textWithStyles700('Wallets', fontSize: 16),
                  SizedBox(height: 15),
                  PackageContainer.customWalletContainer(
                    onTap: () {},
                    title: 'Hoppr Wallet',

                    leadingImagePath: AppImages.wallet,
                    trailing: CustomTextFields.textWithImage(
                      fontWeight: FontWeight.w600,
                      text: '726.29',
                      colors: AppColors.walletCurrencyColor,
                      imagePath: AppImages.nBlackCurrency,
                      imageColors: AppColors.walletCurrencyColor,
                    ),
                  ),
                  SizedBox(height: 15),
                  PackageContainer.customWalletContainer(
                    onTap: () {},
                    title: 'Crypto',
                    leadingImagePath: AppImages.wallet,
                    trailing: Image.asset(
                      AppImages.rightArrow,
                      width: 16,
                      height: 16,
                    ),
                  ),
                  SizedBox(height: 15),
                  PackageContainer.customWalletContainer(
                    onTap: () {},
                    title: 'Cash Payment',
                    leadingImagePath: AppImages.cash,
                    trailing: Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.resendBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: CustomTextFields.textWithStyles600(
                        'Pay on delivery',
                        fontSize: 12,
                        color: AppColors.resendBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  CustomTextFields.textWithStylesSmall(
                    'Update your location on the hoppr home ppage to select address from a different city',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 120,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextFields.textWithImage(
                      text: '125',
                      fontSize: 25,
                      colors: AppColors.commonBlack,
                      fontWeight: FontWeight.w700,
                      imageSize: 23,
                      imagePath: AppImages.nBlackCurrency,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Handle view details tap here
                          },
                          child: CustomTextFields.textWithStylesSmall(
                            'View Details',
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_outlined, size: 20),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: AppButtons.button(onTap: () {}, text: 'Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
