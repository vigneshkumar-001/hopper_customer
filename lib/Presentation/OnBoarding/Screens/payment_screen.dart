import 'package:flutter/material.dart';
import 'package:hopper/Presentation/Drawer/controller/profle_cotroller.dart';
import 'package:hopper/Presentation/OnBoarding/Controller/package_controller.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/pay_pall_screen.dart';
import 'package:hopper/Presentation/OnBoarding/models/address_models.dart';
import 'package:hopper/Presentation/wallet/controller/wallet_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_logger.dart';

import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';

import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

import 'package:cached_network_image/cached_network_image.dart';

class PaymentScreen extends StatefulWidget {
  final String? bookingId;
  final double? amount;
  final AddressModel? sender;
  final AddressModel? receiver;
  const PaymentScreen({
    super.key,
    this.bookingId,
    this.amount,
    this.sender,
    this.receiver,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int selectedIndex = 3;

  final DriverSearchController driverSearchController =
      DriverSearchController();
  final PackageController packageController = Get.put(PackageController());
  final WalletController walletController = Get.put(WalletController());

  final ProfleCotroller controller = Get.put(ProfleCotroller());
  bool _isRatingSheetOpen = false;

  bool _isLoading = false;
  bool payPalLoading = false;
  /*  void _showRatingBottomSheet(BuildContext context) {
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

                  Obx(() {
                    final user = controller.user.value;
                    if (user == null) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl: user.profileImage ?? '',
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => SizedBox(
                                    height: 45,
                                    width: 45,
                                    child: const Center(
                                      child: SizedBox(
                                        height: 15,
                                        width: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 45,
                                    width: 45,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: CustomTextFields.textWithStyles600(
                              textAlign: TextAlign.center,
                              fontSize: 20,
                              'Rate your Experience with ${user.firstName}?',
                            ),
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
                                  child: Obx(() {
                                    return AppButtons.button1(
                                      isLoading:
                                          driverSearchController
                                              .isLoading
                                              .value,
                                      borderRadius: 8,
                                      buttonColor: AppColors.commonBlack,
                                      onTap: () {
                                        final String bookingId =
                                            widget.bookingId ?? '';
                                        selectedRating;
                                        AppLogger.log.i(selectedRating);
                                        driverSearchController.rateDriver(
                                          bookingId: bookingId,
                                          rating: selectedRating.toString(),
                                          context: context,
                                        );
                                      },
                                      text: Text('Rate Ride'),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }*/
  Future<void> _showRatingBottomSheet(BuildContext context) async {
    if (_isRatingSheetOpen) return; // guard
    _isRatingSheetOpen = true;

    int selectedRating = 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                  Obx(() {
                    final user = controller.user.value;
                    if (user == null) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl: user.profileImage ?? '',
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => SizedBox(
                                    height: 45,
                                    width: 45,
                                    child: const Center(
                                      child: SizedBox(
                                        height: 15,
                                        width: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 45,
                                    width: 45,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: CustomTextFields.textWithStyles600(
                              textAlign: TextAlign.center,
                              fontSize: 20,
                              'Rate your Experience with ${user.firstName}?',
                            ),
                          ),
                          const SizedBox(height: 25),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(5, (index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => selectedRating = index + 1);
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
                                    onTap: () => Navigator.pop(context),
                                    text: const Text('Close'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Obx(() {
                                    return AppButtons.button1(
                                      isLoading:
                                          driverSearchController
                                              .isLoading
                                              .value,
                                      borderRadius: 8,
                                      buttonColor: AppColors.commonBlack,
                                      onTap: () {
                                        final String bookingId =
                                            widget.bookingId ?? '';
                                        driverSearchController.rateDriver(
                                          bookingId: bookingId,
                                          rating: selectedRating.toString(),
                                          context: context,
                                        );
                                      },
                                      text: const Text('Rate Ride'),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );

    _isRatingSheetOpen = false; // release when closed
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

  Future<void> payPall() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaypalWebviewPage(
              amount: widget.amount.toString() ?? '',
              bookingId: widget.bookingId ?? '',
            ),
      ),
    );
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
      final String bookingId = widget.bookingId ?? '';
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
            "userBookingId": bookingId,
            "paymentIntentId": transactionId,
          }),
        );

        AppLogger.log.i('Confirm Payment Response: ${response.body}');
        if (response.statusCode == 200) {
          // _showRatingBottomSheet(context);
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
      final String bookingId = widget.bookingId ?? '';
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
  void initState() {
    // TODO: implement initState
    super.initState();
    walletController.getWalletBalance();
    controller.getProfileData();
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
                      Text(''),
                      // Image.asset(AppImages.history, height: 20, width: 20),
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
                      InkWell(
                        onTap:
                            payPalLoading
                                ? null
                                : () async {
                                  setState(() {
                                    payPalLoading = true;
                                    selectedIndex = 0;
                                  });

                                  await payPall();

                                  setState(() {
                                    payPalLoading = false;
                                  });
                                },
                        child: Container(
                          height: 50,
                          width: 170,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.commonWhite,
                            border: Border.all(
                              color:
                                  selectedIndex == 0
                                      ? Colors.black
                                      : AppColors.containerColor,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              payPalLoading
                                  ? Center(child: AppLoader.circularLoader())
                                  : Row(
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
                                selectedIndex = 2;
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
                        border: Border.all(
                          color:
                              selectedIndex == 2
                                  ? Colors.black
                                  : AppColors.containerColor,
                        ),
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
                    borderColor:
                        selectedIndex == 1
                            ? Colors.black
                            : AppColors.containerColor,
                    onTap: () {
                      setState(() {
                        selectedIndex = 1;
                      });
                    },
                    title: 'Hoppr Wallet',

                    leadingImagePath: AppImages.wallet,
                    trailing: CustomTextFields.textWithImage(
                      fontWeight: FontWeight.w600,
                      text:
                          walletController
                              .walletBalance
                              .value
                              ?.customerWalletBalance
                              ?.toString() ??
                          "0",
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
                    borderColor:
                        selectedIndex == 3
                            ? Colors.black
                            : AppColors.containerColor,
                    onTap: () {
                      setState(() {
                        selectedIndex = 3; // Select Cash Payment
                      });
                    },
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
                      text: widget.amount.toString() ?? '280',
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
                          onTap: () {},
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

                /*Expanded(
                  child: Obx(() {
                    return AppButtons.button(
                      onTap: () async {
                        if (selectedIndex == 1 || selectedIndex == 3) {
                          _showRatingBottomSheet(context);
                          print('Cash On Delivery or Hoppr Wallet selected');
                          final paymentType =
                              selectedIndex == 1 ? 'WALLET' : 'COD';

                          final result = await packageController.paymentDetails(
                            bookingId: widget.bookingId ?? '',
                            paymentType: paymentType,
                            context: context,
                          );

                          if (result == '') {
                            _showRatingBottomSheet(context);

                            // After rating, navigate home
                          } else {
                            // API failure
                            // ScaffoldMessenger.of(
                            //   context,
                            // ).showSnackBar(SnackBar(content: Text('')));
                          }
                        } else {
                          // Stripe / PayPal flow already handled separately
                          _showRatingBottomSheet(context);
                        }
                      },
                      isLoading: packageController.isButtonLoading.value,
                      text: 'Continue',
                    );
                  }),
                ),*/
                Expanded(
                  child: Obx(() {
                    return AppButtons.button(
                      onTap: () async {
                        final walletBalance =
                            double.tryParse(
                              walletController
                                      .walletBalance
                                      .value
                                      ?.customerWalletBalance
                                      ?.toString() ??
                                  '0',
                            ) ??
                            0.0;
                        final rideAmount = widget.amount ?? 0.0;

                        if (selectedIndex == 1) {
                          // WALLET
                          if (walletBalance < rideAmount) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Insufficient wallet balance. Please add funds or choose another payment method.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final result = await packageController.paymentDetails(
                            bookingId: widget.bookingId ?? '',
                            paymentType: 'WALLET',
                            context: context,
                          );

                          // call ONCE after success (adjust according to your API’s success contract)
                          if (result ==
                              '' /* success per your current code */ ) {
                            await _showRatingBottomSheet(context);
                          }
                          return;
                        }

                        if (selectedIndex == 3) {
                          // COD
                          final result = await packageController.paymentDetails(
                            bookingId: widget.bookingId ?? '',
                            paymentType: 'COD',
                            context: context,
                          );
                          // show ONCE after success
                          if (result == '' /* success */ ) {
                            await _showRatingBottomSheet(context);
                          }
                          return;
                        }

                        // Stripe / PayPal flows:
                        // Don’t open the sheet here. Open it only after a confirmed success in their respective callbacks.
                        // For example, after Stripe success in displayPaymentSheet(), call:
                        // await _showRatingBottomSheet(context);

                        // final walletBalance =
                        //     double.tryParse(
                        //       walletController
                        //               .walletBalance
                        //               .value
                        //               ?.customerWalletBalance
                        //               ?.toString() ??
                        //           '0',
                        //     ) ??
                        //     0.0;
                        //
                        // final rideAmount = widget.amount ?? 0.0;
                        //
                        // if (selectedIndex == 1) {
                        //   // 🟡 WALLET SELECTED
                        //   if (walletBalance < rideAmount) {
                        //     // ❌ Not enough balance
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       SnackBar(
                        //         content: Text(
                        //           "Insufficient wallet balance. Please add funds or choose another payment method.",
                        //         ),
                        //         backgroundColor: Colors.red,
                        //       ),
                        //     );
                        //     return;
                        //   }
                        //
                        //   _showRatingBottomSheet(context);
                        //   final result = await packageController.paymentDetails(
                        //     bookingId: widget.bookingId ?? '',
                        //     paymentType: 'WALLET',
                        //     context: context,
                        //   );
                        //
                        //   if (result == '') {
                        //     _showRatingBottomSheet(context);
                        //   } else {}
                        // } else if (selectedIndex == 3) {
                        //   // 💵 CASH ON DELIVERY
                        //   _showRatingBottomSheet(context);
                        //   final result = await packageController.paymentDetails(
                        //     bookingId: widget.bookingId ?? '',
                        //     paymentType: 'COD',
                        //     context: context,
                        //   );
                        // } else {
                        //   _showRatingBottomSheet(context);
                        // }
                      },
                      isLoading: packageController.isButtonLoading.value,
                      text: 'Continue',
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
