import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_images.dart';

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
}
