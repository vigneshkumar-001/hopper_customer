import 'package:flutter/material.dart';

import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/confirmation_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:get/get.dart';
import 'package:hopper/Presentation/OnBoarding/models/address_models.dart';

import 'package:hopper/uitls/map/search_loaction.dart';

class PackageScreens extends StatefulWidget {
  const PackageScreens({super.key});

  @override
  State<PackageScreens> createState() => _PackageScreensState();
}

class _PackageScreensState extends State<PackageScreens> {
  bool isSendSelected = true;
  String selectedAddress = 'Collect from';
  bool senderSelected = false;
  bool receiverSelected = false;
  String? selectedParcel;
  bool receiveWithOtp = true;
  AddressModel? senderData;
  AddressModel? receiverData;

  String enteredAddress = '';
  String landmark = '';
  String name = 'Add Sender Address';
  String phone = '';
  String recipientAddress = '';
  String recipientMapAddress = '';
  String recipientLandmark = '';
  String recipientName = '';
  String recipientPhone = '';
  int selectedIndex = 0;
  List<String> parcelTypes = [
    'Food',
    'Medicines',
    'Groceries',
    'Documents',
    'Electronics',
    'Other',
  ];

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
                  SizedBox(height: 30),

                  PackageContainer.customContainers(
                    isSendSelected: isSendSelected,
                    onSelectionChanged: (selected) {
                      setState(() {
                        isSendSelected = selected;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  CustomTextFields.textWithStyles700(
                    fontSize: 16,
                    AppTexts.sendOrReceiveParcel,
                  ),
                  SizedBox(height: 20),

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
                    onClear:
                        senderData != null
                            ? () {
                              setState(() {
                                senderData = null;
                              });
                            }
                            : null,
                    isSelected: senderData != null,
                    containerColor: AppColors.commonWhite,
                    leadingImage: AppImages.colorUpArrow,
                    title: 'Set pick up location',
                    subTitle:
                        senderData == null
                            ? 'Collect from'
                            : '${senderData!.address}, ${senderData!.landmark}, ${senderData!.mapAddress}',
                    userNameAndPhn:
                        senderData == null
                            ? ''
                            : '${senderData!.name} (${senderData!.phone})',
                  ),

                  SizedBox(height: 20),

                  PackageContainer.customPlainContainers(
                    isSelected: receiverData != null,
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
                    onClear:
                        receiverData != null
                            ? () {
                              setState(() {
                                receiverData = null;
                              });
                            }
                            : null,
                    containerColor: AppColors.commonBlack,
                    titleColor: AppColors.commonWhite,
                    subColor: AppColors.commonWhite.withOpacity(0.7),
                    trailingColor: AppColors.commonWhite,
                    iconColor: AppColors.commonWhite,
                    title: 'Set pick up location',
                    subTitle:
                        receiverData == null
                            ? AppTexts.sendTo
                            : '${receiverData!.address}, ${receiverData!.landmark}, ${receiverData!.mapAddress}',
                    leadingImage: AppImages.colorDownArrow,
                    userNameAndPhn:
                        '${receiverData?.name ?? ''} (${receiverData?.phone ?? ''})',
                  ),

                  SizedBox(height: 20),
                  if (senderData != null && receiverData != null) ...[
                    CustomTextFields.textWithStyles600(
                      'Parcel type',
                      fontSize: 16,
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          parcelTypes.map((title) {
                            return ChoiceChip(
                              checkmarkColor:
                                  selectedParcel == title
                                      ? AppColors.choiceChipColor
                                      : Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color:
                                      selectedParcel == title
                                          ? AppColors.choiceChipColor
                                          : AppColors.containerColor,
                                  width: 1.5,
                                ),
                              ),
                              label: Text(
                                title,
                                style: TextStyle(
                                  color:
                                      selectedParcel == title
                                          ? AppColors.choiceChipColor
                                          : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selectedColor: AppColors.choiceChipColor
                                  .withOpacity(0.1),
                              backgroundColor: AppColors.commonWhite,
                              selected: selectedParcel == title,
                              onSelected: (bool selected) {
                                setState(() {
                                  selectedParcel = selected ? title : null;
                                  AppLogger.log.i(
                                    "Selected Parcel: $selectedParcel",
                                  );
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),

                    CustomTextFields.textAndField(
                      tittle: 'Descriptional (Optional)',
                      hintText: 'Eg., Glass Item',
                    ),
                    const SizedBox(height: 12),
                    CustomTextFields.textAndField(
                      tittle: 'Delivery Instruction',
                      hintText: 'Eg., Glass Items are here Please keep it safe',
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 1,
                          child: Checkbox(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            value: receiveWithOtp,
                            activeColor: Color(0xFF357AE9),
                            checkColor: Colors.white,
                            onChanged: (bool? newValue) {
                              setState(() {
                                receiveWithOtp = newValue ?? false;
                                AppLogger.log.i(
                                  'Receive with OTP: $receiveWithOtp',
                                );
                              });
                            },
                          ),
                        ),
                        const Text("Receive parcel with OTP"),
                      ],
                    ),

                    // Row(
                    //   children: [
                    //     GestureDetector(
                    //       onTap: () {
                    //         setState(() {
                    //           receiveWithOtp = !receiveWithOtp;
                    //         });
                    //       },
                    //       child: Image.asset(
                    //         receiveWithOtp
                    //             ? 'assets/images/checkbox_checked.png'
                    //             : 'assets/images/checkbox_unchecked.png',
                    //         height: 24,
                    //         width: 24,
                    //       ),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     const Text("Receive with OTP"),
                    //   ],
                    // ),
                    const SizedBox(height: 5),
                  ],

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.commonBlack.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      title: CustomTextFields.textWithStyles600(
                        AppTexts.thingsToKeepInMind,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Column(
                          spacing: 5,
                          children: [
                            Row(
                              children: [
                                Image.asset(AppImages.pencilBike, height: 20),
                                SizedBox(width: 10),
                                Text(AppTexts.fitOnaTwoWheeler),
                              ],
                            ),
                            Row(
                              children: [
                                Image.asset(AppImages.emptyBox, height: 20),
                                SizedBox(width: 10),
                                Text(AppTexts.avoidSendingExpensive),
                              ],
                            ),
                            Row(
                              children: [
                                Image.asset(AppImages.avoidDrinks, height: 20),
                                SizedBox(width: 10),
                                Text(AppTexts.noAlcohol),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          senderData != null && receiverData != null
              ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: AppButtons.button(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ConfirmationScreen(
                              parcelType: selectedParcel,
                              sender: senderData!,
                              receiver: receiverData!,
                            ),
                      ),
                    );
                  },
                  text: 'Checkout',
                ),
              )
              : SizedBox.shrink(),
    );
  }
}
