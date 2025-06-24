import 'package:flutter/material.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';

class PackageContainer {
  static Widget customContainers({
    required bool isSendSelected,
    required ValueChanged<bool> onSelectionChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.containerColor1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onSelectionChanged(true),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSendSelected ? AppColors.commonWhite : null,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        isSendSelected
                            ? Border.all(
                              color: AppColors.containerColor,
                              width: 2,
                            )
                            : null,
                  ),
                  child: ListTile(
                    title: Text(
                      'Send Parcel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    trailing:
                        isSendSelected
                            ? Image.asset(AppImages.tick, height: 15, width: 15)
                            : null,
                    subtitle: Text(
                      'Send Within City Limit',
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: GestureDetector(
                onTap: () => onSelectionChanged(false),
                child: Container(
                  decoration: BoxDecoration(
                    border:
                        !isSendSelected
                            ? Border.all(
                              color: AppColors.containerColor,
                              width: 2,
                            )
                            : null,
                    color: !isSendSelected ? AppColors.commonWhite : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      'Receive Parcel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    trailing:
                        !isSendSelected
                            ? Image.asset(AppImages.tick, height: 15, width: 15)
                            : null,
                    subtitle: Text(
                      'Get Parcel Within City Limit',
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget customPlainContainers({
    required Color containerColor,
    required String leadingImage,
    required String title,
    required String subTitle,
    required String userNameAndPhn,
    required bool isSelected,
    VoidCallback? onClear,
    VoidCallback? onTap,
    VoidCallback? onEditTap,
    Color? subColor = Colors.black45,
    Color? iconColor = AppColors.commonBlack,
    Color? trailingColor = AppColors.commonBlack,
    Color? titleColor = AppColors.commonBlack,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.commonBlack.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:   EdgeInsets.only(top: isSelected? 5 : 10),
              child: Image.asset(leadingImage, height: 21, width: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subTitle,
                    style: TextStyle(color: subColor, fontSize: 13),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 2,
                      child: DottedLine(
                        direction: Axis.horizontal,
                        dashColor: Colors.grey.shade400,
                        lineThickness: 1,
                        dashLength: 5,
                        dashGapLength: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomTextFields.textWithStylesSmall(
                      userNameAndPhn,
                      colors: titleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            isSelected
                ? Row(
                  children: [
                    GestureDetector(
                      onTap: onEditTap,
                      child: Image.asset(
                        AppImages.edit,
                        height: 20,
                        width: 20,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (onClear != null)
                      GestureDetector(
                        onTap: onClear,
                        child: Icon(Icons.close, size: 20, color: iconColor),
                      ),
                  ],
                )
                : GestureDetector(
                  onTap: onTap,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Image.asset(
                        AppImages.add,
                        height: 20,
                        width: 20,
                        color: trailingColor,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static customPlainContainerss({
    required Color containerColor,
    required String leadingImage,
    required String title,
    required String subTitle,
    VoidCallback? onClear, // <- add this
    VoidCallback? onTap,
    Color? subColor = Colors.black45,
    Color? trailingColor = AppColors.commonBlack,
    Color? titleColor = AppColors.commonBlack,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          border: Border.all(
            color: AppColors.commonBlack.withOpacity(0.1),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Image.asset(leadingImage, height: 22, width: 22)],
          ),
          trailing:
              onClear != null
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    color: trailingColor,
                    onPressed: onClear,
                  )
                  : Image.asset(
                    AppImages.add,
                    height: 20,
                    width: 20,
                    color: trailingColor,
                  ),

          title: CustomTextFields.textWithStyles600(
            fontSize: 15,
            title,
            color: titleColor,
          ),
          subtitle: Text(subTitle, style: TextStyle(color: subColor)),
        ),
      ),
    );
  }

  static customRideContainer({
    required String tittle,
    required String subTitle,
    required String img,
    double imgHeight = 43,
    double imgWeight = 32,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.containerColor,
        ),
        child: ListTile(
          title: Text(
            tittle,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subTitle, style: TextStyle(fontSize: 10)),
          trailing: Image.asset(img, height: imgHeight, width: imgWeight),
        ),
      ),
    );
  }

  static customWalletContainer({
    required VoidCallback onTap,
    required String title,
    FontWeight? fontWeight = FontWeight.w600,
    required String leadingImagePath,
    Widget? trailing,
    Color containerColor = Colors.white,
    Color borderColor = const Color(0xFFE0E0E0),
    Color textColor = Colors.black,
    Color arrowColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          color: containerColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15),
        child: Row(
          children: [
            Image.asset(leadingImagePath, height: 26, width: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: fontWeight,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
