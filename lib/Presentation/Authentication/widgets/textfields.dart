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
    bool autofocus = true,
    String? leadingImage,
    double imgHeight = 10,
    double imgWidth = 10,
    Widget? prefixIcon,

    required String title,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    TextStyle? hintStyle,
    Color containerColor = const Color(0xffF1F1F1),
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: containerColor,
      ),
      child: TextFormField(
        autofocus: autofocus,
        onChanged: onChanged,
        onTap: onTap,
        controller: controller,
        initialValue: initialValue,
        readOnly: readOnly,
        cursorColor: AppColors.commonBlack,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.all(imgHeight),
            child: Image.asset(
              leadingImage ?? AppImages.search,
              height: 9,
              width: 10,
            ),
          ),
          // focusedBorder: OutlineInputBorder(
          //   borderSide: BorderSide(color: Colors.black, width: 1.5),
          //   borderRadius: BorderRadius.circular(4),
          // ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
          suffixIcon: suffixIcon,
          hintText: title,
          hintStyle:
              hintStyle ??
              TextStyle(
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
    String? text1,
    TextAlign textAlign = TextAlign.start,
    FontWeight? fontWeight,
    double fontSize = 13,
    Color? colors = Colors.black45,
  }) {
    return Text(
      textAlign: textAlign,
      text + (text1 ?? ''),
      style: TextStyle(
        color: colors,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }

  static textAndField({
    required String tittle,
    GlobalKey<FormState>? formKey,
    required String hintText,
    TextEditingController? controller,
    TextInputType? type,
    FontWeight? fontWeight = FontWeight.w400,
    int? maxLines,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,

    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tittle,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          textInputAction: TextInputAction.next,
          maxLines: maxLines,
          cursorColor: Colors.black,

          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) {
            // Call the passed onChanged if exists
            // if (onChanged != null) onChanged(value);
            // // Then trigger form validation if formKey is provided
            // formKey?.currentState?.validate();
          },
          inputFormatters: inputFormatters,
          keyboardType: type,
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            color: Color(0xff111111),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,

            hintText: hintText,
            hintStyle: TextStyle(
              color: Color(0xff666666),
              fontWeight: fontWeight,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.containerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.containerColor,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.black,
                width: 1.5,
              ), // BLACK BORDER
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.errorRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.errorRed, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  static Widget textWithImage({
    required String text,
    String? imagePath,
    double imageSize = 16,
    double fontSize = 13,
    TextAlign textAlign = TextAlign.start,
    FontWeight? fontWeight,
    Color? colors = Colors.black45,
    Color? imageColors = Colors.black,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (imagePath != null)
          Image.asset(
            imagePath,
            height: imageSize,
            width: imageSize,
            color: imageColors,
          ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            textAlign: textAlign,
            style: TextStyle(
              color: colors,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ],
    );
  }
}
