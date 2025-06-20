import 'package:flutter/material.dart';
import 'package:dotted_line/dotted_line.dart';

import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/payment_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:hopper/Presentation/OnBoarding/models/address_models.dart';
import 'package:hopper/uitls/map/search_loaction.dart';

class ConfirmationScreen extends StatefulWidget {
  final AddressModel sender;
  final AddressModel receiver;
  final String? parcelType;

  const ConfirmationScreen({
    Key? key,
    required this.sender,
    required this.receiver,
    this.parcelType,
  }) : super(key: key);

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  String? selectedParcel;
  bool isSendSelected = true;

  late AddressModel senderData;
  late AddressModel receiverData;

  List<String> parcelTypes = ['Food', 'Documents', 'Clothes', 'Others'];

  @override
  void initState() {
    super.initState();
    senderData = widget.sender;
    receiverData = widget.receiver;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Image.asset(AppImages.hopprPackage, height: 24),
                      ),
                      Positioned(
                        right: 0,
                        child: Image.asset(
                          AppImages.history,
                          height: 20,
                          width: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  CustomTextFields.textWithStyles700(
                    'Location Details',
                    fontSize: 16,
                  ),
                  const SizedBox(height: 20),
                  PackageContainer.customPlainContainers(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommonLocationSearch(),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          senderData = AddressModel(
                            name: result['name'],
                            phone: result['phone'],
                            address: result['address'],
                            landmark: result['landmark'],
                            mapAddress: result['mapAddress'],
                          );
                        });
                      }
                    },
                    onClear: () {
                      setState(() {
                        senderData = AddressModel(
                          name: 'Add Sender Address',
                          phone: '',
                          address: '',
                          landmark: '',
                          mapAddress: 'Collect from',
                        );
                      });
                    },
                    containerColor: AppColors.commonWhite,
                    title:
                        senderData.address.isEmpty &&
                                senderData.landmark.isEmpty
                            ? senderData.mapAddress
                            : '${senderData.address}, ${senderData.landmark}, ${senderData.mapAddress}',
                    subTitle:
                        senderData.name == 'Add Sender Address' &&
                                senderData.phone.isEmpty
                            ? senderData.name
                            : '${senderData.name} (${senderData.phone})',
                    leadingImage: AppImages.colorUpArrow,
                  ),
                  const SizedBox(height: 20),

                  /// Receiver
                  PackageContainer.customPlainContainers(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommonLocationSearch(),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          receiverData = AddressModel(
                            name: result['name'],
                            phone: result['phone'],
                            address: result['address'],
                            landmark: result['landmark'],
                            mapAddress: result['mapAddress'],
                          );
                        });
                      }
                    },
                    onClear: () {
                      setState(() {
                        receiverData = AddressModel(
                          name: '',
                          phone: '',
                          address: '',
                          landmark: '',
                          mapAddress: '',
                        );
                      });
                    },
                    trailingColor: AppColors.commonWhite,
                    titleColor: AppColors.commonWhite,
                    subColor: AppColors.commonWhite.withOpacity(0.7),
                    containerColor: AppColors.commonBlack,
                    subTitle:
                        receiverData.name.isEmpty
                            ? AppTexts.addRecipientAddress
                            : '${receiverData.name} (${receiverData.phone})',
                    title:
                        receiverData.address.isEmpty
                            ? AppTexts.sendTo
                            : '${receiverData.address}, ${receiverData.landmark}, ${receiverData.mapAddress}',
                    leadingImage: AppImages.colorDownArrow,
                  ),

                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.resendBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 15,
                      ),
                      child: Row(
                        children: [
                          Image.asset(AppImages.tag, height: 24, width: 24),
                          SizedBox(width: 10),
                          CustomTextFields.textWithStyles700(
                            'Apply Coupon',
                            color: AppColors.resendBlue,
                            fontSize: 15,
                          ),
                          Spacer(),
                          Image.asset(
                            AppImages.rightArrow,
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextFields.textWithStyles700(
                    'Order Summary',
                    fontSize: 17,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.commonBlack.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      subtitle: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Column(
                          spacing: 5,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppTexts.senderDetails),
                                Text(widget.sender.name),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppTexts.recipientDetails),
                                Text(widget.receiver.name),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppTexts.itemType),
                                Text(widget.parcelType ?? ''),
                              ],
                            ),
                            SizedBox(height: 3),
                            SizedBox(
                              height: 2,
                              child: DottedLine(
                                direction: Axis.horizontal,
                                lineLength: double.infinity,
                                lineThickness: 1.4,
                                dashLength: 4.0,
                                dashColor: Colors.grey.shade400,
                              ),
                            ),
                            SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(child: Text(AppTexts.senderDetails)),
                                CustomTextFields.textWithImage(
                                  text: '125',
                                  imagePath: AppImages.nCurrency,
                                  fontWeight: FontWeight.w900,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextFields.textWithStyles600(
                                    AppTexts.totalBill,
                                    fontSize: 14,
                                  ),
                                ),

                                CustomTextFields.textWithImage(
                                  text: '125',
                                  imagePath: AppImages.nBlackCurrency,
                                  fontWeight: FontWeight.w900,
                                  colors: AppColors.commonBlack,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomTextFields.textWithStyles700(
                    AppTexts.reviewYourOrderToAvoidCancellations,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.commonBlack.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      subtitle: Column(
                        spacing: 5,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextFields.textWithStylesSmall(
                                  AppTexts.readPolicy,
                                ),
                              ),
                            ],
                          ),
                          CustomTextFields.textWithStyles600(
                            'Read Policy',
                            color: AppColors.justInColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: AppButtons.button(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentScreen()),
              );
            },
            text: 'Confirm Booking',
          ),
        ),
      ),
    );
  }
}
