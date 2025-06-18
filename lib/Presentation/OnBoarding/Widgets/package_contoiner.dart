import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 3),
        child: Row(
          children: [
            // Send Parcel
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    trailing:
                        isSendSelected
                            ? Image.asset(AppImages.tick, height: 20, width: 20)
                            : null,
                    subtitle: Text(
                      'Send Within City Limit',
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Receive Parcel
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    trailing:
                        !isSendSelected
                            ? Image.asset(AppImages.tick, height: 20, width: 20)
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

  static customPlainContainers({
    required Color containerColor,
    required String leadingImage,
    required String title,
    required String subTitle,
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
          leading: Image.asset(leadingImage, height: 22, width: 22),
          trailing: Image.asset(
            AppImages.add,
            height: 20,
            width: 20,
            color: trailingColor,
          ),
          title: CustomTextFields.textWithStyles700(
            fontSize: 16,
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
}
