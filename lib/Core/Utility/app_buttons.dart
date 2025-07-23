import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:get/get.dart';

class AppButtons {
  static final AppButtons _singleton = AppButtons._internal();

  AppButtons._internal();

  static AppButtons get instance => _singleton;

  static button({
    required GestureTapCallback? onTap,
    required String text,
    double? size = double.infinity,
    double? fontSize = 16,
    Color? buttonColor = AppColors.commonBlack,
    Color? textColor = Colors.white,
    Color borderColor = const Color(0xff3F5FF2),

    bool? isLoading,
    bool hasBorder = false,

    String? imagePath,
    String? rightImagePath,
    String? rightImagePathText,
  }) {
    return SizedBox(
      width: size,

      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape:
              hasBorder
                  ? RoundedRectangleBorder(
                    side: BorderSide(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  )
                  : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
          elevation: 0,
          fixedSize: Size(150.w, 40.h),
          backgroundColor: buttonColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null) ...[
              Image.asset(imagePath, height: 24.sp, width: 24.sp),
              SizedBox(width: 10.w),
            ],
            Text(
              text,
              style: TextStyle(
                fontFamily: "Roboto-normal",
                fontSize: fontSize,
                color: textColor,
              ),
            ),
            if (rightImagePath != null) ...[
              SizedBox(width: 10.w),
              Image.asset(
                rightImagePath,
                height: 24.sp,
                width: 24.sp,
                color: AppColors.commonWhite,
              ),
              Text(
                rightImagePathText ?? '',
                style: TextStyle(
                  fontFamily: "Roboto-normal",
                  fontSize: 20,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static backButton({required BuildContext context}) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Image.asset(AppImages.backImage, height: 25),
    );
  }

  static void showCancelRideBottomSheet(BuildContext context) {
    String? selectedReason;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              maxChildSize: 0.60,
              minChildSize: 0.5,
              initialChildSize: 0.60,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // borderRadius: BorderRadius.vertical(
                    //   top: Radius.circular(25),
                    // ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Oluwaseun Michael',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              ' will reach in less than 5 mins',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 30),
                                Expanded(
                                  flex: 1,
                                  child: Image.asset(AppImages.confirmCar),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            CustomTextFields.textWithStyles600(
                              'Still want to cancel the ride? Please tell us why',
                            ),
                            SizedBox(height: 20),
                            ...[
                              'Driver denied pickup',
                              'Driver demanded extra cash',
                              'Selected wrong pickup',
                              'My reason is not listed',
                            ].map((reason) {
                              final isSelected = selectedReason == reason;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),

                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedReason = reason;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color:
                                          isSelected
                                              ? AppColors.commonBlack
                                              : AppColors.containerColor1,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            reason,
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? AppColors.commonWhite
                                                      : AppColors.commonBlack
                                                          .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AppButtons.button(
                              buttonColor: AppColors.containerColor1,
                              textColor: AppColors.commonBlack,
                              onTap: () {
                                Get.back();
                              },
                              text: "Don't Cancel",
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: AppButtons.button(
                              onTap: () {
                                 Get.back();
                              },
                              text: "Cancel Ride",
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
