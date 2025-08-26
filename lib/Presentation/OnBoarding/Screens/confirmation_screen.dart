import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:dotted_line/dotted_line.dart';

import 'package:hopper/Core/Consents/app_colors.dart';

import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_toasts.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/OnBoarding/Controller/package_controller.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/payment_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:hopper/Presentation/OnBoarding/models/address_models.dart';
import 'package:hopper/uitls/map/google_map.dart';
import 'package:hopper/uitls/map/search_loaction.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

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
  final PackageController packageController = Get.put(PackageController());
  String? selectedParcel;
  bool isSendSelected = true;
  final GlobalKey senderKey = GlobalKey();
  final GlobalKey receiverKey = GlobalKey();

  double lineHeight = 100;
  AddressModel? senderData;
  AddressModel? receiverData;
  String capitalizeFirstLetter(String name) {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  bool isWithin1Km(double lat1, double lon1, double lat2, double lon2) {
    final distanceInMeters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return distanceInMeters < 1000;
  }

  List<String> parcelTypes = ['Food', 'Documents', 'Clothes', 'Others'];

  @override
  void initState() {
    super.initState();
    senderData = widget.sender;
    receiverData = widget.receiver;

    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateLineHeight());
  }

  void _calculateLineHeight() {
    final senderBox =
        senderKey.currentContext?.findRenderObject() as RenderBox?;
    final receiverBox =
        receiverKey.currentContext?.findRenderObject() as RenderBox?;

    if (senderBox != null && receiverBox != null) {
      final senderPos = senderBox.localToGlobal(Offset.zero);
      final receiverPos = receiverBox.localToGlobal(Offset.zero);

      final calculatedHeight = receiverPos.dy - senderPos.dy - 30;
      setState(() {
        lineHeight = calculatedHeight > 0 ? calculatedHeight : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Image.asset(
                              AppImages.hopprPackage,
                              height: 24,
                            ),
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
                      Stack(
                        children: [
                          Column(
                            children: [
                              Container(
                                key: senderKey,
                                child: PackageContainer.customPlainContainers(
                                  isSelected: senderData != null,
                                  containerColor: AppColors.commonWhite,
                                  leadingImage: AppImages.colorUpArrow,
                                  title:
                                      senderData != null
                                          ? 'Pick up Location'
                                          : 'Collect from',
                                  subTitle:
                                      senderData != null
                                          ? '${senderData!.address}, ${senderData!.landmark}, ${senderData!.mapAddress}'
                                          : AppTexts.addSenderAddress,
                                  userNameAndPhn:
                                      senderData != null
                                          ? '${capitalizeFirstLetter(senderData!.name)} (${senderData!.phone})'
                                          : '',
                                  onEditTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => MapScreen(
                                              cameFromPackage: true,
                                              searchQuery:
                                                  senderData?.mapAddress ?? '',
                                              initialAddress:
                                                  senderData?.address,
                                              initialLandmark:
                                                  senderData?.landmark,
                                              initialName: senderData?.name,
                                              initialPhone: senderData?.phone,
                                              location:
                                                  senderData != null
                                                      ? LatLng(
                                                        senderData!.latitude,
                                                        senderData!.longitude,
                                                      )
                                                      : null,
                                            ),
                                      ),
                                    );

                                    if (result != null) {
                                      final loc = result['location'];
                                      if (receiverData != null &&
                                          isWithin1Km(
                                            receiverData!.latitude,
                                            receiverData!.longitude,
                                            loc.latitude,
                                            loc.longitude,
                                          )) {
                                        AppToasts.customToast(
                                          context,
                                          "Pickup and drop locations cannot be the same or within 1km.",
                                        );
                                        return;
                                      }
                                      setState(() {
                                        senderData = AddressModel(
                                          name: result['name'],
                                          phone: result['phone'],
                                          address: result['address'],
                                          landmark: result['landmark'],
                                          mapAddress: result['mapAddress'],
                                          latitude: result['location'].latitude,
                                          longitude:
                                              result['location'].longitude,
                                        );
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            _calculateLineHeight();
                                          });
                                    }
                                  },
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const CommonLocationSearch(),
                                      ),
                                    );
                                    if (result != null) {
                                      final loc = result['location'];
                                      if (receiverData != null &&
                                          isWithin1Km(
                                            receiverData!.latitude,
                                            receiverData!.longitude,
                                            loc.latitude,
                                            loc.longitude,
                                          )) {
                                        AppToasts.customToast(
                                          context,
                                          "Pickup and drop locations cannot be the same or within 1km.",
                                        );
                                        return;
                                      }

                                      setState(() {
                                        senderData = AddressModel(
                                          name: result['name'],
                                          phone: result['phone'],
                                          address: result['address'],
                                          landmark: result['landmark'],
                                          mapAddress: result['mapAddress'],
                                          latitude: result['location'].latitude,
                                          longitude:
                                              result['location'].longitude,
                                        );
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            _calculateLineHeight();
                                          });
                                    }
                                  },
                                  onClear:
                                      senderData != null
                                          ? () {
                                            setState(() {
                                              senderData = null;
                                            });
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  _calculateLineHeight();
                                                });
                                          }
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Container(
                                key: receiverKey,
                                child: PackageContainer.customPlainContainers(
                                  isSelected: receiverData != null,
                                  containerColor: AppColors.commonBlack,
                                  titleColor: AppColors.commonWhite,
                                  subColor: AppColors.commonWhite.withOpacity(
                                    0.7,
                                  ),
                                  trailingColor: AppColors.commonWhite,
                                  iconColor: AppColors.commonWhite,
                                  leadingImage: AppImages.colorDownArrow,
                                  title:
                                      receiverData != null
                                          ? 'Drop up Location'
                                          : 'Send to',
                                  subTitle:
                                      receiverData != null
                                          ? '${receiverData!.address}, ${receiverData!.landmark}, ${receiverData!.mapAddress}'
                                          : AppTexts.addRecipientAddress,
                                  userNameAndPhn:
                                      receiverData != null
                                          ? '${capitalizeFirstLetter(receiverData!.name)} (${receiverData!.phone})'
                                          : '',
                                  onEditTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => MapScreen(
                                              cameFromPackage: true,
                                              searchQuery:
                                                  receiverData?.mapAddress ??
                                                  '',
                                              initialAddress:
                                                  receiverData?.address,
                                              initialLandmark:
                                                  receiverData?.landmark,
                                              initialName: receiverData?.name,
                                              initialPhone: receiverData?.phone,
                                              location:
                                                  receiverData != null
                                                      ? LatLng(
                                                        receiverData!.latitude,
                                                        receiverData!.longitude,
                                                      )
                                                      : null,
                                            ),
                                      ),
                                    );

                                    if (result != null) {
                                      final loc = result['location'];
                                      if (senderData != null &&
                                          isWithin1Km(
                                            senderData!.latitude,
                                            senderData!.longitude,
                                            loc.latitude,
                                            loc.longitude,
                                          )) {
                                        AppToasts.customToast(
                                          context,
                                          "Pickup and drop locations cannot be the same or within 1km.",
                                        );
                                        return;
                                      }
                                      setState(() {
                                        receiverData = AddressModel(
                                          name: result['name'],
                                          phone: result['phone'],
                                          address: result['address'],
                                          landmark: result['landmark'],
                                          mapAddress: result['mapAddress'],
                                          latitude: result['location'].latitude,
                                          longitude:
                                              result['location'].longitude,
                                        );
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            _calculateLineHeight();
                                          });
                                    }
                                  },
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const CommonLocationSearch(
                                              type: 'receiver',
                                            ),
                                      ),
                                    );
                                    if (result != null) {
                                      final loc = result['location'];
                                      if (senderData != null &&
                                          isWithin1Km(
                                            senderData!.latitude,
                                            senderData!.longitude,
                                            loc.latitude,
                                            loc.longitude,
                                          )) {
                                        AppToasts.customToast(
                                          context,
                                          "Pickup and drop locations cannot be the same or within 1km.",
                                        );
                                        return;
                                      }

                                      setState(() {
                                        receiverData = AddressModel(
                                          name: result['name'],
                                          phone: result['phone'],
                                          address: result['address'],
                                          landmark: result['landmark'],
                                          mapAddress: result['mapAddress'],
                                          latitude: result['location'].latitude,
                                          longitude:
                                              result['location'].longitude,
                                        );
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            _calculateLineHeight();
                                          });
                                    }
                                  },
                                  onClear:
                                      receiverData != null
                                          ? () {
                                            setState(() {
                                              receiverData = null;
                                            });
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  _calculateLineHeight();
                                                });
                                          }
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 45,
                            left: 24,
                            child: SizedBox(
                              height: lineHeight,
                              child: DottedLine(
                                direction: Axis.vertical,
                                lineLength: lineHeight,
                                dashLength: 4,
                                dashColor: AppColors.dotLineColor,
                              ),
                            ),
                          ),
                        ],
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(AppTexts.senderDetails),
                                    Text(
                                      capitalizeFirstLetter(
                                        widget.sender.name ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(AppTexts.recipientDetails),
                                    Text(
                                      capitalizeFirstLetter(
                                        widget.receiver.name ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                Obx(() {
                                  final data =
                                      packageController
                                          .packageDetails
                                          .value
                                          ?.data;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(AppTexts.senderDetails),
                                          ),
                                          CustomTextFields.textWithImage(
                                            text: data?.amount.toString() ?? '',
                                            imagePath: AppImages.nCurrency,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                CustomTextFields.textWithStyles600(
                                                  AppTexts.totalBill,
                                                  fontSize: 14,
                                                ),
                                          ),

                                          CustomTextFields.textWithImage(
                                            text: data?.amount.toString() ?? '',
                                            imagePath: AppImages.nBlackCurrency,
                                            fontWeight: FontWeight.w900,
                                            colors: AppColors.commonBlack,
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Color(0xFFF6F7FF).withOpacity(0.7),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        CustomTextFields.textWithStyles700(
                          AppTexts.reviewYourOrderToAvoidCancellations,
                          fontSize: 16,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.commonWhite,
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
                                      child:
                                          CustomTextFields.textWithStylesSmall(
                                            AppTexts.readPolicy,
                                          ),
                                    ),
                                  ],
                                ),
                                CustomTextFields.textWithStyles600(
                                  'Read Policy',
                                  color: AppColors.resendBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ],
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
