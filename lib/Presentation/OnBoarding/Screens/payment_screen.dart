import 'package:flutter/material.dart';
import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_logger.dart';

import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/chat_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/package_map_confrim_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final DriverSearchController driverSearchController =
      DriverSearchController();
  bool _isLoading = false;
  void _showRatingBottomSheet(BuildContext context) {
    int selectedRating = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      // shape: const RoundedRectangleBorder(
      //   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      // ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,

                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Column(
                      children: [
                        Image.asset(AppImages.dummy, height: 65, width: 65),
                        const SizedBox(height: 20),
                        CustomTextFields.textWithStyles600(
                          textAlign: TextAlign.center,
                          fontSize: 20,
                          'Rate your Experience with Rebecca?',
                        ),
                        const SizedBox(height: 25),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedRating = index + 1;
                                  });
                                  AppLogger.log.i(selectedRating);
                                },
                                child: Image.asset(
                                  index < selectedRating
                                      ? AppImages.starFill
                                      : AppImages.star1,
                                  height: 48,
                                  width: 48,
                                  color:
                                      index < selectedRating
                                          ? AppColors.commonBlack
                                          : AppColors.buttonBorder,
                                ),
                              );
                              return IconButton(
                                icon: Icon(
                                  Icons.star,
                                  size: 45,
                                  color:
                                      index < selectedRating
                                          ? AppColors.commonBlack
                                          : AppColors.containerColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedRating = index + 1;
                                  });
                                },
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppButtons.button1(
                                  borderRadius: 8,
                                  textColor: AppColors.commonBlack,
                                  borderColor: AppColors.buttonBorder,
                                  buttonColor: AppColors.commonWhite,
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  text: Text('Close'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: AppButtons.button1(
                                  borderRadius: 8,
                                  buttonColor: AppColors.commonBlack,
                                  onTap: () {
                                    final String bookingId =
                                        driverSearchController
                                            .carBooking
                                            .value!
                                            .bookingId;
                                    selectedRating;
                                    AppLogger.log.i(selectedRating);
                                    driverSearchController.rateDriver(
                                      bookingId: bookingId,
                                      rating: selectedRating.toString(),
                                      context: context,
                                    );
                                  },
                                  text: Text('Rate Ride'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, dynamic>? paymentIntentData;

  /*Future<void> makePayment() async {
    try {
      paymentIntentData = await createPaymentIntent('1000') ?? {};

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData!['clientSecret'],
          style: ThemeMode.light,
          customFlow: false,

          merchantDisplayName: 'Hoppr',
        ),
      );

      displayPaymentSheet();
    } catch (e) {
      AppLogger.log.i('Exception: $e');
    }
  }*/
  Future<void> makePayment() async {
    try {
      final result = await createPaymentIntent('1500000');

      if (result == null || !result.containsKey('clientSecret')) {
        AppLogger.log.e("❌ Payment Intent is null or missing 'clientSecret'");
        return;
      }

      paymentIntentData = result;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData!['clientSecret'],
          style: ThemeMode.light,
          customFlow: false,
          merchantDisplayName: 'Hoppr',
        ),
      );

      displayPaymentSheet();
    } catch (e) {
      AppLogger.log.e('💡 Exception in makePayment: $e');
    }
  }

  // displayPaymentSheet() async {
  //   try {
  //     await Stripe.instance.presentPaymentSheet();
  //
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Payment successful")));
  //   } catch (e) {
  //     AppLogger.log.i('Error: $e');
  //   }
  // }
  displayPaymentSheet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      AppLogger.log.i('⚠️ Token not found in shared preferences');
      return;
    }

    try {
      await Stripe.instance.presentPaymentSheet();

      String? clientSecret = paymentIntentData?['clientSecret'];
      String? transactionId;

      if (clientSecret != null && clientSecret.contains('_secret')) {
        transactionId = clientSecret.split('_secret').first;
      }

      if (transactionId != null) {
        final response = await http.post(
          Uri.parse(
            'https://hoppr-face-two-dbe557472d7f.herokuapp.com/api/customer/confirm-stripe-payment-response',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "userBookingId": '412145',
            "paymentIntentId": transactionId,
          }),
        );

        AppLogger.log.i('Confirm Payment Response: ${response.body}');
        if (response.statusCode == 200) {
          _showRatingBottomSheet(context);
          AppLogger.log.i('✅ Payment response confirmed successfully');
        } else {
          AppLogger.log.i('❌ Failed to confirm payment response');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment successful\nTransaction ID: $transactionId"),
        ),
      );

      AppLogger.log.i('✅ Payment successful. Transaction ID: $transactionId');
    } catch (e) {
      AppLogger.log.i('❌ Error during payment sheet presentation: $e');
    }
  }

  createPaymentIntent(String amount) async {
    try {
      final String bookingId = '102386';
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(
          'https://hoppr-face-two-dbe557472d7f.herokuapp.com/api/customer/confirm-stripe-payment-intents',
        ),

        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userBookingId': bookingId, 'amount': amount}),
      );

      AppLogger.log.i('Status code: ${response.statusCode}');
      AppLogger.log.i('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        AppLogger.log.i('Decoded payment intent response: $decoded');
        return decoded;
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (err) {
      AppLogger.log.i('err charging user: $err');
    }
  }

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
                        onTap: () {
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
                          color: AppColors.containerColor1,
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
                          color: AppColors.containerColor1,
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
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap:
                        _isLoading
                            ? null
                            : () async {
                              setState(() {
                                _isLoading = true;
                              });

                              await makePayment();

                              setState(() {
                                _isLoading = false;
                              });
                            },
                    child: Container(
                      height: 50,
                      width: 170,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.commonWhite,
                        border: Border.all(color: AppColors.containerColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          _isLoading
                              ? Center(child: AppLoader.circularLoader())
                              : Row(
                                children: [
                                  Image.asset(AppImages.stripe),
                                  SizedBox(width: 10),
                                  CustomTextFields.textWithStylesSmall(
                                    'Stripe',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    colors: AppColors.commonBlack,
                                  ),
                                ],
                              ),
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
                      text: '0.0',
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
                  child: AppButtons.button(
                    onTap: () {
                      _showRatingBottomSheet(context);
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => PackageMapConfirmScreen(),
                      //   ),
                      // );
                    },
                    text: 'Continue',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
