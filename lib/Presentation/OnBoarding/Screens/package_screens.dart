import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';

class PackageScreens extends StatefulWidget {
  const PackageScreens({super.key});

  @override
  State<PackageScreens> createState() => _PackageScreensState();
}

class _PackageScreensState extends State<PackageScreens> {
  bool isSendSelected = true;
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 25),
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
                  containerColor: AppColors.commonWhite,
                  subTitle: AppTexts.addSenderAddress,
                  title: AppTexts.collectFrom,
                  leadingImage: AppImages.colorUpArrow,
                ),
                SizedBox(height: 20),

                PackageContainer.customPlainContainers(
                  trailingColor: AppColors.commonWhite,
                  titleColor: AppColors.commonWhite,
                  subColor: AppColors.commonWhite.withOpacity(0.7),
                  containerColor: AppColors.commonBlack,
                  subTitle: AppTexts.addRecipientAddress,
                  title: AppTexts.sendTo,
                  leadingImage: AppImages.colorDownArrow,
                ),
                SizedBox(height: 20),

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
                              Text(AppTexts. fitOnaTwoWheeler),
                            ],
                          ),
                          Row(
                            children: [
                              Image.asset(AppImages.emptyBox, height: 20),
                              SizedBox(width: 10),
                              Text(AppTexts. avoidSendingExpensive),
                            ],
                          ),
                          Row(
                            children: [
                              Image.asset(AppImages.avoidDrinks, height: 20),
                              SizedBox(width: 10),
                              Text(AppTexts. noAlcohol),
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
    );
  }
}
