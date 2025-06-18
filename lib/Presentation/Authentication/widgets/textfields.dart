import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_images.dart';

class CustomTextFields {
  static final CustomTextFields _singleton = CustomTextFields._internal();

  CustomTextFields._internal();

  static CustomTextFields get instance => _singleton;

  static mobileNumber({
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? initialValue,
    bool readOnly = false,
    Widget? prefixIcon,
    required String title,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Color(0xffF1F1F1)),
                child: TextField(
                  readOnly: true,

                  onTap: onTap,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: prefixIcon,
                    suffixIcon: suffixIcon,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(color: Color(0xffF1F1F1)),
                child: TextFormField(
                  cursorColor: AppColors.commonBlack,
                  controller: controller,
                  initialValue: initialValue,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    // focusedBorder: OutlineInputBorder(
                    //   borderSide: BorderSide(color: Colors.black, width: 1.5),
                    //   borderRadius: BorderRadius.circular(4),
                    // ),
                    hintText: '',
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static plainTextField({
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? initialValue,
    bool readOnly = true,
    Widget? prefixIcon,
    required String title,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xffF1F1F1),
      ),
      child: TextFormField(
        onTap: onTap,
        controller: controller,
        initialValue: initialValue,
        readOnly: readOnly,
        cursorColor: AppColors.commonBlack,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(AppImages.search, height: 10, width: 10),
          ),
          // focusedBorder: OutlineInputBorder(
          //   borderSide: BorderSide(color: Colors.black, width: 1.5),
          //   borderRadius: BorderRadius.circular(4),
          // ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),

          hintText: title,
          hintStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.commonBlack,
            fontSize: 16,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  static Text textWithStyles700(
    String text, {
    String? text1,
    double fontSize = 25,
    Color? color,
  }) {
    return Text(
      text + (text1 ?? ''),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
      ),
    );
  }

  static Text textWithStyles600(
    String text, {
    String? text1,
    double fontSize = 15,
    TextAlign textAlign = TextAlign.start,
    Color? color,
  }) {
    return Text(
      textAlign: textAlign,
      text + (text1 ?? ''),
      style: TextStyle(
        color: color,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
      ),
    );
  }

  static textWithStylesSmall(
    String text, {
    TextAlign textAlign = TextAlign.start,
    FontWeight? fontWeight,
    Color? colors = Colors.black45,
  }) {
    return Text(
      textAlign: textAlign,
      text,
      style: TextStyle(color: colors, fontSize: 13, fontWeight: fontWeight),
    );
  }
}
